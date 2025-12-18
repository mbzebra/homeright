from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Mapping

from bson import ObjectId
from bson.decimal128 import Decimal128


def utcnow() -> datetime:
    return datetime.now(tz=timezone.utc)


def to_object_id_str(doc: Mapping[str, Any]) -> dict[str, Any]:
    out = dict(doc)
    if "_id" in out and isinstance(out["_id"], ObjectId):
        out["_id"] = str(out["_id"])
    return out


def decimal_to_bson(value: Decimal | None) -> Decimal128 | None:
    if value is None:
        return None
    return Decimal128(value)


def decimal_from_bson(value: Any) -> Decimal | None:
    if value is None:
        return None
    if isinstance(value, Decimal128):
        return value.to_decimal()
    if isinstance(value, Decimal):
        return value
    return Decimal(str(value))

