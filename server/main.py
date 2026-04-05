import asyncio
import logging

from aiohttp import web

from config import HOST, PORT, CLEANUP_INTERVAL
from session import SessionManager
from room_manager import RoomManager
from connection import ConnectionHandler


logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)


async def cleanup_task(session_mgr: SessionManager, room_mgr: RoomManager) -> None:
    while True:
        await asyncio.sleep(CLEANUP_INTERVAL)
        expired = session_mgr.cleanup_expired()
        for s in expired:
            if s.room_code:
                room = room_mgr.get_room(s.room_code)
                if room:
                    room.remove_player(s)
                    if room.is_empty():
                        room_mgr.remove_room(room.code)
        rooms_cleaned = room_mgr.cleanup_empty()
        if expired or rooms_cleaned:
            logger.info("Cleanup: %d expired sessions, %d empty rooms", len(expired), rooms_cleaned)


async def health_handler(request: web.Request) -> web.Response:
    return web.json_response({"status": "ok"})


def create_app() -> web.Application:
    session_mgr = SessionManager()
    room_mgr = RoomManager()
    handler = ConnectionHandler(session_mgr, room_mgr)

    app = web.Application()
    app.router.add_get("/ws", handler.websocket_handler)
    app.router.add_get("/health", health_handler)

    async def start_background(app: web.Application) -> None:
        app["cleanup_task"] = asyncio.create_task(cleanup_task(session_mgr, room_mgr))

    async def stop_background(app: web.Application) -> None:
        app["cleanup_task"].cancel()

    app.on_startup.append(start_background)
    app.on_cleanup.append(stop_background)

    return app


if __name__ == "__main__":
    app = create_app()
    logger.info("Starting Mighty server on %s:%d", HOST, PORT)
    web.run_app(app, host=HOST, port=PORT)
