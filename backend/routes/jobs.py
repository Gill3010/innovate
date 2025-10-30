import os
import logging
from flask import Blueprint, request, jsonify
from backend.extensions import cache, limiter
import httpx

jobs_bp = Blueprint("jobs", __name__)
logger = logging.getLogger(__name__)


@jobs_bp.get("/search")
@limiter.limit("60/minute")
@cache.cached(timeout=300, query_string=True)
def search_jobs():
    query = (request.args.get("q") or "").strip()
    location = (request.args.get("location") or "").strip()
    remote = request.args.get("remote")
    min_salary = request.args.get("min_salary")
    max_salary = request.args.get("max_salary")
    page = int(request.args.get("page", 1))
    per_page = int(request.args.get("per_page", 20))
    country = (request.args.get("country") or os.getenv("ADZUNA_COUNTRY", "gb")).lower()
    contract_time = request.args.get("contract_time")  # full_time | part_time
    contract_type = request.args.get("contract_type")  # permanent | contract
    distance = request.args.get("distance_km")  # numeric string
    max_days_old = request.args.get("max_days_old")  # numeric string

    providers = [
        _adzuna_fetch,
        _indeed_fetch,
        _linkedin_fetch,
    ]
    results = []
    for fn in providers:
        try:
            results.extend(fn(
                query=query,
                location=location,
                remote=remote,
                min_salary=min_salary,
                max_salary=max_salary,
                page=page,
                per_page=per_page,
                country=country,
                contract_time=contract_time,
                contract_type=contract_type,
                distance=distance,
                max_days_old=max_days_old,
            ))
        except Exception as e:
            logger.exception("jobs provider error: %s", e)
            continue
    seen = set()
    deduped = []
    for r in results:
        key = (r.get("title"), r.get("company"), r.get("url"))
        if key in seen:
            continue
        seen.add(key)
        deduped.append(r)
    logger.info("jobs search deduped=%s", len(deduped))
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


def _adzuna_fetch(
    *,
    query: str,
    location: str,
    remote: str | None,
    min_salary: str | None,
    max_salary: str | None,
    page: int,
    per_page: int,
    country: str,
    contract_time: str | None,
    contract_type: str | None,
    distance: str | None,
    max_days_old: str | None,
):
    app_id = os.getenv("ADZUNA_APP_ID")
    app_key = os.getenv("ADZUNA_APP_KEY")
    if not app_id or not app_key:
        logger.warning("adzuna missing credentials")
        return []
    params: dict[str, str] = {
        "what": query,
        "where": location,
        "content-type": "application/json",
        "results_per_page": str(max(1, min(per_page, 50))),
    }
    if min_salary:
        params["salary_min"] = min_salary
    if max_salary:
        params["salary_max"] = max_salary
    if contract_time in {"full_time", "part_time"}:
        params["contract_time"] = contract_time
    if contract_type in {"permanent", "contract"}:
        params["contract_type"] = contract_type
    if distance:
        params["distance"] = distance
    if max_days_old:
        params["max_days_old"] = max_days_old

    url = f"https://api.adzuna.com/v1/api/jobs/{country}/search/{max(1, page)}"
    params.update({"app_id": app_id, "app_key": app_key})
    logger.info("adzuna GET %s params=%s", url, {k: v for k, v in params.items() if k not in {"app_id", "app_key"}})
    with httpx.Client(timeout=10.0) as client:
        resp = client.get(url, params=params)
        logger.info("adzuna status=%s", resp.status_code)
        if resp.status_code != 200:
            try:
                logger.warning("adzuna error body=%s", resp.text[:500])
            except Exception:
                pass
            return []
        data = resp.json()
        results = data.get("results", [])
        logger.info("adzuna results_count=%s", len(results))
        out = []
        for item in results:
            out.append({
                "title": item.get("title"),
                "company": item.get("company", {}).get("display_name"),
                "location": item.get("location", {}).get("display_name"),
                "url": item.get("redirect_url"),
                "salary_min": item.get("salary_min"),
                "salary_max": item.get("salary_max"),
                "contract_time": item.get("contract_time"),
                "contract_type": item.get("contract_type"),
                "source": "adzuna",
            })
        return out


def _indeed_fetch(**kwargs):
    return []


def _linkedin_fetch(**kwargs):
    return []
