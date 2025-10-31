"""Projects blueprint - aggregates all project-related routes."""
from flask import Blueprint, request, jsonify, redirect, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity, verify_jwt_in_request
from flask_jwt_extended import exceptions as jwt_ex
from sqlalchemy import or_
from backend.extensions import db, cache, limiter
from backend.models import Project, User
from backend.firebase_service import firebase_service
from .project_utils import sanitize_str, project_to_dict, project_to_dict_with_token
from datetime import datetime
import secrets
import json

projects_bp = Blueprint("projects", __name__)


# ============= CRUD Operations =============
@projects_bp.post("")
@jwt_required()
@limiter.limit("20/minute")
def create_project():
    """Create a new project."""
    user_id_str = get_jwt_identity()
    data = request.get_json() or {}
    title = sanitize_str(data.get("title", ""))
    if not title:
        return jsonify({"error": "title is required"}), 400
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    now = datetime.utcnow()
    
    if use_firebase and firebase_service.is_enabled:
        # Guardar en Firestore - convertir images y links de string JSON a arrays
        images_str = data.get("images", "")
        images_array = []
        if images_str:
            try:
                images_array = json.loads(images_str) if isinstance(images_str, str) else images_str
            except (json.JSONDecodeError, TypeError):
                images_array = []
        
        links_str = data.get("links", "")
        links_array = []
        if links_str:
            try:
                links_array = json.loads(links_str) if isinstance(links_str, str) else links_str
            except (json.JSONDecodeError, TypeError):
                links_array = []
        
        project_data = {
            "user_id": user_id_str,  # En Firebase puede ser string
            "title": title,
            "description": data.get("description", ""),
            "technologies": sanitize_str(data.get("technologies", ""), 512),
            "images": images_array,  # Guardar como array nativo de Firestore
            "links": links_array,    # Guardar como array nativo de Firestore
            "category": sanitize_str(data.get("category", "general"), 128),
            "featured": bool(data.get("featured", False)),
            "created_at": now,
            "updated_at": now,
        }
        # Generar un ID único para el proyecto
        project_id = secrets.token_urlsafe(16)
        firebase_service.save_project(project_id, project_data)
        cache.clear()
        return jsonify({"id": project_id}), 201
    else:
        # Guardar en SQLite/PostgreSQL (comportamiento original)
        user_id = int(user_id_str)
        p = Project(
            user_id=user_id,
            title=title,
            description=data.get("description", ""),
            technologies=sanitize_str(data.get("technologies", ""), 512),
            images=data.get("images", ""),
            links=data.get("links", ""),
            category=sanitize_str(data.get("category", "general"), 128),
            featured=bool(data.get("featured", False)),
        )
        db.session.add(p)
        db.session.commit()
        cache.clear()
        return jsonify({"id": p.id}), 201


