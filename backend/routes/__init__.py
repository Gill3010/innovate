from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from backend.extensions import limiter, db
from backend.models import User
from backend.firebase_service import firebase_service

users_bp = Blueprint("users", __name__)


@users_bp.get("/me")
@jwt_required()
@limiter.limit("60/minute")
def get_my_profile():
    """Get current user's profile"""
    user_id = get_jwt_identity()
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Firebase: obtener usuario
        user_data = firebase_service.get_user(user_id)
        if not user_data:
            return jsonify({"error": "User not found"}), 404
        return jsonify(_firebase_user_to_dict(user_data))
    else:
        # Local: usar SQL
        user_id = int(user_id)
        user = User.query.get_or_404(user_id)
        return jsonify(_user_to_dict(user))


@users_bp.put("/me")
@jwt_required()
@limiter.limit("20/minute")
def update_my_profile():
    """Update current user's profile"""
    user_id = get_jwt_identity()
    data = request.get_json() or {}
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Firebase: obtener y actualizar usuario
        user_data = firebase_service.get_user(user_id)
        if not user_data:
            return jsonify({"error": "User not found"}), 404
        
        # Actualizar campos permitidos
        update_fields = {}
        if "name" in data:
            update_fields["name"] = data["name"]
        if "bio" in data:
            update_fields["bio"] = data["bio"]
        if "title" in data:
            update_fields["title"] = data["title"]
        if "location" in data:
            update_fields["location"] = data["location"]
        if "avatar_url" in data:
            update_fields["avatar_url"] = data["avatar_url"]
        if "phone" in data:
            update_fields["phone"] = data["phone"]
        if "linkedin_url" in data:
            update_fields["linkedin_url"] = data["linkedin_url"]
        if "github_url" in data:
            update_fields["github_url"] = data["github_url"]
        if "website_url" in data:
            update_fields["website_url"] = data["website_url"]
        
        # Actualizar el usuario con los nuevos campos
        user_data.update(update_fields)
        firebase_service.save_user(user_id, user_data)
        
        # Obtener el usuario actualizado
        updated_user = firebase_service.get_user(user_id)
        return jsonify(_firebase_user_to_dict(updated_user))
    else:
        # Local: usar SQL
        user_id = int(user_id)
        user = User.query.get_or_404(user_id)
        
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
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Firebase: buscar usuario por portfolio_share_token
        user = firebase_service.get_user_by_portfolio_token(token)
        if not user:
            return jsonify({"error": "User not found"}), 404
        return jsonify({
            "id": user.get("id", ""),
            "name": user.get("name", ""),
            "bio": user.get("bio", ""),
            "title": user.get("title", ""),
            "location": user.get("location", ""),
            "avatar_url": user.get("avatar_url", ""),
            "linkedin_url": user.get("linkedin_url", ""),
            "github_url": user.get("github_url", ""),
            "website_url": user.get("website_url", ""),
        })
    else:
        # Local: usar SQL
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


def _firebase_user_to_dict(user_data: dict) -> dict:
    """Convert Firebase user data to dict (omit sensitive fields)"""
    from datetime import datetime
    created_at = user_data.get("created_at")
    if isinstance(created_at, datetime):
        created_at = created_at.isoformat()
    elif created_at:
        created_at = str(created_at)
    
    return {
        "id": user_data.get("id", ""),
        "email": user_data.get("email", ""),
        "name": user_data.get("name", ""),
        "bio": user_data.get("bio", ""),
        "title": user_data.get("title", ""),
        "location": user_data.get("location", ""),
        "avatar_url": user_data.get("avatar_url", ""),
        "phone": user_data.get("phone", ""),
        "linkedin_url": user_data.get("linkedin_url", ""),
        "github_url": user_data.get("github_url", ""),
        "website_url": user_data.get("website_url", ""),
        "portfolio_share_token": user_data.get("portfolio_share_token", ""),
        "created_at": created_at,
    }


