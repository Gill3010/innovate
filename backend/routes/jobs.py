import os
import logging
from flask import Blueprint, request, jsonify
from backend.extensions import cache, limiter, db
from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request, exceptions as jwt_ex
import httpx
from backend.models import JobClick
import unicodedata
import xml.etree.ElementTree as ET

jobs_bp = Blueprint("jobs", __name__)
logger = logging.getLogger(__name__)
def _normalize_text(value: str) -> str:
    if not value:
        return ""
    text = unicodedata.normalize("NFKD", str(value))
    text = "".join([c for c in text if not unicodedata.combining(c)])
    return text.lower().strip()



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
    country_raw = (request.args.get("country") or "").lower().strip()
    shortlist = {"pa", "co", "mx"}
    # Adzuna supported countries
    ADZUNA_SUPPORTED = {"mx", "us", "gb", "es", "br", "de", "fr", "it", "nl", "pl", "au", "ca", "at", "ch", "in", "nz", "sg", "za", "be"}
    # Build fan-out list but keep only supported by Adzuna
    if not country_raw or country_raw == "global":
        candidates = ["pa", "co", "mx"]
    else:
        candidates = [country_raw]
    adzuna_countries = [c for c in candidates if c in ADZUNA_SUPPORTED]
    contract_time = request.args.get("contract_time")
    contract_type = request.args.get("contract_type")
    distance = request.args.get("distance_km")
    max_days_old = request.args.get("max_days_old")
    sort_by = request.args.get("sort")  # relevance|date|salary
    with_meta = (request.args.get("with_meta") or "false").lower() == "true"

    # Provider selection:
    # - If a specific country was selected and is supported by Adzuna, use Adzuna + Indeed RSS (for LATAM: mx/co/pa)
    # - If country is not provided or is 'global', use only remote/global sources
    if country_raw and country_raw != "global" and adzuna_countries:
        providers = [
            _adzuna_fetch,
            _indeed_rss_fetch if country_raw in {"mx", "co", "pa"} else None,
            None,
            None,
        ]
    else:
        providers = [
            None,  # don't call Adzuna for global/unsupported countries
            _remotive_fetch,
            _arbeitnow_fetch,
            _remoteok_fetch,
        ]
    results = []
    total_estimate = 0
    for fn in providers:
        if fn is None:
            continue
        try:
            # Fan-out for Adzuna if multiple countries; single call for other providers
            if fn is _adzuna_fetch and len(adzuna_countries) > 1:
                tmp_items = []
                tmp_total = 0
                for ctry in adzuna_countries:
                    sub_items, sub_total = fn(
                        query=query,
                        location=location,
                        remote=remote,
                        min_salary=min_salary,
                        max_salary=max_salary,
                        page=page,
                        per_page=per_page,
                        country=ctry,
                        contract_time=contract_time,
                        contract_type=contract_type,
                        distance=distance,
                        max_days_old=max_days_old,
                        sort_by=sort_by,
                        countries_filter=shortlist,
                        per_source_limit=int(request.args.get("source_limit", 150)),
                    )
                    tmp_items.extend(sub_items)
                    tmp_total += (sub_total or 0)
                items, total = tmp_items, tmp_total
            else:
                items, total = fn(
                    query=query,
                    location=location,
                    remote=remote,
                    min_salary=min_salary,
                    max_salary=max_salary,
                    page=page,
                    per_page=per_page,
                    country=adzuna_countries[0] if adzuna_countries else "mx",
                    contract_time=contract_time,
                    contract_type=contract_type,
                    distance=distance,
                    max_days_old=max_days_old,
                    sort_by=sort_by,
                    countries_filter=shortlist,
                    per_source_limit=int(request.args.get("source_limit", 150)),
                )
            results.extend(items)
            total_estimate += (total or 0)
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
    if with_meta:
        return jsonify({"items": deduped, "total": total_estimate})
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


