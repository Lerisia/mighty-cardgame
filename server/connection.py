from __future__ import annotations
import json
import logging

from aiohttp import web, WSMsgType

from session import Session, SessionManager
from room_manager import RoomManager
from protocol import error_msg

logger = logging.getLogger(__name__)


class ConnectionHandler:
    def __init__(self, session_manager: SessionManager, room_manager: RoomManager) -> None:
        self.sessions = session_manager
        self.rooms = room_manager

    async def websocket_handler(self, request: web.Request) -> web.WebSocketResponse:
        ws = web.WebSocketResponse()
        await ws.prepare(request)

        session: Session | None = None

        async for ws_msg in ws:
            if ws_msg.type == WSMsgType.TEXT:
                try:
                    msg = json.loads(ws_msg.data)
                except json.JSONDecodeError:
                    await ws.send_str(json.dumps(error_msg("INVALID_JSON", "Invalid JSON")))
                    continue

                msg_type = msg.get("type", "")

                if session is None:
                    session = await self._handle_auth(ws, msg_type, msg)
                    continue

                await self._route_message(session, msg_type, msg)

            elif ws_msg.type in (WSMsgType.ERROR, WSMsgType.CLOSE):
                break

        if session is not None:
            session.detach_ws()
            if session.room_code:
                room = self.rooms.get_room(session.room_code)
                if room:
                    await room._broadcast_except(session, {
                        "type": "player_disconnected",
                        "seat": session.seat_index,
                        "name": session.player_name,
                    })
            logger.info("Session %s disconnected", session.session_id[:8])

        return ws

    async def _handle_auth(self, ws, msg_type: str, msg: dict) -> Session | None:
        if msg_type == "connect":
            name = msg.get("name", "Player")[:20]
            session = self.sessions.create(name)
            session.attach_ws(ws)
            await session.send({
                "type": "session_created",
                "token": session.token,
                "session_id": session.session_id,
            })
            logger.info("New session: %s (%s)", session.session_id[:8], name)
            return session

        elif msg_type == "reconnect":
            token = msg.get("token", "")
            session = self.sessions.get_by_token(token)
            if session is None:
                await ws.send_str(json.dumps(error_msg("INVALID_TOKEN", "Invalid token")))
                return None
            session.attach_ws(ws)
            response = {
                "type": "reconnected",
                "session_id": session.session_id,
                "room_code": session.room_code,
                "seat": session.seat_index,
            }
            if session.room_code:
                room = self.rooms.get_room(session.room_code)
                if room:
                    response["players"] = room._get_players_info()
                    await room._broadcast_except(session, {
                        "type": "player_reconnected",
                        "seat": session.seat_index,
                        "name": session.player_name,
                    })
            await session.send(response)
            logger.info("Reconnected: %s", session.session_id[:8])
            return session

        await ws.send_str(json.dumps(error_msg("AUTH_REQUIRED", "Send connect or reconnect first")))
        return None

    async def _route_message(self, session: Session, msg_type: str, msg: dict) -> None:
        if msg_type == "create_room":
            if session.room_code:
                await session.send(error_msg("ALREADY_IN_ROOM", "Leave current room first"))
                return
            room = self.rooms.create_room(session)
            await session.send({
                "type": "room_created",
                "code": room.code,
                "seat": 0,
                "players": room._get_players_info(),
            })
            logger.info("Room %s created by %s", room.code, session.player_name)

        elif msg_type == "join_room":
            if session.room_code:
                await session.send(error_msg("ALREADY_IN_ROOM", "Leave current room first"))
                return
            code = msg.get("code", "").upper()
            room = self.rooms.get_room(code)
            if room is None:
                await session.send(error_msg("ROOM_NOT_FOUND", "Room not found"))
                return
            await room.try_join(session)

        elif msg_type == "leave_room":
            if not session.room_code:
                await session.send(error_msg("NOT_IN_ROOM", "Not in a room"))
                return
            room = self.rooms.get_room(session.room_code)
            if room:
                seat = session.seat_index
                room.remove_player(session)
                await room._broadcast({
                    "type": "player_left",
                    "seat": seat,
                    "name": session.player_name,
                    "reason": "left",
                })
                if room.is_empty():
                    self.rooms.remove_room(room.code)
            await session.send({"type": "room_left"})

        elif session.room_code:
            room = self.rooms.get_room(session.room_code)
            if room:
                await room.handle_message(session, msg)
        else:
            await session.send(error_msg("NOT_IN_ROOM", "Join or create a room first"))
