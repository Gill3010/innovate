import os
from flask import Blueprint, request, jsonify
from backend.extensions import cache, limiter
import httpx

jobs_bp = Blueprint("jobs", __name__)


@jobs_bp.get("/search")
@limiter.limit("60/minute")
@cache.cached(timeout=300, query_string=True)
def search_jobs():
    query = (request.args.get("q") or "").strip()
    location = (request.args.get("location") or "").strip()
    remote = request.args.get("remote")
    min_salary = request.args.get("min_salary")

    providers = [
        _adzuna_fetch,
        _indeed_fetch,
        _linkedin_fetch,
    ]
    results = []
    for fn in providers:
        try:
            results.extend(fn(query=query, location=location, remote=remote, min_salary=min_salary))
        except Exception:
            continue
    seen = set()
    deduped = []
    for r in results:
        key = (r.get("title"), r.get("company"))
        if key in seen:
            continue
        seen.add(key)
        deduped.append(r)
    return jsonify(deduped)


@jobs_bp.get("/providers/adzuna/version")
@limiter.limit("30/minute")
def adzuna_version():
    app_id = os.getenv("ADZUNA_APP_ID")
    app_key = os.getenv("ADZUNA_APP_KEY")
    country = os.getenv("ADZUNA_COUNTRY", "gb")
    if not app_id or not app_key:
        return jsonify({"error": "Missing ADZUNA_APP_ID/ADZUNA_APP_KEY"}), 400
    url = f"https://api.adzuna.com/v1/api/jobs/{country}/version"
    params = {"app_id": app_id, "app_key": app_key, "content-type": "application/json"}
    with httpx.Client(timeout=10.0) as client:
        resp = client.get(url, params=params)
    return jsonify({"status": resp.status_code, "body": resp.json() if resp.headers.get("content-type", "").startswith("application/json") else resp.text})


def _adzuna_fetch(query: str, location: str, remote: str | None, min_salary: str | None):
    app_id = os.getenv("ADZUNA_APP_ID")
    app_key = os.getenv("ADZUNA_APP_KEY")
    country = os.getenv("ADZUNA_COUNTRY", "gb")
    if not app_id or not app_key:
        return []
    params = {"what": query, "where": location, "content-type": "application/json"}
    if min_salary:
        params["salary_min"] = min_salary
    # country e.g. gb, us, au
    url = f"https://api.adzuna.com/v1/api/jobs/{country}/search/1"
    params.update({"app_id": app_id, "app_key": app_key})
    with httpx.Client(timeout=10.0) as client:
        resp = client.get(url, params=params)
        if resp.status_code != 200:
            return []
        data = resp.json()
        out = []
        for item in data.get("results", []):
            out.append({
                "title": item.get("title"),
                "company": item.get("company", {}).get("display_name"),
                "location": item.get("location", {}).get("display_name"),
                "url": item.get("redirect_url"),
                "salary_min": item.get("salary_min"),
                "salary_max": item.get("salary_max"),
                "source": "adzuna",
            })
        return out


def _indeed_fetch(**kwargs):
    return []


def _linkedin_fetch(**kwargs):
    return []