@projects_bp.put("/<project_id>")
@jwt_required()
@limiter.limit("20/minute")
def update_project(project_id: str):
    """Update an existing project."""
    user_id_str = get_jwt_identity()
    data = request.get_json() or {}
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Actualizar en Firestore
        project = firebase_service.get_project(str(project_id))
        if not project:
            return jsonify({"error": "Project not found"}), 404
        if str(project.get("user_id")) != user_id_str:
            return jsonify({"error": "Not owner"}), 403
        
        # Construir datos actualizados
        update_data = {"updated_at": datetime.utcnow()}
        if "title" in data:
            update_data["title"] = sanitize_str(data.get("title", project.get("title")))
        if "description" in data:
            update_data["description"] = data.get("description", project.get("description", ""))
        if "technologies" in data:
            update_data["technologies"] = sanitize_str(data.get("technologies", project.get("technologies", "")), 512)
        if "images" in data:
            # Convertir string JSON a array si es necesario
            images_val = data.get("images", "")
            if isinstance(images_val, str):
                try:
                    update_data["images"] = json.loads(images_val) if images_val else []
                except json.JSONDecodeError:
                    update_data["images"] = []
            else:
                update_data["images"] = images_val if images_val else []
        if "links" in data:
            # Convertir string JSON a array si es necesario
            links_val = data.get("links", "")
            if isinstance(links_val, str):
                try:
                    update_data["links"] = json.loads(links_val) if links_val else []
                except json.JSONDecodeError:
                    update_data["links"] = []
            else:
                update_data["links"] = links_val if links_val else []
        if "category" in data:
            update_data["category"] = sanitize_str(data.get("category", project.get("category", "general")), 128)
        if "featured" in data:
            update_data["featured"] = bool(data.get("featured", project.get("featured", False)))
        
        firebase_service.save_project(str(project_id), update_data)
        cache.clear()
        return jsonify({"ok": True})
    else:
        # Actualizar en SQLite/PostgreSQL
        try:
            user_id = int(user_id_str)
            project_id_int = int(project_id)
        except ValueError:
            return jsonify({"error": "Invalid project ID"}), 400
        
        p = Project.query.get_or_404(project_id_int)
        if p.user_id != user_id:
            return jsonify({"error": "Not owner"}), 403
        if "title" in data:
            p.title = sanitize_str(data.get("title", p.title))
        if "description" in data:
            p.description = data.get("description", p.description)
        if "technologies" in data:
            p.technologies = sanitize_str(data.get("technologies", p.technologies), 512)
        if "images" in data:
            p.images = data.get("images", p.images)
        if "links" in data:
            p.links = data.get("links", p.links)
        if "category" in data:
            p.category = sanitize_str(data.get("category", p.category), 128)
        if "featured" in data:
            p.featured = bool(data.get("featured", p.featured))
        db.session.commit()
        cache.clear()
        return jsonify({"ok": True})


@projects_bp.delete("/<project_id>")
@jwt_required()
@limiter.limit("10/minute")
def delete_project(project_id: str):
    """Delete a project."""
    user_id_str = get_jwt_identity()
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Eliminar de Firestore
        project = firebase_service.get_project(str(project_id))
        if not project:
            return jsonify({"error": "Project not found"}), 404
        if str(project.get("user_id")) != user_id_str:
            return jsonify({"error": "Not owner"}), 403
        firebase_service.delete_project(str(project_id))
        cache.clear()
        return jsonify({"ok": True})
    else:
        # Eliminar de SQLite/PostgreSQL
        try:
            user_id = int(user_id_str)
            project_id_int = int(project_id)
        except ValueError:
            return jsonify({"error": "Invalid project ID"}), 400
        
        p = Project.query.get_or_404(project_id_int)
        if p.user_id != user_id:
            return jsonify({"error": "Not owner"}), 403
        db.session.delete(p)
        db.session.commit()
        cache.clear()
        return jsonify({"ok": True})


@projects_bp.get("/<project_id>")
@limiter.limit("60/minute")
def get_project(project_id: str):
    """Get a single project by ID."""
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Obtener de Firestore
        project = firebase_service.get_project(str(project_id))
        if not project:
            return jsonify({"error": "Project not found"}), 404
        
        # Asegurar que images y links sean strings JSON válidos
        images = project.get("images")
        if images is None:
            images = "[]"
        elif not isinstance(images, str):
            # Si es una lista (puede pasar si Firestore lo retorna como lista)
            images = json.dumps(images) if images else "[]"
        
        links = project.get("links")
        if links is None:
            links = "[]"
        elif not isinstance(links, str):
            links = json.dumps(links) if links else "[]"
        
        # Convertir a formato similar al que espera project_to_dict_with_token
        result = {
            "id": project.get("id"),
            "user_id": project.get("user_id"),
            "title": project.get("title", ""),
            "description": project.get("description", ""),
            "technologies": project.get("technologies", ""),
            "images": images,
            "links": links,
            "category": project.get("category", "general"),
            "featured": project.get("featured", False),
            "share_token": project.get("share_token"),
            "created_at": project.get("created_at").isoformat() if project.get("created_at") else None,
            "updated_at": project.get("updated_at").isoformat() if project.get("updated_at") else None,
        }
        return jsonify(result)
    else:
        # Obtener de SQLite/PostgreSQL
        try:
            project_id_int = int(project_id)
        except ValueError:
            return jsonify({"error": "Invalid project ID"}), 400
        
        p = Project.query.get_or_404(project_id_int)
        return jsonify(project_to_dict_with_token(p))


