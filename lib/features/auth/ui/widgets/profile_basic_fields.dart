import 'package:flutter/material.dart';

class ProfileBasicFields extends StatelessWidget {
  const ProfileBasicFields({
    super.key,
    required this.nameCtrl,
    required this.titleCtrl,
    required this.locationCtrl,
    required this.bioCtrl,
    required this.phoneCtrl,
  });

  final TextEditingController nameCtrl;
  final TextEditingController titleCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController phoneCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Título profesional',
            hintText: 'Ej: Full Stack Developer, UX Designer',
            prefixIcon: Icon(Icons.work_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: locationCtrl,
          decoration: const InputDecoration(
            labelText: 'Ubicación',
            hintText: 'Ej: Ciudad de México, México',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: bioCtrl,
          decoration: const InputDecoration(
            labelText: 'Biografía',
            hintText: 'Cuéntanos sobre ti...',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneCtrl,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}

