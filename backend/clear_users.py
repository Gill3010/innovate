#!/usr/bin/env python3
"""Script para eliminar todos los usuarios y proyectos de la base de datos (útil para pruebas)"""
import sys
from backend.app import create_app
from backend.extensions import db
from backend.models import User, Project, FavoriteJob, JobClick

if __name__ == "__main__":
    app = create_app()
    with app.app_context():
        print("Eliminando datos de la base de datos...")
        
        # Eliminar proyectos primero (tienen foreign key a usuarios)
        project_count = Project.query.delete()
        print(f"  - Proyectos eliminados: {project_count}")
        
        # Eliminar favoritos
        fav_count = FavoriteJob.query.delete()
        print(f"  - Favoritos eliminados: {fav_count}")
        
        # Eliminar clicks de empleos
        click_count = JobClick.query.delete()
        print(f"  - Clicks de empleos eliminados: {click_count}")
        
        # Eliminar usuarios
        user_count = User.query.delete()
        print(f"  - Usuarios eliminados: {user_count}")
        
        db.session.commit()
        print(f"\n✅ Base de datos limpiada completamente")
        print("   Lista para crear nuevos usuarios y proyectos de prueba")

