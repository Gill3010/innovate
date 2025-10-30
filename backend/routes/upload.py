import os
from uuid import uuid4
from flask import Blueprint, request, jsonify, current_app, send_from_directory
from werkzeug.utils import secure_filename

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
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    name = secure_filename(f"{uuid4().hex}.{ext}")
    path = os.path.join(UPLOAD_DIR, name)
    f.save(path)
    # Blueprint is mounted at /api, so the public URL should include that prefix
    url = f"/api/uploads/{name}"
    return jsonify({"url": url})


@upload_bp.get("/uploads/<path:name>")
def serve_upload(name: str):
    return send_from_directory(UPLOAD_DIR, name)