# ============= Listing Operations =============
@projects_bp.get("")
@limiter.limit("60/minute")
def list_projects():
    """List projects with optional filtering."""
    owner_filter = request.args.get("owner")
    user_id_str = None
    try:
        verify_jwt_in_request(optional=True)
        identity = get_jwt_identity()
        if identity:
            user_id_str = identity
    except (jwt_ex.NoAuthorizationError, ValueError):
        pass

    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Obtener de Firestore
        # Determinar qué user_id usar según filtros
        target_user_id = None
        if owner_filter == "me" and user_id_str:
            target_user_id = user_id_str
        elif owner_filter and owner_filter.isdigit():
            target_user_id = owner_filter
        elif user_id_str and not owner_filter:
            target_user_id = user_id_str
        
        if target_user_id:
            projects = firebase_service.get_user_projects(target_user_id)
        else:
            # Si no hay filtro de usuario, obtener todos (esto necesita mejorarse en el futuro)
            projects = []
        
        # Aplicar filtros básicos (category y featured)
        category = request.args.get("category")
        featured = request.args.get("featured")
        
        if category:
            projects = [p for p in projects if p.get("category") == category]
        if featured is not None:
            projects = [p for p in projects if p.get("featured") == (featured.lower() == "true")]
        
        # Convertir a formato esperado
        result = []
        for p in projects:
            # Asegurar que images y links sean strings JSON válidos
            images = p.get("images")
            if images is None:
                images = "[]"
            elif not isinstance(images, str):
                # Si es una lista (puede pasar si Firestore lo retorna como lista)
                images = json.dumps(images) if images else "[]"
            
            links = p.get("links")
            if links is None:
                links = "[]"
            elif not isinstance(links, str):
                links = json.dumps(links) if links else "[]"
            
            result.append({
                "id": p.get("id"),
                "user_id": p.get("user_id"),
                "title": p.get("title", ""),
                "description": p.get("description", ""),
                "technologies": p.get("technologies", ""),
                "images": images,
                "links": links,
                "category": p.get("category", "general"),
                "featured": p.get("featured", False),
                "share_token": p.get("share_token"),
                "created_at": p.get("created_at").isoformat() if p.get("created_at") else None,
                "updated_at": p.get("updated_at").isoformat() if p.get("updated_at") else None,
            })
        return jsonify(result)
    else:
        # Obtener de SQLite/PostgreSQL
        user_id = int(user_id_str) if user_id_str and user_id_str.isdigit() else None
        q = Project.query
        if owner_filter == "me" and user_id:
            q = q.filter(Project.user_id == user_id)
        elif owner_filter and owner_filter.isdigit():
            q = q.filter(Project.user_id == int(owner_filter))
        elif user_id and not owner_filter:
            q = q.filter(Project.user_id == user_id)

        category = request.args.get("category")
        featured = request.args.get("featured")
        if category:
            q = q.filter(Project.category == sanitize_str(category, 128))
        if featured is not None:
            q = q.filter(Project.featured == (featured.lower() == "true"))
        items = q.order_by(Project.created_at.desc()).all()
        return jsonify([project_to_dict_with_token(p) for p in items])


