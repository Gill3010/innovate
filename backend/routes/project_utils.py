"""Utility functions for project routes."""


def sanitize_str(value: str, max_len: int = 255) -> str:
    """Sanitize and truncate a string value."""
    if not isinstance(value, str):
        return ""
    return value.strip()[:max_len]


def project_to_dict(project) -> dict:
    """Convert a Project model instance to a dictionary."""
    return {
        "id": project.id,
        "user_id": project.user_id,
        "title": project.title,
        "description": project.description,
        "technologies": project.technologies,
        "images": project.images,
        "links": project.links,
        "category": project.category,
        "featured": project.featured,
    }


def project_to_dict_with_token(project) -> dict:
    """Convert a Project model instance to a dictionary including share token."""
    data = project_to_dict(project)
    data["share_token"] = project.share_token
    return data

