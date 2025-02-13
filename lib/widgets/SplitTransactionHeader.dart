import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SplitTransactionHeader extends StatelessWidget {
  final String groupName;
  final double amount;
  final String formattedDate;

  const SplitTransactionHeader({
    Key? key,
    required this.groupName,
    required this.amount,
    required this.formattedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF00C6FB), Color(0xFFFFF176)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Split Transaction",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'interSemiBold',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.black),
                    onPressed: () {
                      // Optionally add person functionality.
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid to $groupName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'interSemiBold',
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        "₹ ${amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamily: 'interExtraBold',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 4),
                          Text(
                            "Equal Split",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'interRegular',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'interRegular',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_circle_left, size: 16, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/logo/movies.png",
                        height: 90,
                        width: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Positioned(
          right: 30,
          bottom: -20,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.receipt,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      ],
    );
  }
}