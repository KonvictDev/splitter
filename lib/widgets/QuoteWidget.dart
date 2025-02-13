import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuoteWidget extends StatelessWidget {
  final Map<String, String> quoteData;

  QuoteWidget({required this.quoteData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Icon(
              Icons.format_quote,
              size: 75,
              color: Colors.black,
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                quoteData["quote"]!,
                style: TextStyle(
                  fontFamily: 'InterRegular',
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Center(
            child: Text(
              "- ${quoteData["author"]}",
              style: TextStyle(
                fontFamily: 'InterSemiBold',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
