from fastapi import APIRouter

from app.api.routes import progress, settings, summary, tasks


api_router = APIRouter()
api_router.include_router(tasks.router, tags=["tasks"])
api_router.include_router(progress.router, tags=["progress"])
api_router.include_router(settings.router, tags=["settings"])
api_router.include_router(summary.router, tags=["summary"])

