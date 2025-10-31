import json
from flask import Blueprint, render_template, abort, request, url_for
from backend.extensions import limiter
from backend.models import User, Project


share_bp = Blueprint("share", __name__)


def _make_absolute_url(path: str) -> str:
    """Convert relative URL to absolute URL."""
    if not path:
        return ""
    if path.startswith("http://") or path.startswith("https://"):
        return path
    # Use request.host_url to get base URL
    base = request.host_url.rstrip("/")
    if path.startswith("/"):
        return f"{base}{path}"
    return f"{base}/{path}"


def _parse_list_field(raw: str) -> list[str]:
    """Parse a list field that may be stored as JSON array or plain text.
    Accepts JSON like '["/a","/b"]' or plain text separated by newlines/commas.
    Returns a list of trimmed non-empty strings.
    """
    if not raw:
        return []
    # Try JSON first
    try:
        data = json.loads(raw)
        if isinstance(data, list):
            return [str(x).strip() for x in data if str(x).strip()]
    except Exception:
        pass
    # Fallback: split by newlines and commas
    parts = []
    for line in str(raw).split("\n"):
        parts.extend(line.split(","))
    return [p.strip() for p in parts if p and p.strip()]


@share_bp.get("/p/<token>")
@limiter.limit("120/minute")
def share_project_page(token: str):
    """Public HTML page for a shared project identified by share token."""
    project = Project.query.filter_by(share_token=token).first()
    if not project:
        abort(404)
    # Get owner to check if portfolio is shareable
    owner = User.query.get(project.user_id)
    portfolio_token = owner.portfolio_share_token if owner else None
    
    # Process images: parse list field and convert to absolute URLs
    raw_images = _parse_list_field(project.images or "")
    images = [_make_absolute_url(img) for img in raw_images]
    
    # Build a simple ViewModel
    vm = {
        "title": project.title or "Proyecto",
        "description": project.description or "",
        "technologies": [t.strip() for t in (project.technologies or "").split(";") if t.strip()] or [],
        "images": images,
        "links": _parse_list_field(project.links or ""),
        "category": project.category or "general",
    }
    # Cover image fallback (already absolute from images array)
    cover = vm["images"][0] if vm["images"] else None
    return render_template("project_share.html", vm=vm, cover=cover, portfolio_token=portfolio_token)


@share_bp.get("/pf/<token>")
@limiter.limit("120/minute")
def share_portfolio_page(token: str):
    """Public HTML page for a user's shared portfolio identified by portfolio share token."""
    user = User.query.filter_by(portfolio_share_token=token).first()
    if not user:
        abort(404)
    projects = Project.query.filter_by(user_id=user.id).order_by(Project.created_at.desc()).all()
    items = []
    for p in projects:
        images_list = _parse_list_field(p.images or "")
        first = images_list[0] if images_list else None
        cover_absolute = _make_absolute_url(first) if first else None
        items.append({
            "title": p.title,
            "description": p.description or "",
            "category": p.category or "general",
            "cover": cover_absolute,
            "token": p.share_token,
        })
    # Process avatar URL
    raw_avatar = (user.avatar_url or "").strip() or None
    avatar_absolute = _make_absolute_url(raw_avatar) if raw_avatar else None
    
    portfolio_vm = {
        "owner_name": user.name or "",
        "title": (user.title or "").strip(),
        "bio": (user.bio or "").strip(),
        "avatar": avatar_absolute,
        "links": {
            "linkedin": (user.linkedin_url or "").strip() or None,
            "github": (user.github_url or "").strip() or None,
            "website": (user.website_url or "").strip() or None,
        },
        "projects": items,
    }
    # Choose an image for previews: avatar or first project cover
    cover = portfolio_vm["avatar"] or next((i["cover"] for i in items if i.get("cover")), None)
    cover_absolute = _make_absolute_url(cover) if cover else None
    return render_template("portfolio_share.html", vm=portfolio_vm, cover=cover_absolute)


