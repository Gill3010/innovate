from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from backend.extensions import limiter, db
from backend.models import User

users_bp = Blueprint("users", __name__)


@users_bp.get("/me")
@jwt_required()
@limiter.limit("60/minute")
def get_my_profile():
    """Get current user's profile"""
    user_id = int(get_jwt_identity())
    print(f"DEBUG: Looking for user_id={user_id}")
    user = User.query.get_or_404(user_id)
    return jsonify(_user_to_dict(user))


@users_bp.put("/me")
@jwt_required()
@limiter.limit("20/minute")
def update_my_profile():
    """Update current user's profile"""
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)
    data = request.get_json() or {}
    
    # Update allowed fields
    if "name" in data:
        user.name = data["name"]
    if "bio" in data:
        user.bio = data["bio"]
    if "title" in data:
        user.title = data["title"]
    if "location" in data:
        user.location = data["location"]
    if "avatar_url" in data:
        user.avatar_url = data["avatar_url"]
    if "phone" in data:
        user.phone = data["phone"]
    if "linkedin_url" in data:
        user.linkedin_url = data["linkedin_url"]
    if "github_url" in data:
        user.github_url = data["github_url"]
    if "website_url" in data:
        user.website_url = data["website_url"]
    
    db.session.commit()
    return jsonify(_user_to_dict(user))


@users_bp.get("/profile/<token>")
@limiter.limit("60/minute")
def get_public_profile(token: str):
    """Get public profile by share token"""
    user = User.query.filter_by(portfolio_share_token=token).first_or_404()
    return jsonify({
        "id": user.id,
        "name": user.name or "",
        "bio": user.bio or "",
        "title": user.title or "",
        "location": user.location or "",
        "avatar_url": user.avatar_url or "",
        "linkedin_url": user.linkedin_url or "",
        "github_url": user.github_url or "",
        "website_url": user.website_url or "",
    })


def _user_to_dict(user: User) -> dict:
    """Convert User to dict (omit sensitive fields)"""
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name or "",
        "bio": user.bio or "",
        "title": user.title or "",
        "location": user.location or "",
        "avatar_url": user.avatar_url or "",
        "phone": user.phone or "",
        "linkedin_url": user.linkedin_url or "",
        "github_url": user.github_url or "",
        "website_url": user.website_url or "",
        "portfolio_share_token": user.portfolio_share_token or "",
        "created_at": user.created_at.isoformat() if user.created_at else None,
    }