@projects_bp.get("/public")
@limiter.limit("120/minute")
def list_public_projects():
    """Public explore endpoint with pagination and filters."""
    page = max(int(request.args.get("page", 1)), 1)
    per_page = min(max(int(request.args.get("per_page", 20)), 1), 50)
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Firebase: obtener todos los proyectos públicos
        # Firestore no soporta consultas sin filtros de manera eficiente,
        # así que obtenemos todos y filtramos/ordenamos en Python
        all_projects = firebase_service.get_all_projects()
        
        # Aplicar filtros
        category = request.args.get("category")
        if category:
            all_projects = [p for p in all_projects if p.get("category") == category]
        
        term = request.args.get("q")
        if term:
            term_lower = term.lower()
            all_projects = [
                p for p in all_projects
                if term_lower in (p.get("title", "") or "").lower() or
                   term_lower in (p.get("description", "") or "").lower()
            ]
        
        # Ordenar
        order = (request.args.get("order") or "new").lower()
        if order == "old":
            all_projects.sort(key=lambda p: p.get("created_at", datetime.min))
        else:
            all_projects.sort(key=lambda p: p.get("created_at", datetime.min), reverse=True)
        
        # Paginación
        total = len(all_projects)
        start = (page - 1) * per_page
        end = start + per_page
        items = all_projects[start:end]
        
        # Convertir a formato de respuesta
        result = []
        for p in items:
            # Asegurar que images y links sean strings JSON válidos
            images = p.get("images")
            if images is None:
                images = "[]"
            elif not isinstance(images, str):
                images = json.dumps(images) if images else "[]"
            
            links = p.get("links")
            if links is None:
                links = "[]"
            elif not isinstance(links, str):
                links = json.dumps(links) if links else "[]"
            
            result.append({
                "id": p.get("id", ""),
                "title": p.get("title", ""),
                "description": p.get("description", ""),
                "technologies": p.get("technologies", ""),
                "category": p.get("category", "general"),
                "featured": p.get("featured", False),
                "images": images,
                "links": links,
                "share_token": p.get("share_token", ""),
                "created_at": str(p.get("created_at", "")),
                "updated_at": str(p.get("updated_at", "")),
            })
        
        return jsonify({
            "page": page,
            "per_page": per_page,
            "total": total,
            "items": result,
        })
    else:
        # Local: usar SQL
        q = Project.query
        category = request.args.get("category")
        if category:
            q = q.filter(Project.category == sanitize_str(category, 128))
        term = request.args.get("q")
        if term:
            t = f"%{sanitize_str(term, 255)}%"
            q = q.filter(or_(Project.title.ilike(t), Project.description.ilike(t)))
        order = (request.args.get("order") or "new").lower()
        if order == "old":
            q = q.order_by(Project.created_at.asc())
        else:
            q = q.order_by(Project.created_at.desc())
        total = q.count()
        items = q.offset((page - 1) * per_page).limit(per_page).all()
        return jsonify({
            "page": page,
            "per_page": per_page,
            "total": total,
            "items": [project_to_dict(p) for p in items],
        })


# ============= Sharing Operations =============
@projects_bp.post("/<project_id>/share")
@jwt_required()
@limiter.limit("10/minute")
def share_project(project_id: str):
    """Generate a share token for a specific project."""
    user_id = get_jwt_identity()
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Firebase: obtener proyecto
        project_data = firebase_service.get_project(project_id)
        if not project_data:
            return jsonify({"error": "Project not found"}), 404
        
        # Verificar que el usuario es el dueño
        if project_data.get("user_id") != user_id:
            return jsonify({"error": "Not owner"}), 403
        
        # Generar token si no existe
        share_token = project_data.get("share_token")
        if not share_token:
            share_token = secrets.token_urlsafe(16)
            # Actualizar el proyecto con el nuevo token usando save_project con merge=True
            project_data["share_token"] = share_token
            firebase_service.save_project(project_id, project_data)
        
        return jsonify({
            "share_token": share_token,
            "share_url": f"/api/projects/shared/{share_token}",
            "share_page_url": f"/share/p/{share_token}"
        })
    else:
        # Local: usar SQL
        user_id = int(user_id)
        project_id = int(project_id)
        p = Project.query.get_or_404(project_id)
        if p.user_id != user_id:
            return jsonify({"error": "Not owner"}), 403
        if not p.share_token:
            p.share_token = secrets.token_urlsafe(16)
            db.session.commit()
            cache.clear()
        return jsonify({
            "share_token": p.share_token,
            "share_url": f"/api/projects/shared/{p.share_token}",
            "share_page_url": f"/share/p/{p.share_token}"
        })


