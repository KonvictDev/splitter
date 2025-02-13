import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ContactRow extends StatelessWidget {
  final Map<String, dynamic> contact;
  final double share;
  final double progress;
  final Color progressColor;

  const ContactRow({
    Key? key,
    required this.contact,
    required this.share,
    required this.progress,
    required this.progressColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dynamic avatar = contact['avatar'];
    bool hasAvatar = avatar != null &&
        ((avatar is String && avatar.isNotEmpty) || (avatar is! String));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: Row(
        children: [
          // Display avatar or first letter if not available.
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            backgroundImage: hasAvatar ? MemoryImage(avatar) : null,
            child: !hasAvatar
                ? Text(
              contact['name'].toString().substring(0, 1),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'interSemiBold',
                color: Colors.black,
              ),
            )
                : null,
          ),
          const SizedBox(width: 10),
          // Display contact name, progress bar, and percentage.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['name'].toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'interSemiBold',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 190,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Display the percentage.
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'interRegular',
                  ),
                ),
              ],
            ),
          ),
          // Display the share amount.
          Text(
            "₹ ${share.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'interSemiBold',
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}