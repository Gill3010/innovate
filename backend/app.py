import os
from flask import Flask, jsonify
from dotenv import load_dotenv
from backend.extensions import db, jwt, cache, cors, limiter
from backend.routes.auth import auth_bp
from backend.routes.projects import projects_bp
from backend.routes.jobs import jobs_bp
from backend.routes.ai import ai_bp
from backend.config import get_config


def create_app() -> Flask:
    load_dotenv()
    app = Flask(__name__)
    app.config.from_object(get_config())

    db.init_app(app)
    jwt.init_app(app)
    cache.init_app(app)
    cors.init_app(app, resources={r"/*": {"origins": app.config.get("CORS_ORIGINS", "*")}})
    limiter.init_app(app)

    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(projects_bp, url_prefix="/api/projects")
    app.register_blueprint(jobs_bp, url_prefix="/api/jobs")
    app.register_blueprint(ai_bp, url_prefix="/api/ai")

    @app.get("/api/health")
    @limiter.exempt
    def health():
        return jsonify(status="ok"), 200

    with app.app_context():
        if app.config.get("AUTO_CREATE_DB", False):
            db.create_all()

    return app


if __name__ == "__main__":
    app = create_app()
    port = int(os.getenv("PORT", "8000"))
    app.run(host="0.0.0.0", port=port)
