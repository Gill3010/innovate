import 'package:flutter/material.dart';

class ProfileSocialFields extends StatelessWidget {
  const ProfileSocialFields({
    super.key,
    required this.linkedinCtrl,
    required this.githubCtrl,
    required this.websiteCtrl,
  });

  final TextEditingController linkedinCtrl;
  final TextEditingController githubCtrl;
  final TextEditingController websiteCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Enlaces profesionales',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: linkedinCtrl,
          decoration: const InputDecoration(
            labelText: 'LinkedIn',
            hintText: 'https://linkedin.com/in/tu-perfil',
            prefixIcon: Icon(Icons.badge),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: githubCtrl,
          decoration: const InputDecoration(
            labelText: 'GitHub',
            hintText: 'https://github.com/tu-usuario',
            prefixIcon: Icon(Icons.code),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: websiteCtrl,
          decoration: const InputDecoration(
            labelText: 'Sitio web',
            hintText: 'https://tu-sitio.com',
            prefixIcon: Icon(Icons.language),
          ),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}

