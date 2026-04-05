from __future__ import annotations
import random
import string

from session import Session
from room import Room


VALID_CHARS = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
CODE_LENGTH = 6


class RoomManager:
    def __init__(self) -> None:
        self.rooms: dict[str, Room] = {}

    def create_room(self, host: Session) -> Room:
        code = self._generate_code()
        room = Room(code, host)
        self.rooms[code] = room
        return room

    def get_room(self, code: str) -> Room | None:
        return self.rooms.get(code.upper())

    def remove_room(self, code: str) -> None:
        self.rooms.pop(code, None)

    def cleanup_empty(self) -> int:
        empty = [code for code, room in self.rooms.items() if room.is_empty()]
        for code in empty:
            del self.rooms[code]
        return len(empty)

    def _generate_code(self) -> str:
        for _ in range(100):
            code = "".join(random.choices(VALID_CHARS, k=CODE_LENGTH))
            if code not in self.rooms:
                return code
        raise RuntimeError("Failed to generate unique room code")
