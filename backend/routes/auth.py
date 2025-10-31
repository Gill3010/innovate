from flask import Blueprint, request, jsonify, current_app
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import create_access_token
from backend.extensions import db, limiter
from backend.models import User
from backend.firebase_service import firebase_service
from datetime import datetime
import secrets

auth_bp = Blueprint("auth", __name__)


@auth_bp.post("/register")
@limiter.limit("10/minute")
def register():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""
    if not email or not password:
        return jsonify({"error": "email and password required"}), 400
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    # Verificar si el usuario ya existe
    if use_firebase and firebase_service.is_enabled:
        # Verificar en Firestore
        existing_user = firebase_service.get_user_by_email(email)
        if existing_user:
            return jsonify({"error": "user exists"}), 409
    else:
        # Verificar en SQLite/PostgreSQL
        if User.query.filter_by(email=email).first():
            return jsonify({"error": "user exists"}), 409
    
    password_hash = generate_password_hash(password)
    now = datetime.utcnow()
    
    # Guardar según el entorno
    if use_firebase and firebase_service.is_enabled:
        # Guardar en Firestore
        user_data = {
            "email": email,
            "password_hash": password_hash,
            "name": data.get("name", ""),
            "created_at": now,
            "updated_at": now,
        }
        # Usar el email como ID único o generar uno
        user_id = email.replace("@", "_at_").replace(".", "_")  # ID basado en email
        firebase_service.save_user(user_id, user_data)
        return jsonify({"id": user_id}), 201
    else:
        # Guardar en SQLite/PostgreSQL (comportamiento original)
        user = User(email=email, password_hash=password_hash)
        db.session.add(user)
        db.session.commit()
        return jsonify({"id": user.id}), 201


@auth_bp.post("/login")
@limiter.limit("20/minute")
def login():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    # Buscar usuario según el entorno
    user = None
    user_id = None
    
    if use_firebase and firebase_service.is_enabled:
        # Buscar en Firestore
        user = firebase_service.get_user_by_email(email)
        if not user:
            return jsonify({"error": "invalid credentials"}), 401
        user_id = user.get("id")
        password_hash = user.get("password_hash")
        if not check_password_hash(password_hash, password):
            return jsonify({"error": "invalid credentials"}), 401
    else:
        # Buscar en SQLite/PostgreSQL
        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({"error": "invalid credentials"}), 401
        if not check_password_hash(user.password_hash, password):
            return jsonify({"error": "invalid credentials"}), 401
        user_id = str(user.id)
    
    token = create_access_token(identity=user_id)
    return jsonify({"access_token": token})
