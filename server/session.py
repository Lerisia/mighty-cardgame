from __future__ import annotations
import secrets
import time
import uuid


RECONNECT_GRACE_PERIOD = 120.0


class Session:
    def __init__(self, name: str) -> None:
        self.session_id: str = str(uuid.uuid4())
        self.token: str = secrets.token_urlsafe(24)
        self.player_name: str = name
        self.room_code: str | None = None
        self.seat_index: int | None = None
        self.ws = None
        self.connected: bool = False
        self.last_seen: float = time.monotonic()

    def attach_ws(self, ws) -> None:
        self.ws = ws
        self.connected = True
        self.last_seen = time.monotonic()

    def detach_ws(self) -> None:
        self.ws = None
        self.connected = False
        self.last_seen = time.monotonic()

    def is_expired(self) -> bool:
        if self.connected:
            return False
        return time.monotonic() - self.last_seen > RECONNECT_GRACE_PERIOD

    async def send(self, msg: dict) -> None:
        if self.ws is not None and self.connected:
            import json
            try:
                await self.ws.send_str(json.dumps(msg))
            except Exception:
                self.detach_ws()


class SessionManager:
    def __init__(self) -> None:
        self._by_id: dict[str, Session] = {}
        self._by_token: dict[str, Session] = {}

    def create(self, name: str) -> Session:
        session = Session(name)
        self._by_id[session.session_id] = session
        self._by_token[session.token] = session
        return session

    def get_by_token(self, token: str) -> Session | None:
        return self._by_token.get(token)

    def get_by_id(self, session_id: str) -> Session | None:
        return self._by_id.get(session_id)

    def remove(self, session: Session) -> None:
        self._by_id.pop(session.session_id, None)
        self._by_token.pop(session.token, None)

    def cleanup_expired(self) -> list[Session]:
        expired = [s for s in self._by_id.values() if s.is_expired()]
        for s in expired:
            self.remove(s)
        return expired
