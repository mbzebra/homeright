from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field, field_validator

from app.models.enums import TaskStatus


class ProgressCreate(BaseModel):
    owner_id: str = Field(min_length=1)
    task_id: str = Field(min_length=1)
    year: int = Field(ge=1970, le=3000)
    month: int = Field(ge=1, le=12)

    status: TaskStatus = TaskStatus.not_started
    cost: Optional[Decimal] = None
    note: str = Field(default="", max_length=2000)
    date: Optional[datetime] = None

    @field_validator("owner_id", "task_id")
    @classmethod
    def strip_ids(cls, v: str) -> str:
        return v.strip()


class ProgressUpdate(BaseModel):
    status: Optional[TaskStatus] = None
    cost: Optional[Decimal] = None
    note: Optional[str] = Field(default=None, max_length=2000)
    date: Optional[datetime] = None


class ProgressOut(BaseModel):
    id: str
    owner_id: str
    task_id: str
    year: int
    month: int
    status: TaskStatus
    cost: Optional[Decimal] = None
    note: str
    date: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

