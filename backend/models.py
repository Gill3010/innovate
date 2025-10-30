from datetime import datetime
from backend.extensions import db


class User(db.Model):
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    name = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class Project(db.Model):
    __tablename__ = "projects"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, default="")
    technologies = db.Column(db.String(512), default="")
    images = db.Column(db.Text, default="")
    links = db.Column(db.Text, default="")
    category = db.Column(db.String(128), default="general")
    featured = db.Column(db.Boolean, default=False)
    share_token = db.Column(db.String(32), unique=True, nullable=True, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class FavoriteJob(db.Model):
    __tablename__ = "favorite_jobs"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    title = db.Column(db.String(255), nullable=False)
    company = db.Column(db.String(255), nullable=False)
    location = db.Column(db.String(255), default="")
    url = db.Column(db.String(512), nullable=False)
    source = db.Column(db.String(64), default="adzuna")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    __table_args__ = (db.UniqueConstraint("user_id", "url", name="uq_fav_user_url"),)


class JobClick(db.Model):
    __tablename__ = "job_clicks"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True, index=True)
    url = db.Column(db.String(512), nullable=False)
    title = db.Column(db.String(255))
    company = db.Column(db.String(255))
    source = db.Column(db.String(64))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    __table_args__ = (db.Index("ix_job_clicks_url_created", "url", "created_at"),)