@jobs_bp.get("/countries")
@limiter.limit("120/minute")
def list_countries():
    """Return supported countries for the selector plus 'global'."""
    countries = [
        {"code": "mx", "name": "Mexico"},
        {"code": "co", "name": "Colombia"},
        {"code": "pa", "name": "Panama"},
        {"code": "us", "name": "United States"},
        {"code": "gb", "name": "United Kingdom"},
        {"code": "es", "name": "Spain"},
        {"code": "br", "name": "Brazil"},
        {"code": "de", "name": "Germany"},
        {"code": "fr", "name": "France"},
        {"code": "it", "name": "Italy"},
        {"code": "nl", "name": "Netherlands"},
        {"code": "pl", "name": "Poland"},
        {"code": "au", "name": "Australia"},
        {"code": "ca", "name": "Canada"},
        {"code": "at", "name": "Austria"},
        {"code": "ch", "name": "Switzerland"},
        {"code": "in", "name": "India"},
        {"code": "nz", "name": "New Zealand"},
        {"code": "sg", "name": "Singapore"},
        {"code": "za", "name": "South Africa"},
        {"code": "be", "name": "Belgium"},
    ]
    return jsonify(countries)


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
    sort_by: str | None,
    countries_filter: set[str],
    per_source_limit: int,
):
    app_id = os.getenv("ADZUNA_APP_ID")
    app_key = os.getenv("ADZUNA_APP_KEY")
    if not app_id or not app_key:
        logger.warning("adzuna missing credentials")
        return [], 0
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
    if sort_by in {"relevance", "date", "salary"}:
        params["sort_by"] = sort_by

    # Ensure country is one of supported; fallback to MX for LATAM shortlist
    if country not in countries_filter:
        country = "mx"
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
            return [], 0
        data = resp.json()
        results = data.get("results", [])
        total = data.get("count", 0)
        logger.info("adzuna results_count=%s total=%s", len(results), total)
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
        return out, int(total or 0)


def _remotive_fetch(
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
    sort_by: str | None,
    countries_filter: set[str],
    per_source_limit: int,
):
    """Remotive public API - remote/global roles. No API key."""
    params = {"search": query or "", "limit": str(max(50, min(per_source_limit, 300)))}
    url = "https://remotive.com/api/remote-jobs"
    with httpx.Client(timeout=10.0) as client:
        resp = client.get(url, params=params)
        if resp.status_code != 200:
            return [], 0
        data = resp.json()
        jobs = data.get("jobs", [])
        out = []
        # Determine strict target based on user location
        loc_filter = _normalize_text(location)
        target_country = None
        if any(k in loc_filter for k in ["panama", "panama"]):
            target_country = "panama"
        elif "colombia" in loc_filter:
            target_country = "colombia"
        elif any(k in loc_filter for k in ["mexico", "mexico"]):
            target_country = "mexico"
        for j in jobs:
            loc_str = j.get("candidate_required_location") or j.get("job_type") or "Remote"
            # strict filter toward PA/CO/MX/LatAm, exclude Brazil explicitly
            keep = False
            loc_lower = _normalize_text(loc_str)
            latam_markers = ["panama", "colombia", "mexico", "latam", "latin america", "remote", "anywhere", "global"]
            if target_country:
                # Strict: must mention target country explicitly
                keep = target_country in loc_lower
            else:
                if any(x in loc_lower for x in latam_markers):
                    keep = True
            if "brazil" in loc_lower or "brasil" in loc_lower:
                keep = False
            if remote is not None and remote.lower() == "false":
                # user asked not remote; Remotive is mostly remote, so skip
                if not (target_country and target_country in loc_lower):
                    keep = False
            if not keep:
                continue
            out.append({
                "title": j.get("title"),
                "company": j.get("company_name"),
                "location": loc_str,
                "url": j.get("url"),
                "salary_min": None,
                "salary_max": None,
                "contract_time": None,
                "contract_type": None,
                "source": "remotive",
            })
        return out, len(out)


def _arbeitnow_fetch(
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
    sort_by: str | None,
    countries_filter: set[str],
    per_source_limit: int,
):
    """Arbeitnow Job Board API - no key."""
    url = "https://www.arbeitnow.com/api/job-board-api"
    with httpx.Client(timeout=10.0) as client:
        resp = client.get(url)
        if resp.status_code != 200:
            return [], 0
        data = resp.json()
        jobs = data.get("data", [])
        out = []
        for j in jobs:
            title = j.get("title") or ""
            company = j.get("company")
            loc = j.get("location") or ""
            remote_tag = j.get("remote") or False
            # text filter
            if query and query.lower() not in f"{title} {company} {loc}".lower():
                continue
            # country filter (loose, by location text)
            loc_filter = _normalize_text(location)
            target_country = None
            if "panama" in loc_filter:
                target_country = "panama"
            elif "colombia" in loc_filter:
                target_country = "colombia"
            elif "mexico" in loc_filter:
                target_country = "mexico"
            loc_lower = _normalize_text(loc)
            if target_country:
                # Strict: must mention target country explicitly
                keep_country = target_country in loc_lower
            else:
                keep_country = any(x in loc_lower for x in ["panama", "colombia", "mexico"]) or remote_tag
            if not keep_country:
                continue
            if remote is not None and remote.lower() == "false" and remote_tag:
                continue
            out.append({
                "title": title,
                "company": company,
                "location": loc if loc else ("Remote" if remote_tag else None),
                "url": j.get("url"),
                "salary_min": None,
                "salary_max": None,
                "contract_time": None,
                "contract_type": None,
                "source": "arbeitnow",
            })
            if len(out) >= per_source_limit:
                break
        return out, len(out)