@projects_bp.get("/shared/<token>")
@limiter.limit("60/minute")
def get_shared_project(token: str):
    """Get a project by its share token."""
    # If the client is a browser (requests HTML), redirect to public page
    accept = (request.headers.get("accept") or "").lower()
    wants_html = "text/html" in accept or request.args.get("view") == "1"
    if wants_html:
        return redirect(f"/share/p/{token}", code=302)
    p = Project.query.filter_by(share_token=token).first_or_404()
    return jsonify(project_to_dict(p))


@projects_bp.post("/portfolio/share")
@jwt_required()
@limiter.limit("10/minute")
def share_portfolio():
    """Generate a share token for user's entire portfolio."""
    user_id = get_jwt_identity()
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Firebase: obtener usuario
        user_data = firebase_service.get_user(user_id)
        if not user_data:
            return jsonify({"error": "User not found"}), 404
        
        # Generar token si no existe
        share_token = user_data.get("portfolio_share_token")
        if not share_token:
            share_token = secrets.token_urlsafe(16)
            # Actualizar el usuario con el nuevo token usando save_user con merge=True
            user_data["portfolio_share_token"] = share_token
            firebase_service.save_user(user_id, user_data)
        
        return jsonify({
            "share_token": share_token,
            "share_url": f"/api/projects/portfolio/{share_token}",
            "share_page_url": f"/share/pf/{share_token}"
        })
    else:
        # Local: usar SQL
        user_id = int(user_id)
        user = User.query.get_or_404(user_id)
        if not user.portfolio_share_token:
            user.portfolio_share_token = secrets.token_urlsafe(16)
            db.session.commit()
            cache.clear()
        return jsonify({
            "share_token": user.portfolio_share_token,
            "share_url": f"/api/projects/portfolio/{user.portfolio_share_token}",
            "share_page_url": f"/share/pf/{user.portfolio_share_token}"
        })


@projects_bp.get("/portfolio/<token>")
@limiter.limit("60/minute")
def get_shared_portfolio(token: str):
    """Get all projects for a user by their portfolio share token."""
    # If the client is a browser (requests HTML), redirect to public page
    accept = (request.headers.get("accept") or "").lower()
    wants_html = "text/html" in accept or request.args.get("view") == "1"
    if wants_html:
        return redirect(f"/share/pf/{token}", code=302)
    
    use_firebase = current_app.config.get("USE_FIREBASE", False)
    
    if use_firebase and firebase_service.is_enabled:
        # Firebase: buscar usuario por portfolio_share_token
        user = firebase_service.get_user_by_portfolio_token(token)
        if not user:
            return jsonify({"error": "Portfolio not found"}), 404
        
        user_id = user.get("id")
        # Obtener proyectos del usuario
        projects = firebase_service.get_user_projects(user_id)
        
        # Convertir a formato de respuesta
        result = []
        for p in projects:
            # Asegurar que images y links sean strings JSON válidos
            images = p.get("images")
            if images is None:
                images = "[]"
            elif not isinstance(images, str):
                images = json.dumps(images) if images else "[]"
            
            links = p.get("links")
            if links is None:
                links = "[]"
            elif not isinstance(links, str):
                links = json.dumps(links) if links else "[]"
            
            result.append({
                "id": p.get("id", ""),
                "title": p.get("title", ""),
                "description": p.get("description", ""),
                "technologies": p.get("technologies", ""),
                "category": p.get("category", "general"),
                "featured": p.get("featured", False),
                "images": images,
                "links": links,
                "share_token": p.get("share_token", ""),
                "created_at": str(p.get("created_at", "")),
            })
        
        return jsonify(result)
    else:
        # Local: usar SQL
        user = User.query.filter_by(portfolio_share_token=token).first_or_404()
        projects = Project.query.filter_by(user_id=user.id).order_by(
            Project.created_at.desc()
        ).all()
        return jsonify([project_to_dict(p) for p in projects])
