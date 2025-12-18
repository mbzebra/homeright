from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import uuid4

from pydantic import BaseModel, Field, field_validator, model_validator

from app.models.enums import Schedule


class TaskCreate(BaseModel):
    owner_id: str = Field(min_length=1)
    task_id: Optional[str] = None
    title: str = Field(min_length=1, max_length=200)
    detail: str = Field(default="", max_length=2000)
    schedule: Schedule
    month: Optional[int] = Field(default=None, ge=1, le=12)
    is_builtin: bool = False

    @field_validator("owner_id")
    @classmethod
    def strip_owner(cls, v: str) -> str:
        return v.strip()

    @model_validator(mode="after")
    def validate_custom_month(self) -> "TaskCreate":
        if self.schedule == Schedule.custom and self.month is None:
            raise ValueError("month is required when schedule=custom")
        if self.schedule != Schedule.custom and self.month is not None:
            raise ValueError("month is only allowed when schedule=custom")
        return self

    def ensure_task_id(self) -> str:
        return self.task_id or str(uuid4())


class TaskUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=200)
    detail: Optional[str] = Field(default=None, max_length=2000)
    schedule: Optional[Schedule] = None
    month: Optional[int] = Field(default=None, ge=1, le=12)
    is_builtin: Optional[bool] = None

    @model_validator(mode="after")
    def validate_custom_month(self) -> "TaskUpdate":
        if self.schedule == Schedule.custom and self.month is None:
            raise ValueError("month is required when schedule=custom")
        if self.schedule is not None and self.schedule != Schedule.custom and self.month is not None:
            raise ValueError("month is only allowed when schedule=custom")
        return self


class TaskOut(BaseModel):
    owner_id: str
    task_id: str
    title: str
    detail: str
    schedule: Schedule
    month: Optional[int] = None
    is_builtin: bool
    created_at: datetime
    updated_at: datetime

