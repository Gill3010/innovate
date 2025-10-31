import 'package:flutter/foundation.dart' show kDebugMode;

/// Servicio para detectar el entorno actual (desarrollo o producción)
class Environment {
  /// Determina si estamos en modo desarrollo
  static bool get isDevelopment {
    // En Flutter, kDebugMode es true en modo desarrollo y false en release
    // Pero también podemos usar variables de entorno
    const envOverride = String.fromEnvironment('ENV', defaultValue: '');
    if (envOverride.isNotEmpty) {
      return envOverride == 'development' || envOverride == 'dev';
    }
    return kDebugMode;
  }

  /// Determina si estamos en modo producción
  static bool get isProduction {
    return !isDevelopment;
  }

  /// Obtiene el nombre del entorno
  static String get current {
    return isDevelopment ? 'development' : 'production';
  }

  /// Determina si debemos usar Firebase (producción)
  static bool get useFirebase {
    // En producción siempre usamos Firebase
    // En desarrollo podemos usar local o Firebase según configuración
    const useFirebaseInDev = String.fromEnvironment('USE_FIREBASE_IN_DEV', defaultValue: 'false');
    if (isDevelopment) {
      return useFirebaseInDev == 'true';
    }
    return true; // En producción siempre usar Firebase
  }

  /// Determina si debemos usar el backend local
  static bool get useLocalBackend {
    return isDevelopment && !useFirebase;
  }
}

