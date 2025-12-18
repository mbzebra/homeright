from __future__ import annotations

from datetime import datetime
from typing import Any

from bson import ObjectId
from pydantic import BaseModel, ConfigDict, Field


class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v: Any) -> ObjectId:
        if isinstance(v, ObjectId):
            return v
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid ObjectId")
        return ObjectId(v)


class MongoBaseModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str | None = Field(default=None, alias="_id")


class Timestamped(BaseModel):
    created_at: datetime | None = None
    updated_at: datetime | None = None

