from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongo import mongo
from app.models.enums import TaskStatus
from app.utils.bson import decimal_from_bson


router = APIRouter(prefix="/summary")


def get_db() -> AsyncIOMotorDatabase:
    return mongo.db


@router.get("/month/{owner_id}/{year}/{month}")
async def month_summary(owner_id: str, year: int, month: int, db: AsyncIOMotorDatabase = Depends(get_db)):
    owner_id = owner_id.strip()

    tasks = await db["tasks"].find({"owner_id": owner_id}).to_list(length=5000)
    progress = await db["progress"].find({"owner_id": owner_id, "year": year, "month": month}).to_list(length=5000)
    progress_by_task = {p["task_id"]: p for p in progress}

    tasks_in_month = []
    for t in tasks:
        schedule = t.get("schedule")
        task_month = t.get("month")

        include = False
        if schedule == "custom":
            include = task_month == month
        elif schedule == "monthly":
            include = True
        elif schedule == "quarterly":
            include = month in [1, 4, 7, 10]
        elif schedule == "annual":
            include = month == 1
        elif schedule == "spring":
            include = month == 3
        elif schedule == "summer":
            include = month == 6
        elif schedule == "fall":
            include = month == 9
        elif schedule == "winter":
            include = month == 12
        elif schedule == "seasonal":
            include = month == 3

        if not include:
            continue

        p = progress_by_task.get(t["task_id"])
        tasks_in_month.append(
            {
                "task_id": t["task_id"],
                "title": t.get("title", ""),
                "detail": t.get("detail", ""),
                "schedule": schedule,
                "month": t.get("month"),
                "is_builtin": bool(t.get("is_builtin", False)),
                "progress": None
                if not p
                else {
                    "status": p.get("status"),
                    "cost": decimal_from_bson(p.get("cost")),
                    "note": p.get("note", ""),
                    "date": p.get("date"),
                    "updated_at": p.get("updated_at"),
                },
            }
        )

    completed = 0
    total = len(tasks_in_month)
    total_cost = 0
    for item in tasks_in_month:
        p = item["progress"]
        if not p:
            continue
        if p["status"] == TaskStatus.complete.value:
            completed += 1
            if p["cost"] is not None:
                total_cost += float(p["cost"])

    return {
        "owner_id": owner_id,
        "year": year,
        "month": month,
        "total_tasks": total,
        "completed_tasks": completed,
        "is_month_complete": total > 0 and completed == total,
        "completed_cost_total": total_cost,
        "tasks": tasks_in_month,
    }


@router.get("/year/{owner_id}/{year}")
async def year_summary(
    owner_id: str,
    year: int,
    months: int = Query(default=12, ge=1, le=12),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    owner_id = owner_id.strip()
    progress = await db["progress"].find({"owner_id": owner_id, "year": year, "status": TaskStatus.complete.value}).to_list(length=20000)

    completed_count = len(progress)
    completed_cost = 0
    for p in progress:
        cost = decimal_from_bson(p.get("cost"))
        if cost is not None:
            completed_cost += float(cost)

    return {
        "owner_id": owner_id,
        "year": year,
        "completed_count": completed_count,
        "completed_cost_total": completed_cost,
        "notes": "This endpoint mirrors the iOS app's year totals; month-level 'yearProgress' is computed in-app and can also be derived from /summary/month.",
    }

