from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongo import mongo
from app.models.enums import Schedule
from app.models.task import TaskCreate, TaskOut, TaskUpdate
from app.utils.bson import to_object_id_str, utcnow


router = APIRouter(prefix="/tasks")


def get_db() -> AsyncIOMotorDatabase:
    return mongo.db


@router.post("", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
async def create_task(payload: TaskCreate, db: AsyncIOMotorDatabase = Depends(get_db)):
    now = utcnow()
    task_id = payload.ensure_task_id()

    doc = {
        "owner_id": payload.owner_id,
        "task_id": task_id,
        "title": payload.title,
        "detail": payload.detail,
        "schedule": payload.schedule.value,
        "month": payload.month,
        "is_builtin": payload.is_builtin,
        "created_at": now,
        "updated_at": now,
    }

    try:
        await db["tasks"].insert_one(doc)
    except Exception as e:
        raise HTTPException(status_code=409, detail=f"Task already exists or invalid: {e}")

    return TaskOut(**doc)


@router.get("", response_model=list[TaskOut])
async def list_tasks(
    owner_id: str = Query(min_length=1),
    schedule: Schedule | None = None,
    month: int | None = Query(default=None, ge=1, le=12),
    is_builtin: bool | None = None,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=200, ge=1, le=1000),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    query: dict = {"owner_id": owner_id.strip()}
    if schedule is not None:
        query["schedule"] = schedule.value
    if month is not None:
        query["month"] = month
    if is_builtin is not None:
        query["is_builtin"] = is_builtin

    cursor = db["tasks"].find(query).sort([("is_builtin", -1), ("title", 1)]).skip(skip).limit(limit)
    docs = [to_object_id_str(d) async for d in cursor]
    return [
        TaskOut(
            owner_id=d["owner_id"],
            task_id=d["task_id"],
            title=d["title"],
            detail=d.get("detail", ""),
            schedule=Schedule(d["schedule"]),
            month=d.get("month"),
            is_builtin=bool(d.get("is_builtin", False)),
            created_at=d["created_at"],
            updated_at=d["updated_at"],
        )
        for d in docs
    ]


@router.get("/{task_id}", response_model=TaskOut)
async def get_task(task_id: str, owner_id: str = Query(min_length=1), db: AsyncIOMotorDatabase = Depends(get_db)):
    doc = await db["tasks"].find_one({"owner_id": owner_id.strip(), "task_id": task_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Task not found")
    doc = to_object_id_str(doc)
    return TaskOut(
        owner_id=doc["owner_id"],
        task_id=doc["task_id"],
        title=doc["title"],
        detail=doc.get("detail", ""),
        schedule=Schedule(doc["schedule"]),
        month=doc.get("month"),
        is_builtin=bool(doc.get("is_builtin", False)),
        created_at=doc["created_at"],
        updated_at=doc["updated_at"],
    )


@router.put("/{task_id}", response_model=TaskOut)
async def replace_task(
    task_id: str,
    owner_id: str = Query(min_length=1),
    payload: TaskCreate,
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    if payload.ensure_task_id() != task_id:
        raise HTTPException(status_code=400, detail="task_id mismatch")
    if payload.owner_id.strip() != owner_id.strip():
        raise HTTPException(status_code=400, detail="owner_id mismatch")

    now = utcnow()
    update = {
        "owner_id": payload.owner_id.strip(),
        "task_id": task_id,
        "title": payload.title,
        "detail": payload.detail,
        "schedule": payload.schedule.value,
        "month": payload.month,
        "is_builtin": payload.is_builtin,
        "updated_at": now,
    }

    existing = await db["tasks"].find_one({"owner_id": owner_id.strip(), "task_id": task_id})
    if not existing:
        update["created_at"] = now
        await db["tasks"].insert_one(update)
        return TaskOut(**update)

    await db["tasks"].update_one({"_id": existing["_id"]}, {"$set": update})
    update["created_at"] = existing["created_at"]
    return TaskOut(**update)


@router.patch("/{task_id}", response_model=TaskOut)
async def update_task(
    task_id: str,
    owner_id: str = Query(min_length=1),
    payload: TaskUpdate,
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    doc = await db["tasks"].find_one({"owner_id": owner_id.strip(), "task_id": task_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Task not found")

    update: dict = {"updated_at": utcnow()}
    for field in ["title", "detail", "is_builtin"]:
        value = getattr(payload, field)
        if value is not None:
            update[field] = value
    if payload.schedule is not None:
        update["schedule"] = payload.schedule.value
    if payload.month is not None:
        update["month"] = payload.month

    await db["tasks"].update_one({"_id": doc["_id"]}, {"$set": update})
    merged = {**doc, **update}
    merged = to_object_id_str(merged)
    return TaskOut(
        owner_id=merged["owner_id"],
        task_id=merged["task_id"],
        title=merged["title"],
        detail=merged.get("detail", ""),
        schedule=Schedule(merged["schedule"]),
        month=merged.get("month"),
        is_builtin=bool(merged.get("is_builtin", False)),
        created_at=merged["created_at"],
        updated_at=merged["updated_at"],
    )


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(task_id: str, owner_id: str = Query(min_length=1), db: AsyncIOMotorDatabase = Depends(get_db)):
    result = await db["tasks"].delete_one({"owner_id": owner_id.strip(), "task_id": task_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Task not found")
    return None
