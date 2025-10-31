import 'package:flutter/material.dart';

class ProfileAvatarWidget extends StatelessWidget {
  const ProfileAvatarWidget({
    super.key,
    required this.avatarUrl,
    required this.tempAvatarUrl,
    required this.onPickAvatar,
  });

  final String avatarUrl;
  final String? tempAvatarUrl;
  final VoidCallback onPickAvatar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: (tempAvatarUrl != null || avatarUrl.isNotEmpty)
                ? NetworkImage(tempAvatarUrl ?? avatarUrl)
                : null,
            child: (tempAvatarUrl == null && avatarUrl.isEmpty)
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 20),
                onPressed: onPickAvatar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

