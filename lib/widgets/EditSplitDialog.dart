import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Constants/AppConstants.dart';

class EditSplitDialog extends StatefulWidget {
  final double totalAmount;
  final double initialUserShare;
  final List<double> initialContactShares;
  final List<Map<String, dynamic>> contacts;

  const EditSplitDialog({
    Key? key,
    required this.totalAmount,
    required this.initialUserShare,
    required this.initialContactShares,
    required this.contacts,
  }) : super(key: key);

  @override
  _EditSplitDialogState createState() => _EditSplitDialogState();
}

class _EditSplitDialogState extends State<EditSplitDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userController;
  late List<TextEditingController> _contactControllers;
  String _formError = "";

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(
      text: widget.initialUserShare.toStringAsFixed(2),
    );
    _contactControllers = widget.initialContactShares
        .map((share) => TextEditingController(text: share.toStringAsFixed(2)))
        .toList();
  }

  @override
  void dispose() {
    _userController.dispose();
    for (var controller in _contactControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Build a form field for each participant.
  Widget _buildInputField(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: AppConstants.textFieldWidth,
          child: TextFormField(
            controller: controller,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 15),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(AppConstants.borderRadius),
                borderSide:
                BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius + 2),
                borderSide:
                const BorderSide(color: AppConstants.primaryColor),
              ),
              hintText: "Amount",
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Enter amount";
              }
              if (double.tryParse(value) == null) {
                return "Invalid number";
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
  // Validate the total sum.
  bool _validateTotalSum() {
    final double? userAmount = double.tryParse(_userController.text);
    if (userAmount == null) return false;
    double total = userAmount;
    for (var controller in _contactControllers) {
      final amt = double.tryParse(controller.text);
      if (amt == null) return false;
      total += amt;
    }
    return (total - widget.totalAmount).abs() <= 0.01;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(AppConstants.dialogBorderRadius),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppConstants.dialogWidth,
          maxWidth: AppConstants.dialogWidth,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius:
            BorderRadius.circular(AppConstants.dialogBorderRadius),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    width: double.infinity,
                    child: const Center(
                      child: Text(
                        "Edit Split Amounts",
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Input row for the current user.
                  _buildInputField("You", _userController),
                  const SizedBox(height: 10),
                  // Input rows for each contact.
                  for (int i = 0; i < widget.contacts.length; i++) ...[
                    const SizedBox(height: 10),
                    _buildInputField(
                      widget.contacts[i]['name'] ?? "Contact ${i + 1}",
                      _contactControllers[i],
                    ),
                  ],
                  if (_formError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        _formError,
                        style: const TextStyle(
                          color: AppConstants.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 15),
                  // Action buttons.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (!_validateTotalSum()) {
                              setState(() {
                                _formError =
                                "The total does not match the expense amount (${widget.totalAmount.toStringAsFixed(2)})";
                              });
                              return;
                            }
                            // If valid, return the new values.
                            final double userAmount =
                            double.parse(_userController.text);
                            final List<double> newContactAmounts =
                            _contactControllers
                                .map((controller) =>
                                double.parse(controller.text))
                                .toList();
                            Navigator.of(context).pop({
                              'userShare': userAmount,
                              'contactShares': newContactAmounts,
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                        ),
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

