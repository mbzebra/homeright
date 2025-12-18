from motor.motor_asyncio import AsyncIOMotorDatabase


async def ensure_indexes(db: AsyncIOMotorDatabase) -> None:
    await db["tasks"].create_index([("owner_id", 1), ("task_id", 1)], unique=True)
    await db["tasks"].create_index([("owner_id", 1), ("schedule", 1), ("month", 1)])
    await db["tasks"].create_index([("owner_id", 1), ("is_builtin", 1)])

    await db["progress"].create_index(
        [("owner_id", 1), ("task_id", 1), ("year", 1), ("month", 1)],
        unique=True,
    )
    await db["progress"].create_index([("owner_id", 1), ("year", 1), ("month", 1), ("status", 1)])

    await db["settings"].create_index([("owner_id", 1)], unique=True)

