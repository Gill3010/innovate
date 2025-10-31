"""Projects blueprint - aggregates all project-related routes."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, verify_jwt_in_request
from flask_jwt_extended import exceptions as jwt_ex
from sqlalchemy import or_
from backend.extensions import db, cache, limiter
from backend.models import Project, User
from .project_utils import sanitize_str, project_to_dict, project_to_dict_with_token
import secrets

projects_bp = Blueprint("projects", __name__)


# ============= CRUD Operations =============
@projects_bp.post("")
@jwt_required()
@limiter.limit("20/minute")
def create_project():
    """Create a new project."""
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    title = sanitize_str(data.get("title", ""))
    if not title:
        return jsonify({"error": "title is required"}), 400
    p = Project(
        user_id=user_id,
        title=title,
        description=data.get("description", ""),
        technologies=sanitize_str(data.get("technologies", ""), 512),
        images=data.get("images", ""),
        links=data.get("links", ""),
        category=sanitize_str(data.get("category", "general"), 128),
        featured=bool(data.get("featured", False)),
    )
    db.session.add(p)
    db.session.commit()
    cache.clear()
    return jsonify({"id": p.id}), 201


@projects_bp.put("/<int:project_id>")
@jwt_required()
@limiter.limit("20/minute")
def update_project(project_id: int):
    """Update an existing project."""
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    p = Project.query.get_or_404(project_id)
    if p.user_id != user_id:
        return jsonify({"error": "Not owner"}), 403
    if "title" in data:
        p.title = sanitize_str(data.get("title", p.title))
    if "description" in data:
        p.description = data.get("description", p.description)
    if "technologies" in data:
        p.technologies = sanitize_str(data.get("technologies", p.technologies), 512)
    if "images" in data:
        p.images = data.get("images", p.images)
    if "links" in data:
        p.links = data.get("links", p.links)
    if "category" in data:
        p.category = sanitize_str(data.get("category", p.category), 128)
    if "featured" in data:
        p.featured = bool(data.get("featured", p.featured))
    db.session.commit()
    cache.clear()
    return jsonify({"ok": True})


@projects_bp.delete("/<int:project_id>")
@jwt_required()
@limiter.limit("10/minute")
def delete_project(project_id: int):
    """Delete a project."""
    user_id = int(get_jwt_identity())
    p = Project.query.get_or_404(project_id)
    if p.user_id != user_id:
        return jsonify({"error": "Not owner"}), 403
    db.session.delete(p)
    db.session.commit()
    cache.clear()
    return jsonify({"ok": True})


@projects_bp.get("/<int:project_id>")
@limiter.limit("60/minute")
def get_project(project_id: int):
    """Get a single project by ID."""
    p = Project.query.get_or_404(project_id)
    return jsonify(project_to_dict_with_token(p))


# ============= Listing Operations =============
@projects_bp.get("")
@limiter.limit("60/minute")
def list_projects():
    """List projects with optional filtering."""
    owner_filter = request.args.get("owner")
    user_id = None
    try:
        verify_jwt_in_request(optional=True)
        identity = get_jwt_identity()
        if identity:
            user_id = int(identity)
    except (jwt_ex.NoAuthorizationError, ValueError):
        pass

    q = Project.query
    if owner_filter == "me" and user_id:
        q = q.filter(Project.user_id == user_id)
    elif owner_filter and owner_filter.isdigit():
        q = q.filter(Project.user_id == int(owner_filter))
    elif user_id and not owner_filter:
        q = q.filter(Project.user_id == user_id)

    category = request.args.get("category")
    featured = request.args.get("featured")
    if category:
        q = q.filter(Project.category == sanitize_str(category, 128))
    if featured is not None:
        q = q.filter(Project.featured == (featured.lower() == "true"))
    items = q.order_by(Project.created_at.desc()).all()
    return jsonify([project_to_dict_with_token(p) for p in items])


@projects_bp.get("/public")
@limiter.limit("120/minute")
def list_public_projects():
    """Public explore endpoint with pagination and filters."""
    page = max(int(request.args.get("page", 1)), 1)
    per_page = min(max(int(request.args.get("per_page", 20)), 1), 50)
    q = Project.query
    category = request.args.get("category")
    if category:
        q = q.filter(Project.category == sanitize_str(category, 128))
    term = request.args.get("q")
    if term:
        t = f"%{sanitize_str(term, 255)}%"
        q = q.filter(or_(Project.title.ilike(t), Project.description.ilike(t)))
    order = (request.args.get("order") or "new").lower()
    if order == "old":
        q = q.order_by(Project.created_at.asc())
    else:
        q = q.order_by(Project.created_at.desc())
    total = q.count()
    items = q.offset((page - 1) * per_page).limit(per_page).all()
    return jsonify({
        "page": page,
        "per_page": per_page,
        "total": total,
        "items": [project_to_dict(p) for p in items],
    })


# ============= Sharing Operations =============
@projects_bp.post("/<int:project_id>/share")
@jwt_required()
@limiter.limit("10/minute")
def share_project(project_id: int):
    """Generate a share token for a specific project."""
    user_id = int(get_jwt_identity())
    p = Project.query.get_or_404(project_id)
    if p.user_id != user_id:
        return jsonify({"error": "Not owner"}), 403
    if not p.share_token:
        p.share_token = secrets.token_urlsafe(16)
        db.session.commit()
        cache.clear()
    return jsonify({
        "share_token": p.share_token,
        "share_url": f"/api/projects/shared/{p.share_token}"
    })


@projects_bp.get("/shared/<token>")
@limiter.limit("60/minute")
def get_shared_project(token: str):
    """Get a project by its share token."""
    p = Project.query.filter_by(share_token=token).first_or_404()
    return jsonify(project_to_dict(p))


@projects_bp.post("/portfolio/share")
@jwt_required()
@limiter.limit("10/minute")
def share_portfolio():
    """Generate a share token for user's entire portfolio."""
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)
    if not user.portfolio_share_token:
        user.portfolio_share_token = secrets.token_urlsafe(16)
        db.session.commit()
        cache.clear()
    return jsonify({
        "share_token": user.portfolio_share_token,
        "share_url": f"/api/projects/portfolio/{user.portfolio_share_token}"
    })


@projects_bp.get("/portfolio/<token>")
@limiter.limit("60/minute")
def get_shared_portfolio(token: str):
    """Get all projects for a user by their portfolio share token."""
    user = User.query.filter_by(portfolio_share_token=token).first_or_404()
    projects = Project.query.filter_by(user_id=user.id).order_by(
        Project.created_at.desc()
    ).all()
    return jsonify([project_to_dict(p) for p in projects])
