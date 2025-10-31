#!/usr/bin/env python3
"""Script para ver los usuarios almacenados en la base de datos SQLite."""
import sqlite3
import os
from pathlib import Path
from datetime import datetime


def view_users():
    """Muestra todos los usuarios en la base de datos SQLite."""
    # Ubicación del archivo de base de datos
    db_path = Path(__file__).parent / "app.db"
    
    if not db_path.exists():
        print(f"❌ No se encontró la base de datos en: {db_path}")
        print("   La base de datos se creará automáticamente cuando registres el primer usuario.")
        return
    
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row  # Para acceder por nombre de columna
    cursor = conn.cursor()
    
    try:
        # Verificar si existe la tabla users
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='users'
        """)
        if not cursor.fetchone():
            print("❌ La tabla 'users' no existe aún.")
            print("   La tabla se creará cuando registres el primer usuario.")
            return
        
        # Obtener usuarios
        cursor.execute("""
            SELECT id, email, name, bio, title, location, 
                   avatar_url, created_at, updated_at,
                   portfolio_share_token
            FROM users
            ORDER BY created_at DESC
        """)
        users = cursor.fetchall()
        
        print("=" * 70)
        print("👥 USUARIOS EN LA BASE DE DATOS")
        print("=" * 70)
        
        if not users:
            print("\n📭 No hay usuarios registrados aún.")
            print("   Los usuarios aparecerán aquí cuando se registren.\n")
        else:
            print(f"\n📊 Total de usuarios: {len(users)}\n")
            
            for user in users:
                print(f"🆔 ID: {user['id']}")
                print(f"   📧 Email: {user['email']}")
                print(f"   👤 Nombre: {user['name'] or '(sin nombre)'}")
                if user['title']:
                    print(f"   💼 Título: {user['title']}")
                if user['location']:
                    print(f"   📍 Ubicación: {user['location']}")
                print(f"   📅 Creado: {user['created_at']}")
                print(f"   🔄 Actualizado: {user['updated_at']}")
                
                # Contar proyectos
                cursor.execute("SELECT COUNT(*) FROM projects WHERE user_id = ?", (user['id'],))
                project_count = cursor.fetchone()[0]
                print(f"   📁 Proyectos: {project_count}")
                
                if user['portfolio_share_token']:
                    print(f"   🔗 Token compartir: {user['portfolio_share_token']}")
                
                print()
        
        print("=" * 70)
        print(f"\n📍 Ubicación de la base de datos:")
        print(f"   {db_path.absolute()}")
        
        # Verificar configuración de Firebase
        env_file = Path(__file__).parent.parent / ".env"
        use_firebase = False
        if env_file.exists():
            with open(env_file) as f:
                for line in f:
                    if line.startswith("USE_FIREBASE="):
                        use_firebase = "true" in line.lower()
                        break
        
        print(f"\n🔥 Firebase habilitado: {'SÍ ✅' if use_firebase else 'NO ❌ (modo desarrollo)'}")
        
        if not use_firebase:
            print("\n💡 EXPLICACIÓN:")
            print("   Los usuarios se están guardando en SQLite local (desarrollo).")
            print("   Para guardarlos en Firebase (producción), configura:")
            print("   1. USE_FIREBASE=true en tu archivo .env")
            print("   2. GOOGLE_APPLICATION_CREDENTIALS con las credenciales de Firebase")
            print("   3. Reinicia el servidor backend")
        
        print()
        
    except sqlite3.Error as e:
        print(f"❌ Error al leer la base de datos: {e}")
    finally:
        conn.close()


if __name__ == "__main__":
    view_users()

