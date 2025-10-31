import os
from datetime import timedelta


class BaseConfig:
    SECRET_KEY = os.getenv("SECRET_KEY", "change-me")
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "change-me-too")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=6)

    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
        f"sqlite:///{os.path.abspath(os.path.join(os.path.dirname(__file__), 'app.db'))}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")
    PREFERRED_URL_SCHEME = "https" if os.getenv("FORCE_HTTPS", "true").lower() == "true" else "http"

    CACHE_TYPE = os.getenv("CACHE_TYPE", "SimpleCache")
    CACHE_DEFAULT_TIMEOUT = int(os.getenv("CACHE_DEFAULT_TIMEOUT", "300"))

    RATELIMIT_DEFAULT = os.getenv("RATELIMIT_DEFAULT", "100 per minute")

    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")

    AUTO_CREATE_DB = os.getenv("AUTO_CREATE_DB", "false").lower() == "true"

    # Firebase configuration
    USE_FIREBASE = os.getenv("USE_FIREBASE", "false").lower() == "true"
    FIREBASE_STORAGE_BUCKET = os.getenv("FIREBASE_STORAGE_BUCKET", "")
    FIRESTORE_DATABASE = os.getenv("FIRESTORE_DATABASE", "innovate")
    GOOGLE_APPLICATION_CREDENTIALS = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")


class DevelopmentConfig(BaseConfig):
    DEBUG = True


class ProductionConfig(BaseConfig):
    DEBUG = False
    # En producción, usar Firebase por defecto
    USE_FIREBASE = os.getenv("USE_FIREBASE", "true").lower() == "true"


def get_config():
    env = os.getenv("FLASK_ENV", "development").lower()
    if env == "production":
        return ProductionConfig
    return DevelopmentConfig
