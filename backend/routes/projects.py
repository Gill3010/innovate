from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, verify_jwt_in_request
from flask_jwt_extended import exceptions as jwt_ex
from backend.extensions import db, cache, limiter
from backend.models import Project
import secrets

projects_bp = Blueprint("projects", __name__)


def sanitize_str(value: str, max_len: int = 255) -> str:
    if not isinstance(value, str):
        return ""
    return value.strip()[:max_len]


@projects_bp.get("")
@limiter.limit("60/minute")
@cache.cached(timeout=120, query_string=True)
def list_projects():
    owner_filter = request.args.get("owner")  # "me" or user_id
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
        # Default: show only my projects if logged in
        q = q.filter(Project.user_id == user_id)

    category = request.args.get("category")
    featured = request.args.get("featured")
    if category:
        q = q.filter(Project.category == sanitize_str(category, 128))
    if featured is not None:
        q = q.filter(Project.featured == (featured.lower() == "true"))
    items = q.order_by(Project.created_at.desc()).all()
    return jsonify([
        {
            "id": p.id,
            "user_id": p.user_id,
            "title": p.title,
            "description": p.description,
            "technologies": p.technologies,
            "images": p.images,
            "links": p.links,
            "category": p.category,
            "featured": p.featured,
            "share_token": p.share_token,
        }
        for p in items
    ])


@projects_bp.get("/<int:project_id>")
@limiter.limit("60/minute")
def get_project(project_id: int):
    p = Project.query.get_or_404(project_id)
    return jsonify({
        "id": p.id,
        "title": p.title,
        "description": p.description,
        "technologies": p.technologies,
        "images": p.images,
        "links": p.links,
        "category": p.category,
        "featured": p.featured,
    })


@projects_bp.post("")
@jwt_required()
@limiter.limit("20/minute")
def create_project():
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
    user_id = int(get_jwt_identity())
    p = Project.query.get_or_404(project_id)
    if p.user_id != user_id:
        return jsonify({"error": "Not owner"}), 403
    db.session.delete(p)
    db.session.commit()
    cache.clear()
    return jsonify({"ok": True})


@projects_bp.post("/<int:project_id>/share")
@jwt_required()
@limiter.limit("10/minute")
def share_project(project_id: int):
    user_id = int(get_jwt_identity())
    p = Project.query.get_or_404(project_id)
    if p.user_id != user_id:
        return jsonify({"error": "Not owner"}), 403
    if not p.share_token:
        p.share_token = secrets.token_urlsafe(16)
        db.session.commit()
        cache.clear()
    return jsonify({"share_token": p.share_token, "share_url": f"/api/projects/shared/{p.share_token}"})


@projects_bp.get("/shared/<token>")
@limiter.limit("60/minute")
def get_shared_project(token: str):
    p = Project.query.filter_by(share_token=token).first_or_404()
    return jsonify({
        "id": p.id,
        "title": p.title,
        "description": p.description,
        "technologies": p.technologies,
        "images": p.images,
        "links": p.links,
        "category": p.category,
        "featured": p.featured,
    })
