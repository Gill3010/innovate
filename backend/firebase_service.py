"""Servicio de Firebase para el backend."""
import os
from typing import Optional, Dict, Any, List
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, storage
from google.cloud import firestore
from google.cloud import storage as gcs_storage


class FirebaseService:
    """Servicio singleton para interactuar con Firebase."""
    
    _instance = None
    _initialized = False
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        if not self._initialized:
            self._db: Optional[firestore.Client] = None
            self._storage_bucket: Optional[Any] = None
            self._initialized = True
    
    def initialize(self, use_firebase: bool = False):
        """Inicializa Firebase Admin SDK si está habilitado."""
        if not use_firebase:
            return
        
        # Obtener el nombre de la base de datos desde variable de entorno
        db_name = os.getenv("FIRESTORE_DATABASE", "innovate")
        
        if firebase_admin._apps:
            # Ya está inicializado
            # Usar la base de datos especificada
            self._db = firestore.Client(database=db_name)
            self._storage_bucket = storage.bucket()
            return
        
        # Obtener credenciales desde variable de entorno o archivo
        cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        else:
            # En producción (Cloud Run, etc.) puede usar Application Default Credentials
            try:
                firebase_admin.initialize_app()
            except Exception as e:
                print(f"Warning: Could not initialize Firebase: {e}")
                return
        
        # Obtener cliente de Firestore con la base de datos especificada
        # Usar la base de datos desde variable de entorno (por defecto 'innovate')
        self._db = firestore.Client(database=db_name)
        print(f"Firebase conectado a la base de datos: {db_name}")
        
        bucket_name = os.getenv("FIREBASE_STORAGE_BUCKET")
        if bucket_name:
            self._storage_bucket = storage.bucket(bucket_name)
        else:
            self._storage_bucket = storage.bucket()
    
    @property
    def is_enabled(self) -> bool:
        """Verifica si Firebase está habilitado y inicializado."""
        return self._db is not None
    
    # ===== FIRESTORE =====
    
    def save_user(self, user_id: str, user_data: Dict[str, Any]) -> None:
        """Guarda o actualiza un usuario en Firestore."""
        if not self.is_enabled:
            return
        
        user_data['updated_at'] = datetime.utcnow()
        if 'created_at' not in user_data:
            user_data['created_at'] = datetime.utcnow()
        
        self._db.collection('users').document(str(user_id)).set(
            user_data, 
            merge=True
        )
    
    def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Obtiene un usuario de Firestore."""
        if not self.is_enabled:
            return None
        
        doc = self._db.collection('users').document(str(user_id)).get()
        if not doc.exists:
            return None
        
        data = doc.to_dict()
        data['id'] = doc.id
        return data
    
    def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Obtiene un usuario por email."""
        if not self.is_enabled:
            return None
        
        query = self._db.collection('users').where('email', '==', email.lower()).limit(1)
        docs = query.stream()
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            return data
        return None
    
    def get_user_by_portfolio_token(self, token: str) -> Optional[Dict[str, Any]]:
        """Obtiene un usuario por token de compartir portafolio."""
        if not self.is_enabled:
            return None
        
        query = self._db.collection('users').where('portfolio_share_token', '==', token).limit(1)
        docs = query.stream()
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            return data
        return None
    
    def save_project(self, project_id: str, project_data: Dict[str, Any]) -> None:
        """Guarda o actualiza un proyecto en Firestore."""
        if not self.is_enabled:
            return
        
        project_data['updated_at'] = datetime.utcnow()
        if 'created_at' not in project_data:
            project_data['created_at'] = datetime.utcnow()
        
        self._db.collection('projects').document(str(project_id)).set(
            project_data,
            merge=True
        )
    
    def get_project(self, project_id: str) -> Optional[Dict[str, Any]]:
        """Obtiene un proyecto por ID."""
        if not self.is_enabled:
            return None
        
        doc = self._db.collection('projects').document(str(project_id)).get()
        if not doc.exists:
            return None
        
        data = doc.to_dict()
        data['id'] = doc.id
        return data
    
    def get_user_projects(self, user_id: str) -> List[Dict[str, Any]]:
        """Obtiene todos los proyectos de un usuario."""
        if not self.is_enabled or not user_id:
            return []
        
        # user_id puede ser string (desde JWT) o necesitar conversión
        # Sin order_by en la query para evitar requerir índice compuesto
        query = self._db.collection('projects').where('user_id', '==', str(user_id))
        docs = query.stream()
        projects = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            projects.append(data)
        
        # Ordenar en memoria por created_at (más reciente primero)
        projects.sort(key=lambda p: p.get('created_at', datetime.min), reverse=True)
        return projects
    
    def get_project_by_share_token(self, token: str) -> Optional[Dict[str, Any]]:
        """Obtiene un proyecto por token de compartir."""
        if not self.is_enabled:
            return None
        
        query = self._db.collection('projects').where('share_token', '==', token).limit(1)
        docs = query.stream()
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            return data
        return None
    
    def get_all_projects(self) -> List[Dict[str, Any]]:
        """Obtiene todos los proyectos (para explorar/public)."""
        if not self.is_enabled:
            return []
        
        projects = []
        for doc in self._db.collection('projects').stream():
            data = doc.to_dict()
            data['id'] = doc.id
            projects.append(data)
        return projects
    
    def delete_project(self, project_id: str) -> None:
        """Elimina un proyecto."""
        if not self.is_enabled:
            return
        
        self._db.collection('projects').document(str(project_id)).delete()
    
    # ===== STORAGE =====
    
    def upload_image(
        self, 
        file_data: bytes, 
        file_name: str, 
        folder: str = "uploads",
        content_type: str = "image/jpeg"
    ) -> str:
        """Sube una imagen a Firebase Storage y retorna la URL pública."""
        if not self.is_enabled or not self._storage_bucket:
            raise Exception("Firebase Storage no está habilitado")
        
        blob_name = f"{folder}/{file_name}"
        blob = self._storage_bucket.blob(blob_name)
        
        blob.upload_from_string(
            file_data,
            content_type=content_type
        )
        
        # Hacer el blob público (o configurar reglas de acceso apropiadas)
        try:
            blob.make_public()
        except Exception as e:
            print(f"Warning: No se pudo hacer público el blob (puede ya ser público): {e}")
        
        # Obtener la URL pública
        public_url = blob.public_url
        print(f"Imagen subida exitosamente: {public_url}")
        return public_url
    
    def delete_image(self, image_url: str) -> None:
        """Elimina una imagen de Firebase Storage."""
        if not self.is_enabled or not self._storage_bucket:
            return
        
        try:
            # Extraer el nombre del blob de la URL
            # Formato: https://firebasestorage.googleapis.com/v0/b/bucket/o/path%2Ffile.jpg
            if 'firebasestorage.googleapis.com' in image_url:
                # Parsear la URL de Firebase Storage
                parts = image_url.split('/o/')
                if len(parts) == 2:
                    blob_name = parts[1].split('?')[0]  # Remover query params
                    from urllib.parse import unquote
                    blob_name = unquote(blob_name)
                    blob = self._storage_bucket.blob(blob_name)
                    blob.delete()
        except Exception as e:
            print(f"Error al eliminar imagen de Storage: {e}")


# Instancia global del servicio
firebase_service = FirebaseService()

