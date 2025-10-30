from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from backend.extensions import db, limiter
from backend.models import FavoriteJob

favorites_bp = Blueprint("favorites", __name__)


@favorites_bp.get("/jobs")
@jwt_required()
@limiter.limit("120/minute")
def list_jobs():
    user_id = int(get_jwt_identity())
    items = FavoriteJob.query.filter_by(user_id=user_id).order_by(FavoriteJob.created_at.desc()).all()
    return jsonify([
        {
            "id": f.id,
            "title": f.title,
            "company": f.company,
            "location": f.location,
            "url": f.url,
            "source": f.source,
        }
        for f in items
    ])


@favorites_bp.post("/jobs")
@jwt_required()
@limiter.limit("60/minute")
def add_job():
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}
    title = (data.get("title") or "").strip()
    company = (data.get("company") or "").strip()
    url = (data.get("url") or "").strip()
    if not title or not company or not url:
        return jsonify({"error": "title, company, url required"}), 400
    existing = FavoriteJob.query.filter_by(user_id=user_id, url=url).first()
    if existing:
        return jsonify({"ok": True, "id": existing.id})
    fav = FavoriteJob(
        user_id=user_id,
        title=title,
        company=company,
        location=(data.get("location") or ""),
        url=url,
        source=(data.get("source") or "adzuna"),
    )
    db.session.add(fav)
    db.session.commit()
    return jsonify({"ok": True, "id": fav.id}), 201


@favorites_bp.delete("/jobs")
@jwt_required()
@limiter.limit("60/minute")
def remove_job():
    user_id = int(get_jwt_identity())
    url = (request.args.get("url") or "").strip()
    if not url:
        return jsonify({"error": "url required"}), 400
    FavoriteJob.query.filter_by(user_id=user_id, url=url).delete()
    db.session.commit()
    return jsonify({"ok": True})

