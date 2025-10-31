import json
from flask import Blueprint, render_template, abort, request, url_for, current_app
from backend.extensions import limiter
from backend.models import User, Project
from backend.firebase_service import firebase_service


share_bp = Blueprint("share", __name__)


def _make_absolute_url(path: str) -> str:
    """Convert relative URL to absolute URL using request's host.
    This ensures URLs work correctly for both local and network clients."""
    if not path:
        return ""
    if path.startswith("http://") or path.startswith("https://"):
        # Already absolute - extract path and rebuild with current host
        # This fixes URLs stored with wrong IPs (127.0.0.1, 10.0.2.2, etc.)
        try:
            from urllib.parse import urlparse
            parsed = urlparse(path)
            path = parsed.path  # Extract just the path part
        except Exception:
            return path  # If parsing fails, return as-is
    
    # Build absolute URL using request's host
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
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Firebase: buscar proyecto por share_token
        project = firebase_service.get_project_by_share_token(token)
        if not project:
            abort(404)
        
        # Get owner to check if portfolio is shareable
        user_id = project.get("user_id")
        owner = firebase_service.get_user(user_id) if user_id else None
        portfolio_token = owner.get("portfolio_share_token") if owner else None
        
        # Process images: Firebase almacena como array
        raw_images = project.get("images") or []
        if isinstance(raw_images, str):
            raw_images = _parse_list_field(raw_images)
        images = [_make_absolute_url(img) if not img.startswith("http") else img for img in raw_images]
        
        # Build a simple ViewModel
        vm = {
            "title": project.get("title") or "Proyecto",
            "description": project.get("description") or "",
            "technologies": [t.strip() for t in (project.get("technologies") or "").split(";") if t.strip()] or [],
            "images": images,
            "links": project.get("links") or [],
            "category": project.get("category") or "general",
        }
        if isinstance(vm["links"], str):
            vm["links"] = _parse_list_field(vm["links"])
    else:
        # Local: usar SQL
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
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Firebase: buscar usuario por portfolio_share_token
        user = firebase_service.get_user_by_portfolio_token(token)
        if not user:
            abort(404)
        user_id = user.get("id")
        
        # Obtener proyectos del usuario ordenados por fecha
        projects = firebase_service.get_user_projects(user_id)
        # Ordenar en Python (Firestore sin order_by para evitar índices)
        projects = sorted(projects, key=lambda p: p.get("created_at", ""), reverse=True)
        
        items = []
        for p in projects:
            images_list = p.get("images") or []
            if isinstance(images_list, str):
                images_list = _parse_list_field(images_list)
            first = images_list[0] if images_list else None
            # Si la imagen ya es URL absoluta (Firebase Storage), no modificar
            if first and first.startswith("http"):
                cover_absolute = first
            else:
                cover_absolute = _make_absolute_url(first) if first else None
            items.append({
                "title": p.get("title", ""),
                "description": p.get("description", ""),
                "category": p.get("category", "general"),
                "cover": cover_absolute,
                "token": p.get("share_token"),
            })
        
        # Process avatar URL
        raw_avatar = (user.get("avatar_url") or "").strip() or None
        # Si el avatar ya es URL absoluta (Firebase Storage), no modificar
        if raw_avatar and raw_avatar.startswith("http"):
            avatar_absolute = raw_avatar
        else:
            avatar_absolute = _make_absolute_url(raw_avatar) if raw_avatar else None
        
        portfolio_vm = {
            "owner_name": user.get("name", ""),
            "title": (user.get("title") or "").strip(),
            "bio": (user.get("bio") or "").strip(),
            "avatar": avatar_absolute,
            "links": {
                "linkedin": (user.get("linkedin_url") or "").strip() or None,
                "github": (user.get("github_url") or "").strip() or None,
                "website": (user.get("website_url") or "").strip() or None,
            },
            "projects": items,
        }
    else:
        # Local: usar SQL
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
    cover_absolute = _make_absolute_url(cover) if cover and not cover.startswith("http") else cover
    return render_template("portfolio_share.html", vm=portfolio_vm, cover=cover_absolute)


