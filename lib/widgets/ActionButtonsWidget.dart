import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onSettleUp;
  const ActionButtonsWidget({Key? key, required this.onSettleUp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double iconSize = MediaQuery.of(context).size.width * 0.1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            context,
            icon: Icons.payment,
            label: 'Settle up',
            onPressed: onSettleUp,
            iconSize: iconSize,
          ),
          _buildActionButton(
            context,
            icon: Icons.group_add,
            label: 'Add custom split',
            onPressed: () {},
            iconSize: iconSize,
          ),
          _buildActionButton(
            context,
            icon: Icons.receipt_long,
            label: 'Add expense',
            onPressed: () {},
            iconSize: iconSize,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onPressed, required double iconSize}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Ink(
          decoration: const ShapeDecoration(
            color: Colors.blue,
            shape: CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
            iconSize: iconSize,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontFamily: 'interSemiBold', fontSize: iconSize * 0.25),
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}