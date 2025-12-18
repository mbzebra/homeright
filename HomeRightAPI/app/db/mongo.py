from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.core.config import settings


class Mongo:
    def __init__(self) -> None:
        self._client: AsyncIOMotorClient | None = None
        self._db: AsyncIOMotorDatabase | None = None

    def connect(self) -> None:
        if self._client is not None:
            return
        self._client = AsyncIOMotorClient(settings.mongodb_uri)
        self._db = self._client[settings.mongodb_db]

    def close(self) -> None:
        if self._client is None:
            return
        self._client.close()
        self._client = None
        self._db = None

    @property
    def db(self) -> AsyncIOMotorDatabase:
        if self._db is None:
            raise RuntimeError("Mongo is not connected")
        return self._db


mongo = Mongo()

