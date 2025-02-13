import 'package:flutter/material.dart';

class ExpenseChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Function(bool) onSelected;

  ExpenseChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontFamily: 'InterRegular')),
      avatar: Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.black),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Colors.black,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
