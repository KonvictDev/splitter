// Overlapping avatars widget.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OverlappingAvatarsWidget extends StatelessWidget {
  final String? userAvatarUrl;
  final String? ownerAvatarUrl;
  final double screenWidth;
  const OverlappingAvatarsWidget({Key? key, this.userAvatarUrl, this.ownerAvatarUrl, required this.screenWidth}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = (screenWidth * 0.15).clamp(30.0, 60.0) as double;
    final ImageProvider userImage = (userAvatarUrl != null && userAvatarUrl!.isNotEmpty)
        ? NetworkImage(userAvatarUrl!)
        : const AssetImage('assets/logo/img.png');
    final ImageProvider ownerImage = (ownerAvatarUrl != null && ownerAvatarUrl!.isNotEmpty)
        ? NetworkImage(ownerAvatarUrl!)
        : const AssetImage('assets/logo/img.png');
    return Center(
      child: SizedBox(
        width: avatarRadius * 3,
        height: avatarRadius * 1.75,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              child: CircleAvatar(radius: avatarRadius, backgroundImage: userImage),
            ),
            Positioned(
              left: avatarRadius * 0.8,
              child: CircleAvatar(radius: avatarRadius, backgroundImage: ownerImage),
            ),
          ],
        ),
      ),
    );
  }
}