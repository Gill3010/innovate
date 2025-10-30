from flask import Blueprint, jsonify
from backend.extensions import limiter
from backend.models import User

users_bp = Blueprint("users", __name__)

@users_bp.get("/profile/<token>")
@limiter.limit("60/minute")
def get_public_profile(token: str):
    user = User.query.filter_by(portfolio_share_token=token).first_or_404()
    return jsonify({
        "id": user.id,
        "name": user.name or "",
    })


