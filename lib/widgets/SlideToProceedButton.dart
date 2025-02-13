import 'package:flutter/material.dart';
import 'package:slider_button/slider_button.dart';

class SlideToProceedButton extends StatelessWidget {
  final VoidCallback onSlide;
  final bool isEnabled; // Add the isEnabled property

  const SlideToProceedButton({
    Key? key,
    required this.onSlide,
    required this.isEnabled, // Make isEnabled required
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SliderButton(
        action: isEnabled
            ? () async {
          onSlide(); // Call the onSlide function if enabled
          return Future.value(true); // Indicate success with a non-nullable Future<bool?>
        }
            : () async {
          return Future.value(false); // Return false if not enabled (prevent the slide)
        },
        label: Padding(
          padding: EdgeInsets.only(left: 0.0), // Adds space to the left of the text
          child: Text(
            'Slide to proceed',
            style: TextStyle(
              fontFamily: 'InterBold',
              color: isEnabled ? Colors.black : Colors.black, // Change text color when disabled
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        icon: Icon(
          Icons.arrow_forward,
          color: isEnabled ? Colors.black : Colors.black, // Change icon color when disabled
        ),
        radius: 20,
        backgroundColor: isEnabled ? Colors.black : Colors.black, // Background color when disabled
        buttonColor: Colors.white,
        highlightedColor: Colors.grey.shade300,
        baseColor: Colors.grey.shade300,
      ),
    );
  }
}
