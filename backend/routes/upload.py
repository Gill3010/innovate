import os
from uuid import uuid4
from flask import Blueprint, request, jsonify, current_app, send_from_directory
from werkzeug.utils import secure_filename
from backend.firebase_service import firebase_service

upload_bp = Blueprint("upload", __name__)

UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "..", "uploads")
UPLOAD_DIR = os.path.abspath(UPLOAD_DIR)
ALLOWED = {"png", "jpg", "jpeg", "gif", "webp"}


@upload_bp.post("/image")
def upload_image():
    if "file" not in request.files:
        return jsonify({"error": "file part missing"}), 400
    f = request.files["file"]
    if f.filename == "":
        return jsonify({"error": "empty filename"}), 400
    ext = f.filename.rsplit(".", 1)[-1].lower()
    if ext not in ALLOWED:
        return jsonify({"error": "unsupported type"}), 400
    
    # Determinar el tipo de contenido
    content_type_map = {
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "gif": "image/gif",
        "webp": "image/webp"
    }
    content_type = content_type_map.get(ext, "image/jpeg")
    
    # Leer el archivo
    file_data = f.read()
    name = secure_filename(f"{uuid4().hex}.{ext}")
    
    # Si Firebase está habilitado, subir a Firebase Storage
    if firebase_service.is_enabled:
        try:
            url = firebase_service.upload_image(
                file_data=file_data,
                file_name=name,
                folder="uploads",
                content_type=content_type
            )
            return jsonify({"url": url})
        except Exception as e:
            # Si falla Firebase, caer back a almacenamiento local
            print(f"Error al subir a Firebase Storage: {e}")
            print("Usando almacenamiento local como fallback...")
    
    # Almacenamiento local (desarrollo o fallback)
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    path = os.path.join(UPLOAD_DIR, name)
    with open(path, "wb") as saved_file:
        saved_file.write(file_data)
    # Blueprint is mounted at /api, so the public URL should include that prefix
    url = f"/api/uploads/{name}"
    return jsonify({"url": url})


@upload_bp.get("/uploads/<path:name>")
def serve_upload(name: str):
    return send_from_directory(UPLOAD_DIR, name)
