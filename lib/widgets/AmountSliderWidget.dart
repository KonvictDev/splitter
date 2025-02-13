import 'package:flutter/material.dart';

class AmountSlider extends StatelessWidget {
  final double sliderValue;
  final Function(double) onChanged;
  final TextEditingController controller;
  final String? errorMessage;
  final double maxAmount;

  AmountSlider({
    required this.sliderValue,
    required this.onChanged,
    required this.controller,
    required this.errorMessage,
    this.maxAmount = 20000.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE1F5FE), Color(0xFFFFF9C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount:',
                style: TextStyle(fontFamily: 'InterSemiBold', fontSize: 18),
              ),
              SizedBox(
                width: 100,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IntrinsicWidth(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(fontFamily: 'InterSemiBold', fontSize: 18),
                            ),
                            Flexible(
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  errorText: errorMessage,
                                ),
                                style: TextStyle(
                                  fontFamily: 'InterRegular',
                                  fontSize: 18,
                                ),
                                onChanged: (value) {
                                  double? enteredValue = double.tryParse(value);
                                  if (enteredValue != null && enteredValue >= 0 && enteredValue <= maxAmount) {
                                    onChanged(enteredValue);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          SizedBox(height: 2),
          Slider(
            value: sliderValue,
            min: 0,
            max: maxAmount,
            divisions: 2000,
            onChanged: onChanged,
            activeColor: Color(0xFF00728F),
            inactiveColor: Colors.grey[300],
            thumbColor: Colors.black,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹0', style: TextStyle(fontFamily: 'InterRegular', fontSize: 14)),
              Text('₹20,000', style: TextStyle(fontFamily: 'InterRegular', fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
