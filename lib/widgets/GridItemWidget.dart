// Grid item widget for each split
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GridItemWidget extends StatelessWidget {
  final String splitAmount;
  final String? avatarUrl;
  const GridItemWidget({Key? key, required this.splitAmount, this.avatarUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double avatarRadius =
    (MediaQuery.of(context).size.width * 0.05).clamp(20.0, 30.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
              ? NetworkImage(avatarUrl!)
              : null,
          child: (avatarUrl == null || avatarUrl!.isEmpty)
              ? const Icon(Icons.person, size: 20)
              : null,
        ),
        Positioned(
          top: -3,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '₹$splitAmount',
              style: const TextStyle(
                fontFamily: 'interSemiBold',
                fontWeight: FontWeight.w400,
                fontSize: 8,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