def _remoteok_fetch(
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
    sort_by: str | None,
    countries_filter: set[str],
    per_source_limit: int,
):
    """RemoteOK public JSON. Nota: filtra LatAm y excluye Brasil."""
    url = "https://remoteok.com/api"
    with httpx.Client(timeout=10.0, headers={"User-Agent": "InnovateJobs/1.0"}) as client:
        resp = client.get(url)
        if resp.status_code != 200:
            return [], 0
        try:
            data = resp.json()
        except Exception:
            return [], 0
        if not isinstance(data, list):
            return [], 0
        # First element often contains metadata
        posts = [x for x in data if isinstance(x, dict) and x.get("position")]
        out = []
        # Determine strict target based on user location
        loc_filter = _normalize_text(location)
        target_country = None
        if "panama" in loc_filter or "panama" in loc_filter:
            target_country = "panama"
        elif "colombia" in loc_filter:
            target_country = "colombia"
        elif "mexico" in loc_filter or "mexico" in loc_filter:
            target_country = "mexico"
        for j in posts:
            title = j.get("position") or ""
            company = j.get("company") or j.get("company_name")
            loc = (j.get("location") or "Remote").strip()
            desc = (j.get("description") or "")
            url_job = j.get("url") or j.get("apply_url")
            text = f"{title} {company} {loc} {desc}".lower()
            if query and query.lower() not in text:
                continue
            # Strict: if target country specified, must mention it explicitly
            if target_country:
                if target_country not in text:
                    continue
            else:
                # No specific location: allow LatAm markers
                include_markers = ["panama", "colombia", "mexico", "latam", "latin america", "anywhere", "global", "remote"]
                if not any(m in text for m in include_markers):
                    continue
            if "brazil" in text or "brasil" in text:
                continue
            out.append({
                "title": title,
                "company": company,
                "location": loc,
                "url": url_job,
                "salary_min": None,
                "salary_max": None,
                "contract_time": None,
                "contract_type": None,
                "source": "remoteok",
            })
            if len(out) >= per_source_limit:
                break
        return out, len(out)


def _indeed_rss_fetch(
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
    sort_by: str | None,
    countries_filter: set[str],
    per_source_limit: int,
):
    """Indeed RSS feed parser - public, no API key needed. LATAM: mx, co, pa."""
    # Indeed RSS country codes mapping
    indeed_country_map = {
        "mx": "mx",  # Mexico
        "co": "co",  # Colombia
        "pa": "pa",  # Panama
    }
    indeed_country = indeed_country_map.get(country)
    if not indeed_country:
        return [], 0
    
    # Build RSS URL
    base_url = f"https://{indeed_country}.indeed.com/rss"
    params = {"q": query or ""}
    if location:
        params["l"] = location
    url = f"{base_url}?" + "&".join(f"{k}={v}" for k, v in params.items() if v)
    
    try:
        with httpx.Client(timeout=10.0, headers={"User-Agent": "InnovateJobs/1.0"}) as client:
            resp = client.get(url)
            if resp.status_code != 200:
                return [], 0
            # Parse RSS XML
            root = ET.fromstring(resp.text)
            # Indeed RSS uses standard RSS 2.0 format (no namespace)
            items = root.findall(".//item")
            out = []
            for item in items[:per_source_limit]:
                title_elem = item.find("title")
                link_elem = item.find("link")
                desc_elem = item.find("description")
                if not title_elem or not link_elem:
                    continue
                title = (title_elem.text or "").strip()
                url_job = (link_elem.text or "").strip()
                desc = (desc_elem.text or "").strip() if desc_elem is not None else ""
                # Extract company/location from description if available
                company = ""
                location_str = location or ""
                if desc:
                    # Simple extraction from description
                    parts = desc.split(" - ")
                    if len(parts) >= 2:
                        company = parts[0].strip()
                        location_str = parts[1].strip() if not location else location
                out.append({
                    "title": title,
                    "company": company or "Indeed",
                    "location": location_str,
                    "url": url_job,
                    "salary_min": None,
                    "salary_max": None,
                    "contract_time": None,
                    "contract_type": None,
                    "source": "indeed",
                })
            return out, len(out)
    except Exception as e:
        logger.warning("indeed rss error: %s", e)
        return [], 0


@jobs_bp.post("/track-click")
@limiter.limit("240/minute")
def track_click():
    user_id = None
    try:
        verify_jwt_in_request(optional=True)
        identity = get_jwt_identity()
        if identity:
            user_id = int(identity)
    except jwt_ex.NoAuthorizationError:
        pass

    data = request.get_json() or {}
    url = (data.get("url") or "").strip()
    if not url:
        return jsonify({"error": "url required"}), 400
    click = JobClick(
        user_id=user_id,
        url=url,
        title=(data.get("title") or ""),
        company=(data.get("company") or ""),
        source=(data.get("source") or ""),
    )
    db.session.add(click)
    db.session.commit()
    return jsonify({"ok": True})
