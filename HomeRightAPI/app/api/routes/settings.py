from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongo import mongo
from app.models.settings import SettingsOut, SettingsUpsert
from app.utils.bson import utcnow


router = APIRouter(prefix="/settings")


def get_db() -> AsyncIOMotorDatabase:
    return mongo.db


@router.get("/{owner_id}", response_model=SettingsOut)
async def get_settings(owner_id: str, db: AsyncIOMotorDatabase = Depends(get_db)):
    owner_id = owner_id.strip()
    doc = await db["settings"].find_one({"owner_id": owner_id})
    if not doc:
        now = utcnow()
        doc = {"owner_id": owner_id, "selected_year": 2024, "created_at": now, "updated_at": now}
        await db["settings"].insert_one(doc)
    return SettingsOut(
        owner_id=doc["owner_id"],
        selected_year=doc["selected_year"],
        created_at=doc["created_at"],
        updated_at=doc["updated_at"],
    )


@router.put("/{owner_id}", response_model=SettingsOut)
async def upsert_settings(owner_id: str, payload: SettingsUpsert, db: AsyncIOMotorDatabase = Depends(get_db)):
    owner_id = owner_id.strip()
    now = utcnow()
    await db["settings"].update_one(
        {"owner_id": owner_id},
        {"$set": {"selected_year": payload.selected_year, "updated_at": now}, "$setOnInsert": {"created_at": now}},
        upsert=True,
    )
    doc = await db["settings"].find_one({"owner_id": owner_id})
    if not doc:
        raise HTTPException(status_code=500, detail="Failed to upsert settings")
    return SettingsOut(
        owner_id=doc["owner_id"],
        selected_year=doc["selected_year"],
        created_at=doc["created_at"],
        updated_at=doc["updated_at"],
    )


@router.delete("/{owner_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_settings(owner_id: str, db: AsyncIOMotorDatabase = Depends(get_db)):
    owner_id = owner_id.strip()
    result = await db["settings"].delete_one({"owner_id": owner_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Settings not found")
    return None

