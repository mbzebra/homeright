from __future__ import annotations

from fastapi import FastAPI

from app.api.router import api_router
from app.core.config import settings
from app.db.indexes import ensure_indexes
from app.db.mongo import mongo


app = FastAPI(title=settings.app_name)


@app.on_event("startup")
async def on_startup() -> None:
    mongo.connect()
    await ensure_indexes(mongo.db)


@app.on_event("shutdown")
async def on_shutdown() -> None:
    mongo.close()


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(api_router)

