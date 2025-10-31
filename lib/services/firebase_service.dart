import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../core/environment.dart';

/// Servicio centralizado para interactuar con Firebase
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Instancias de Firebase
  // NOTA: El cliente web no soporta bien bases de datos no-default
  // Por ahora usamos la instancia por defecto
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  FirebaseStorage get storage => FirebaseStorage.instance;
  firebase_auth.FirebaseAuth get auth => firebase_auth.FirebaseAuth.instance;

  /// Verifica si Firebase está habilitado
  bool get isEnabled => Environment.useFirebase;

  // ===== FIRESTORE =====

  /// Guarda o actualiza un usuario en Firestore
  Future<void> saveUser({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    if (!isEnabled) return;
    await firestore.collection('users').doc(userId).set(userData, SetOptions(merge: true));
  }

  /// Obtiene un usuario de Firestore
  Future<Map<String, dynamic>?> getUser(String userId) async {
    if (!isEnabled) return null;
    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Actualiza un campo específico del usuario
  Future<void> updateUserField(String userId, String field, dynamic value) async {
    if (!isEnabled) return;
    await firestore.collection('users').doc(userId).update({field: value});
  }

  /// Guarda o actualiza un proyecto en Firestore
  Future<void> saveProject({
    required String projectId,
    required Map<String, dynamic> projectData,
  }) async {
    if (!isEnabled) return;
    await firestore.collection('projects').doc(projectId).set(projectData, SetOptions(merge: true));
  }

  /// Obtiene proyectos de un usuario
  Future<List<Map<String, dynamic>>> getUserProjects(String userId) async {
    if (!isEnabled) return [];
    final snapshot = await firestore
        .collection('projects')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  /// Obtiene un proyecto por ID
  Future<Map<String, dynamic>?> getProject(String projectId) async {
    if (!isEnabled) return null;
    final doc = await firestore.collection('projects').doc(projectId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Elimina un proyecto
  Future<void> deleteProject(String projectId) async {
    if (!isEnabled) return;
    await firestore.collection('projects').doc(projectId).delete();
  }

  /// Obtiene proyectos por token de compartir
  Future<Map<String, dynamic>?> getProjectByShareToken(String token) async {
    if (!isEnabled) return null;
    final snapshot = await firestore
        .collection('projects')
        .where('share_token', isEqualTo: token)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return {'id': doc.id, ...doc.data()};
  }

  /// Obtiene un usuario por token de compartir portafolio
  Future<Map<String, dynamic>?> getUserByPortfolioToken(String token) async {
    if (!isEnabled) return null;
    final snapshot = await firestore
        .collection('users')
        .where('portfolio_share_token', isEqualTo: token)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return {'id': doc.id, ...doc.data()};
  }

  // ===== STORAGE =====

  /// Sube una imagen a Firebase Storage
  /// Retorna la URL pública de la imagen
  Future<String> uploadImage({
    required List<int> imageData,
    required String fileName,
    required String folder, // ej: 'avatars', 'projects'
  }) async {
    if (!isEnabled) {
      throw Exception('Firebase Storage no está habilitado en este entorno');
    }

    final ref = storage.ref().child('$folder/$fileName');
    final metadata = SettableMetadata(
      contentType: 'image/${_getImageType(fileName)}',
      cacheControl: 'public, max-age=31536000',
    );
    
    await ref.putData(
      Uint8List.fromList(imageData),
      metadata,
    );
    
    return await ref.getDownloadURL();
  }

  /// Elimina una imagen de Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    if (!isEnabled) return;
    
    try {
      final ref = storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Si la URL no es de Firebase Storage, ignorar
      print('Error al eliminar imagen de Storage: $e');
    }
  }

  /// Determina el tipo de imagen basado en la extensión
  String _getImageType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'png';
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
    }
  }

  /// Obtiene la referencia de Storage desde una URL
  Reference? getStorageRefFromUrl(String url) {
    if (!isEnabled) return null;
    try {
      return storage.refFromURL(url);
    } catch (e) {
      return null;
    }
  }
}

