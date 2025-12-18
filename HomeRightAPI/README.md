# HomeRightAPI

FastAPI + MongoDB backend for the HomeRight iOS app feature set described in `FEATURES.md`.

This API is intentionally simple and does **not** include authentication yet. Every request is scoped by `owner_id` (a string you choose: Apple user id, email hash, device id, etc.).

## What this API supports

- **Tasks CRUD** (`/tasks`)
  - Built-in tasks and user-created custom tasks.
  - Custom tasks are stored as tasks with `schedule="custom"` and a required `month`.
- **Progress CRUD** (`/progress`)
  - Per `task_id + year + month` tracking of `status`, `cost`, `note`, and `date`.
  - Supports an **upsert** endpoint to mirror the app’s “always save latest edits” behavior.
- **Settings CRUD** (`/settings/{owner_id}`)
  - Stores `selected_year` (mirrors the app’s `selectedYear` state).
- **Summary endpoints** (`/summary/...`)
  - Convenience read endpoints for month/year rollups (completion + cost totals).

## Local setup

### 1) Requirements

- Python 3.11+ (3.10 may work but is not the target)
- MongoDB 6+ (local install, or run via Docker)

If you want to run Mongo via Docker:

```bash
cd HomeRightAPI
docker compose up -d
```

If you want to run **both** Mongo + the API via Docker:

```bash
cd HomeRightAPI
docker compose up --build
```

Then open:
- `http://localhost:8000/docs`

### 2) Environment variables

Create `HomeRightAPI/.env` from the template:

```bash
cp HomeRightAPI/.env.example HomeRightAPI/.env
```

### 3) Install + run

```bash
cd HomeRightAPI
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

uvicorn app.main:app --reload --port 8000
```

Open docs:
- Swagger: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Request scoping

Most reads/writes require `owner_id`. For example:

```bash
curl -X POST http://localhost:8000/tasks \\
  -H 'Content-Type: application/json' \\
  -d '{ "owner_id": "demo", "title": "Test smoke alarms", "detail": "Press test button", "schedule": "monthly", "is_builtin": true }'
```

## Minimal CRUD walkthrough

### Create a custom task for a month

```bash
curl -X POST http://localhost:8000/tasks \\
  -H 'Content-Type: application/json' \\
  -d '{ "owner_id": "demo", "title": "Clean dryer vent", "detail": "Vacuum lint and inspect outside flap", "schedule": "custom", "month": 1, "is_builtin": false }'
```

### Upsert progress (matches iOS behavior)

```bash
curl -X PUT http://localhost:8000/progress/by-key \\
  -H 'Content-Type: application/json' \\
  -d '{ "owner_id": "demo", "task_id": "YOUR_TASK_ID", "year": 2025, "month": 1, "status": "complete", "cost": 25.50, "note": "Replaced filter", "date": "2025-01-03T00:00:00Z" }'
```

### Read a month summary

```bash
curl http://localhost:8000/summary/month/demo/2025/1
```

## Notes on data model vs iOS app

The iOS app stores:
- Built-in tasks in the bundle
- Progress keyed as `{taskUUID}-{year}-{month}`
- Custom tasks by month (not year-scoped), with progress still keyed by year+month

This API mirrors that by using:
- `tasks` collection for both built-in and custom tasks (custom tasks include `month`)
- `progress` collection with a unique key `(owner_id, task_id, year, month)`
- `settings` for `selected_year`
