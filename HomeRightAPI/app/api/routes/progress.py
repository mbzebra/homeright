from __future__ import annotations

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument

from app.db.mongo import mongo
from app.models.enums import TaskStatus
from app.models.progress import ProgressCreate, ProgressOut, ProgressUpdate
from app.utils.bson import decimal_from_bson, decimal_to_bson, to_object_id_str, utcnow


router = APIRouter(prefix="/progress")


def get_db() -> AsyncIOMotorDatabase:
    return mongo.db


def _doc_to_out(doc: dict) -> ProgressOut:
    doc = to_object_id_str(doc)
    return ProgressOut(
        id=doc["_id"],
        owner_id=doc["owner_id"],
        task_id=doc["task_id"],
        year=doc["year"],
        month=doc["month"],
        status=TaskStatus(doc["status"]),
        cost=decimal_from_bson(doc.get("cost")),
        note=doc.get("note", ""),
        date=doc.get("date"),
        created_at=doc["created_at"],
        updated_at=doc["updated_at"],
    )


@router.post("", response_model=ProgressOut, status_code=status.HTTP_201_CREATED)
async def create_progress(payload: ProgressCreate, db: AsyncIOMotorDatabase = Depends(get_db)):
    now = utcnow()
    doc = {
        "owner_id": payload.owner_id,
        "task_id": payload.task_id,
        "year": payload.year,
        "month": payload.month,
        "status": payload.status.value,
        "cost": decimal_to_bson(payload.cost),
        "note": payload.note,
        "date": payload.date,
        "created_at": now,
        "updated_at": now,
    }
    try:
        result = await db["progress"].insert_one(doc)
    except Exception as e:
        raise HTTPException(status_code=409, detail=f"Progress already exists or invalid: {e}")

    doc["_id"] = result.inserted_id
    return _doc_to_out(doc)


@router.get("", response_model=list[ProgressOut])
async def list_progress(
    owner_id: str = Query(min_length=1),
    year: int | None = Query(default=None, ge=1970, le=3000),
    month: int | None = Query(default=None, ge=1, le=12),
    task_id: str | None = None,
    status_value: TaskStatus | None = Query(default=None, alias="status"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=500, ge=1, le=2000),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    query: dict = {"owner_id": owner_id.strip()}
    if year is not None:
        query["year"] = year
    if month is not None:
        query["month"] = month
    if task_id is not None:
        query["task_id"] = task_id.strip()
    if status_value is not None:
        query["status"] = status_value.value

    cursor = db["progress"].find(query).sort([("updated_at", -1)]).skip(skip).limit(limit)
    return [_doc_to_out(d) async for d in cursor]


@router.get("/{progress_id}", response_model=ProgressOut)
async def get_progress(progress_id: str, owner_id: str = Query(min_length=1), db: AsyncIOMotorDatabase = Depends(get_db)):
    if not ObjectId.is_valid(progress_id):
        raise HTTPException(status_code=400, detail="Invalid progress id")
    doc = await db["progress"].find_one({"_id": ObjectId(progress_id), "owner_id": owner_id.strip()})
    if not doc:
        raise HTTPException(status_code=404, detail="Progress not found")
    return _doc_to_out(doc)


@router.put("/by-key", response_model=ProgressOut)
async def upsert_progress_by_key(payload: ProgressCreate, db: AsyncIOMotorDatabase = Depends(get_db)):
    """
    Upsert by (owner_id, task_id, year, month).
    This matches the iOS app behavior: edits overwrite the current record for that task-month-year.
    """
    now = utcnow()
    query = {
        "owner_id": payload.owner_id,
        "task_id": payload.task_id,
        "year": payload.year,
        "month": payload.month,
    }
    update = {
        "$set": {
            "status": payload.status.value,
            "cost": decimal_to_bson(payload.cost),
            "note": payload.note,
            "date": payload.date,
            "updated_at": now,
        },
        "$setOnInsert": {"created_at": now},
    }
    result = await db["progress"].find_one_and_update(
        query,
        update,
        upsert=True,
        return_document=ReturnDocument.AFTER,
    )
    if result is None:
        # Motor returns None if return_document isn't set as expected; fallback read.
        result = await db["progress"].find_one(query)
    if not result:
        raise HTTPException(status_code=500, detail="Failed to upsert progress")
    return _doc_to_out(result)


@router.patch("/{progress_id}", response_model=ProgressOut)
async def update_progress(
    progress_id: str,
    payload: ProgressUpdate,
    owner_id: str = Query(min_length=1),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    if not ObjectId.is_valid(progress_id):
        raise HTTPException(status_code=400, detail="Invalid progress id")

    doc = await db["progress"].find_one({"_id": ObjectId(progress_id), "owner_id": owner_id.strip()})
    if not doc:
        raise HTTPException(status_code=404, detail="Progress not found")

    update: dict = {"updated_at": utcnow()}
    if payload.status is not None:
        update["status"] = payload.status.value
    if payload.cost is not None:
        update["cost"] = decimal_to_bson(payload.cost)
    if payload.note is not None:
        update["note"] = payload.note
    if payload.date is not None:
        update["date"] = payload.date

    await db["progress"].update_one({"_id": doc["_id"]}, {"$set": update})
    merged = {**doc, **update}
    return _doc_to_out(merged)


@router.put("/{progress_id}", response_model=ProgressOut)
async def replace_progress(
    progress_id: str,
    payload: ProgressCreate,
    owner_id: str = Query(min_length=1),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """
    Replace an existing progress record by Mongo _id.
    Use /progress/by-key for the iOS-style (owner_id, task_id, year, month) upsert.
    """
    if not ObjectId.is_valid(progress_id):
        raise HTTPException(status_code=400, detail="Invalid progress id")
    owner_id = owner_id.strip()

    existing = await db["progress"].find_one({"_id": ObjectId(progress_id), "owner_id": owner_id})
    if not existing:
        raise HTTPException(status_code=404, detail="Progress not found")

    now = utcnow()
    replacement = {
        "owner_id": owner_id,
        "task_id": payload.task_id.strip(),
        "year": payload.year,
        "month": payload.month,
        "status": payload.status.value,
        "cost": decimal_to_bson(payload.cost),
        "note": payload.note,
        "date": payload.date,
        "created_at": existing["created_at"],
        "updated_at": now,
    }

    await db["progress"].replace_one({"_id": existing["_id"]}, {**replacement, "_id": existing["_id"]})
    return _doc_to_out({**replacement, "_id": existing["_id"]})


@router.delete("/{progress_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_progress(progress_id: str, owner_id: str = Query(min_length=1), db: AsyncIOMotorDatabase = Depends(get_db)):
    if not ObjectId.is_valid(progress_id):
        raise HTTPException(status_code=400, detail="Invalid progress id")
    result = await db["progress"].delete_one({"_id": ObjectId(progress_id), "owner_id": owner_id.strip()})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Progress not found")
    return None
