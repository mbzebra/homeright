from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class SettingsUpsert(BaseModel):
    selected_year: int = Field(ge=1970, le=3000)


class SettingsOut(BaseModel):
    owner_id: str
    selected_year: int
    created_at: datetime
    updated_at: datetime

