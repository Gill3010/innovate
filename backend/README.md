Backend (Flask)

Setup

1) Virtualenv + deps

```
python3 -m venv .venv
source .venv/bin/activate
pip install -r backend/requirements.txt
```

2) Env vars (examples)
- FLASK_ENV=development
- SECRET_KEY=change-me
- JWT_SECRET_KEY=change-me-too
- DATABASE_URL=postgresql+psycopg2://user:password@localhost:5432/innovate
- CORS_ORIGINS=*
- CACHE_TYPE=SimpleCache
- CACHE_DEFAULT_TIMEOUT=300
- RATELIMIT_DEFAULT=100 per minute
- OPENAI_API_KEY=...
- ADZUNA_APP_ID=...
- ADZUNA_APP_KEY=...
- AUTO_CREATE_DB=true (dev)
- FORCE_HTTPS=false (dev)

3) Run
```
python -m backend.app
```

PostgreSQL quick start (local)
```
# macOS (Homebrew):
brew install postgresql@16
brew services start postgresql@16
createdb innovate
# create user if needed:
# createuser -s postgres
# or set DATABASE_URL env accordingly
```

Seed 17 projects
```
# Ensure the server can connect to the DB via DATABASE_URL
python -m backend.seed_projects
```

Endpoints
- GET /api/health
- Auth: POST /api/auth/register, POST /api/auth/login
- Projects: GET/POST /api/projects, GET/PUT/DELETE /api/projects/<id>
- Jobs: GET /api/jobs/search
- AI: POST /api/ai/project-description, /cv-suggestions, /cover-letter, /career-chat
