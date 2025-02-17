import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:splitter/splitPage.dart';
import 'package:splitter/widgets/AmountSliderWidget.dart';
import 'package:splitter/widgets/ExpenseChipWidget.dart';
import 'package:splitter/widgets/QuoteWidget.dart';
import 'package:splitter/widgets/SlideToProceedButton.dart';
import 'friendsPage.dart';
import 'dart:math';

class GroupCreationPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedContacts;

  GroupCreationPage({this.selectedContacts = const []});

  @override
  _GroupCreationPageState createState() => _GroupCreationPageState();
}

class _GroupCreationPageState extends State<GroupCreationPage>
    with SingleTickerProviderStateMixin {
  double _sliderValue = 0.0;
  final Set<String> _selectedExpenses = {};
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  String? _errorMessage;

  late AnimationController _animationController;

  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);

  final List<Map<String, String>> _quotes = [];

  @override
  void initState() {
    super.initState();
    _amountController.text = _sliderValue.toStringAsFixed(2);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _loadQuoteFromFirestore();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _groupNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Updates the amount when slider value changes
  void _updateAmount(double value) {
    setState(() {
      _sliderValue = value;
      _amountController.text = value.toStringAsFixed(2);
      _errorMessage = null;
    });
  }
  Future<bool> _checkContactsExist() async {
    bool allContactsExist = true;
    for (var contact in widget.selectedContacts) {
      bool exists = await _contactExistsInFirestore(contact['phone']);
      if (!exists) {
        allContactsExist = false;
        break;
      }
    }
    return allContactsExist;  // Return the result
  }

  Future<void> _loadQuoteFromFirestore() async {
    try {
      // Fetch the quotes collection from Firestore
      var quoteCollection = FirebaseFirestore.instance.collection('quotes');

      // Get all documents from the collection
      var querySnapshot = await quoteCollection.get();

      // Randomly pick a quote
      if (querySnapshot.docs.isNotEmpty) {
        var randomDoc =
        querySnapshot.docs[Random().nextInt(querySnapshot.docs.length)];
        var quoteData = randomDoc.data();

        setState(() {
          _quotes.clear(); // clear the existing quotes if any
          _quotes.add({
            'quote': quoteData['Quote'] ?? 'No quote available',
            'author': quoteData['Author'] ?? 'Unknown',
          });
        });
      } else {
        setState(() {
          _quotes.clear();
          _quotes.add({
            'quote': 'No quotes available at the moment.',
            'author': 'Unknown',
          });
        });
      }
    } catch (e) {
      setState(() {
        _quotes.clear();
        _quotes.add({
          'quote': 'Error fetching quotes.',
          'author': 'Unknown',
        });
      });
    }
  }

  // Updated _canProceed() method that now also requires a non-empty group name.
  bool _canProceed() {
    return _groupNameController.text.trim().isNotEmpty &&
        widget.selectedContacts.isNotEmpty &&
        _selectedExpenses.isNotEmpty &&
        _sliderValue > 1;
  }

  Future<bool> _contactExistsInFirestore(String contactPhone) async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(contactPhone)  // Assuming 'phone' is the document ID
          .get();
      return userDoc.exists;
    } catch (e) {
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C6FB), Color(0xFFFFF176)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.only(bottom: 100),
                child: Padding(
                  padding: defaultPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Back button and "Add people" title.
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add people',
                            style: TextStyle(
                                fontFamily: 'InterSemiBold', fontSize: 18),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Contacts Row: Add button, self avatar, and selected contacts.
                      // Contacts Row: Add button, self avatar, and selected contacts.
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              var newSelectedContacts = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendsPage(
                                      selectedContacts:
                                      widget.selectedContacts),
                                ),
                              );

                              if (newSelectedContacts != null) {
                                setState(() {
                                  widget.selectedContacts
                                      .addAll(newSelectedContacts);
                                });
                              } else if (widget.selectedContacts.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "You haven't selected any contacts yet.")),
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.add, color: Colors.black),
                            ),
                          ),
                          SizedBox(width: 16),
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.black,
                            child: Text('You',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'InterRegular')),
                          ),
                          SizedBox(width: 16),
                          // Scrollable list for selected contacts with overlapping effect.
                          Expanded(
                            child: SingleChildScrollView(
                              physics: BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                  widget.selectedContacts.length,
                                      (index) {
                                    var contact = widget.selectedContacts[index];
                                    return Transform.translate(
                                      offset: Offset(-20.0 * index, 0),
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundImage: contact['avatar'].isEmpty ? null : MemoryImage(contact['avatar']),
                                          backgroundColor: Colors.black,
                                          child: contact['avatar'].isEmpty
                                              ? Text(
                                            contact['name'][0],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'InterRegular',
                                            ),
                                          )
                                              : null,
                                        ),
                                      ),
                                    );

                                      },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Group Name Section: Header and TextField.
                      Text(
                        'Paid to',
                        style: TextStyle(
                            fontFamily: 'InterSemiBold', fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _groupNameController, // Ensure this controller is defined and disposed appropriately.
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black,
                          fontStyle: FontStyle.normal,
                          fontFamily: 'InterSemiBold', // Change to your desired font family.
                        ),

                        decoration: InputDecoration(
                          hintText: 'Paid to',
                          hintStyle: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey,
                            fontFamily: 'InterSemiBold', // Ensure this matches your input text font if desired.
                          ),
                          contentPadding: EdgeInsets.only(left: 20.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.black, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.black, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.black, width: 1.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),


                      SizedBox(height: 18),
                      // Expense Purpose Section.
                      Text('Expense purpose',
                          style: TextStyle(
                              fontFamily: 'InterSemiBold', fontSize: 18)),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          ExpenseChip(
                              label: 'Snacks',
                              icon: Icons.fastfood,
                              isSelected:
                              _selectedExpenses.contains('snacks'),
                              onSelected: (selected) {
                                setState(() => selected
                                    ? _selectedExpenses.add('snacks')
                                    : _selectedExpenses.remove('snacks'));
                              }),
                          // You can add more ExpenseChip widgets here for other purposes.
                          ExpenseChip(
                              label: 'Snacks',
                              icon: Icons.fastfood,
                              isSelected:
                              _selectedExpenses.contains('snacks'),
                              onSelected: (selected) {
                                setState(() => selected
                                    ? _selectedExpenses.add('snacks')
                                    : _selectedExpenses.remove('snacks'));
                              }),
                        ],
                      ),
                      SizedBox(height: 24),
                      // Expense Amount Section.
                      Text('Expense amount',
                          style: TextStyle(
                              fontFamily: 'InterSemiBold', fontSize: 18)),
                      SizedBox(height: 10),
                      AmountSlider(
                        sliderValue: _sliderValue,
                        onChanged: _updateAmount,
                        controller: _amountController,
                        errorMessage: _errorMessage,
                      ),
                      if (_quotes.isNotEmpty)
                        QuoteWidget(quoteData: _quotes.first),
                    ],
                  ),
                ),
              ),
              // Slide-to-Proceed Button.
              Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () async {
                    if (!_canProceed()) {
                      // If the button is disabled, show a SnackBar.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Please select all required fields before proceeding."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: SlideToProceedButton(
                    onSlide: _canProceed()
                        ? () async {
                      bool allContactsExist = await _checkContactsExist();
                      // Immediately navigate to the next screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SplitTransactionScreen(
                              expenseItems: _selectedExpenses.toList(),
                              amount: _sliderValue,
                              allContactsExist: allContactsExist,  // Wait for the result
                          contacts: widget.selectedContacts
                              .map<Map<String, dynamic>>((contact) {
                            return {
                              'name': contact['name'].toString(),
                              'number': (contact['phone'] ?? 'N/A').toString(),
                              'avatar': contact['avatar'],
                            };
                          }).toList(),
                          groupName: _groupNameController.text.trim(),
                        ),
                      ),
                      );
                    }
                        : () {},
                    isEnabled: _canProceed(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
