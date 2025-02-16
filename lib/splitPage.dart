import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Constants/AppConstants.dart';
import 'bottom_navigation_main_screen.dart';
import 'helper/PushNotificationService.dart';
import 'helper/SplitCalculator.dart';
import 'widgets/ContactRow.dart';
import 'widgets/EditSplitDialog.dart';
import 'widgets/SplitTransactionHeader.dart';

class SplitTransactionScreen extends StatefulWidget {
  final List<String> expenseItems;
  final double amount;
  final List<Map<String, dynamic>> contacts;
  final String groupName;


  const SplitTransactionScreen({
    Key? key,
    required this.expenseItems,
    required this.amount,
    required this.contacts,
    required this.groupName,
  }) : super(key: key);

  @override
  State<SplitTransactionScreen> createState() => _SplitTransactionScreenState();
}

class _SplitTransactionScreenState extends State<SplitTransactionScreen> {
  final List<Color> progressColors = const [
    Color(0xFF719191),
    Color(0xFFBB9C79),
    Color(0xFFA0C4FF),
    Color(0xFF827CB0),
    Color(0xFFFFADAD),
    Color(0xFFC8B6FF),
    Color(0xFFFDFFB6),
    Color(0xFFCAFFBF),
    Color(0xFFFFC6FF),
    Color(0xFF9AE6B4),
  ];
  final pushService = PushNotificationService();
  late final SplitCalculator splitCalculator;
  late final String formattedDate;

  double? customUserShare;
  List<double>? customContactShares;
  bool _isLoading = false;

  /// Initializes the state, sets up UI parameters, and validates the transaction amount.
  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: AppConstants.primaryColor),
    );

    if (widget.amount <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid amount provided. Please enter an amount greater than zero.',
            ),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      });
    }

    splitCalculator = SplitCalculator(
      amount: widget.amount,
      contactCount: widget.contacts.length,
    );

    formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());

    customUserShare = splitCalculator.individualShare;
    customContactShares = List<double>.filled(
      widget.contacts.length,
      splitCalculator.individualShare,
    );
  }

  /// Computes and returns the total of the custom split amounts.
  double get totalCustomSplit {
    double total = customUserShare ?? 0.0;
    if (customContactShares != null) {
      total += customContactShares!.fold(0.0, (prev, element) => prev + element);
    }
    return total;
  }

  /// Uploads the provided avatar bytes to Firebase Storage and returns the download URL.
  Future<String> uploadAvatar(String fileName, Uint8List avatarBytes) async {
    try {
      Reference storageRef =
      FirebaseStorage.instance.ref().child('avatars').child('$fileName.jpg');
      UploadTask uploadTask = storageRef.putData(avatarBytes);

      await uploadTask;
      return await storageRef.getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  /// Executes a test upload to Firebase Storage to verify functionality.


  Future<void> updateFriends() async {
    // Get current user and their phone number
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.phoneNumber == null) return;

    final String userPhone = user.phoneNumber!;

    // Retrieve the user's document from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userPhone)
        .get();

    // Get the current friends map; if it doesn't exist, initialize it as an empty map.
    Map<String, dynamic> userData =
    userDoc.exists ? (userDoc.data() as Map<String, dynamic>) : {};
    Map<String, dynamic> friends = {};
    if (userData.containsKey('friends') && userData['friends'] is Map) {
      friends = Map<String, dynamic>.from(userData['friends']);
    }


    // Loop through each selected contact and update or add the entry.
    for (int i = 0; i < widget.contacts.length; i++) {
      final contact = widget.contacts[i];
      // Determine the split amount for this contact.
      final double splitAmount =
      (customContactShares != null && customContactShares!.length > i)
          ? customContactShares![i]
          : splitCalculator.individualShare;

      bool found = false;
      String? contactPhone = contact['number'];
      if (contactPhone == null) continue;

      // Trim the phone number and remove any spaces.
      contactPhone = contactPhone.trim().replaceAll(RegExp(r'\s+'), '');

      // Check if the phone number already has the "+91" prefix; if not, add it.
      if (!contactPhone.startsWith("+91")) {
        contactPhone = "+91" + contactPhone;
      }
      // Iterate over the existing friends entries.
      friends.forEach((key, friendData) {
        if (friendData is Map<String, dynamic>) {
          // Compare the stored phone number with the current contact's number.
          if (friendData['phoneNumber'] == contactPhone) {
            found = true;
            // If found, update the "theyOwe" value by adding the split amount.
            double existingOwe = (friendData['theyOwe'] ?? 0 as num).toDouble();

            friendData['theyOwe'] = existingOwe + splitAmount;
            friends[key] = friendData;
          }
        }
      });

      // If no matching friend was found, add a new map for this contact.
      if (!found) {
        // Here we use the contact's phone number as the key.
        friends[contactPhone] = {
          'name': contact['name'],
          'phoneNumber': contactPhone,
          'theyOwe': splitAmount,
        };
      }
    }

    // Update the user's document with the modified friends map.
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userPhone)
        .update({'friends': friends});
  }
  Future<void> updateGroupForContacts(String groupName, Map<String, dynamic> groupData) async {
    // Loop through each selected contact.
    for (var contact in widget.contacts) {
      String? contactPhone = contact['number'];
      if (contactPhone == null) continue;

      // Trim the phone number and remove any spaces.
      contactPhone = contactPhone.trim().replaceAll(RegExp(r'\s+'), '');

      // Check if the phone number already has the "+91" prefix; if not, add it.
      if (!contactPhone.startsWith("+91")) {
        contactPhone = "+91" + contactPhone;
      }

      // Check if there is a user document for this contact.
      DocumentSnapshot contactDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(contactPhone)
          .get();
      if (contactDoc.exists) {
        // If the document exists, update its 'groups' field by merging the new group.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(contactPhone)
            .set({
          'groups': { groupName: groupData }
        }, SetOptions(merge: true));
      }
    }
  }
  /// Updates each selected contact's Firestore document under the "friends" map.
  /// For each contact:
  /// - Check if the contact exists (document id equals the formatted contact phone).
  /// - In the contact's document, check if there is an entry in "friends" whose "phoneNumber"
  ///   matches the current user's phone number.
  /// - If found, update the "youOwe" field (adding the split amount); if not found, add a new map
  ///   with the current user's details (using groupOwnerName as the name) and set both "theyOwe"
  ///   and "youOwe" to the split amount.
  Future<void> updateFriendsForContacts(String groupOwnerName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.phoneNumber == null) return;
    final String currentUserPhone = user.phoneNumber!;

    // Loop over each selected contact.
    for (int i = 0; i < widget.contacts.length; i++) {
      var contact = widget.contacts[i];
      // Get and format the contact's phone number.
      String? contactPhone = contact['number'];
      if (contactPhone == null) continue;
      contactPhone = contactPhone.trim().replaceAll(RegExp(r'\s+'), '');
      if (!contactPhone.startsWith("+91")) {
        contactPhone = "+91" + contactPhone;
      }

      print('Phone:'+contactPhone);

      // Check if a user document exists for this contact.
      DocumentSnapshot contactDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(contactPhone)
          .get();

      if (contactDoc.exists) {
        Map<String, dynamic> contactData =
        contactDoc.data() as Map<String, dynamic>;
        // Get the friends map (or initialize to empty if not present).
        Map<String, dynamic> friendsMap = {};
        if (contactData.containsKey('friends') && contactData['friends'] is Map) {
          friendsMap = Map<String, dynamic>.from(contactData['friends']);
        }

        // Determine the split amount for this contact.
        double splitAmount = (customContactShares != null &&
            customContactShares!.length > i)
            ? customContactShares![i]
            : splitCalculator.individualShare;

        bool found = false;
        // Iterate over the entries in the friends map.
        for (String key in friendsMap.keys) {
          final friendData = friendsMap[key];
          if (friendData is Map<String, dynamic>) {
            // Compare the "phoneNumber" field with the current user's phone number.
            if (friendData['phoneNumber'] == currentUserPhone) {
              found = true;
              // If "youOwe" exists, add to it; otherwise, insert it with the splitAmount.
              double existingYouOwe = 0.0;
              if (friendData.containsKey('youOwe')) {
                existingYouOwe =
                    double.tryParse(friendData['youOwe'].toString()) ?? 0.0;
              }
              friendData['youOwe'] =
                  (existingYouOwe + splitAmount).toStringAsFixed(2);
              friendsMap[key] = friendData;
              break;
            }
          }
        }

        // If no matching friend entry is found, add a new entry.
        if (!found) {
          friendsMap[currentUserPhone] = {
            'phoneNumber': currentUserPhone,
            'name': groupOwnerName,

            'youOwe': splitAmount.toStringAsFixed(2),
          };
        }

        // Update the contact's document with the updated friends map.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(contactPhone)
            .update({'friends': friendsMap});
      }
    }
  }

  /// Displays the dialog for editing individual split values.
  Future<void> _showEditDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditSplitDialog(
        totalAmount: widget.amount,
        initialUserShare: customUserShare ?? splitCalculator.individualShare,
        initialContactShares: customContactShares ??
            List<double>.filled(widget.contacts.length, splitCalculator.individualShare),
        contacts: widget.contacts,
      ),
    );

    if (result != null) {
      setState(() {
        customUserShare = result['userShare'] as double;
        customContactShares = result['contactShares'] as List<double>;
      });
    }
  }

  Future<Map<String, String>?> getRandomNotification() async {
    try {
      // Retrieve all documents from the "notifications" collection.
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('notifications').get();

      // Check if there are any documents.
      if (snapshot.docs.isEmpty) {
        return null;
      }

      // Generate a random index within the range of available documents.
      int randomIndex = Random().nextInt(snapshot.docs.length);
      DocumentSnapshot randomDoc = snapshot.docs[randomIndex];

      // Extract the "title" and "body" fields.
      String title = randomDoc.get('title');
      String body = randomDoc.get('body');

      // Return the values as a map.
      return {'title': title, 'body': body};
    } catch (e) {
      print('Error retrieving random notification: $e');
      return null;
    }
  }

  /// Builds and returns the UI for the split transaction screen.
  @override
  Widget build(BuildContext context) {
    if (widget.amount <= 0) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              "Error: The amount must be greater than zero.",
              style: TextStyle(color: AppConstants.errorColor, fontSize: 18),
            ),
          ),
        ),
      );
    }

    bool isValidSplit = ((totalCustomSplit - widget.amount).abs() < 0.01);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SplitTransactionHeader(
                    groupName: widget.groupName,
                    amount: widget.amount,
                    formattedDate: formattedDate,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: widget.expenseItems.isNotEmpty
                        ? Text(
                      "Expense: ${widget.expenseItems.join(', ')}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'interRegular',
                        color: AppConstants.textColor,
                      ),
                    )
                        : const Text(
                      "No expense details available.",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'interRegular',
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(
                    child: widget.contacts.isNotEmpty
                        ? ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.contacts.length,
                      itemBuilder: (context, index) {
                        final double share = (customContactShares != null &&
                            customContactShares!.length > index)
                            ? customContactShares![index]
                            : splitCalculator.individualShare;
                        final double progress = share / widget.amount;
                        final Color progressColor =
                        progressColors[index % progressColors.length];
                        return ContactRow(
                          contact: widget.contacts[index],
                          share: share,
                          progress: progress,
                          progressColor: progressColor,
                        );
                      },
                    )
                        : const Center(
                      child: Text(
                        "No participants selected. Please add contacts to split the expense.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: _showEditDialog,
                        icon: const Icon(Icons.edit, color: AppConstants.textColor),
                        label: const Text(
                          "Edit Individually",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'interSemiBold',
                            color: AppConstants.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppConstants.primaryColor,
                                AppConstants.secondaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              if (widget.contacts.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No participants to split with. Please add contacts.'),
                                    backgroundColor: AppConstants.errorColor,
                                  ),
                                );
                                return;
                              }
                              if (!isValidSplit) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Custom splits do not add up to the total amount. Please adjust the splits.'),
                                    backgroundColor: AppConstants.errorColor,
                                  ),
                                );
                                return;
                              }

                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null || user.phoneNumber == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Authentication error: No valid phone number found.'),
                                    backgroundColor: AppConstants.errorColor,
                                  ),
                                );
                                return;
                              }
                              final String userPhone = user.phoneNumber!;
                              String? groupOwnerAvatar;
                              String? groupOwnerName;
                              DocumentSnapshot userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userPhone)
                                  .get();
                              if (userDoc.exists) {
                                final data = userDoc.data() as Map<String, dynamic>;
                                // Retrieve the user's own avatar from the pidata map.

                                final pidata = data['pidata'] as Map<String, dynamic>?;
                                groupOwnerName = pidata != null && pidata['name'] != null
                                    ? pidata['name'] as String
                                    : '';
                                groupOwnerAvatar = pidata != null && pidata['avatar'] != null
                                    ? pidata['avatar'] as String
                                    : '';
                              }

                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                List<Future<Map<String, dynamic>>> splitFutures = [];
                                for (int i = 0; i < widget.contacts.length; i++) {
                                  final contact = widget.contacts[i];
                                  final String uniqueFileName =
                                      "${contact['number']}_${DateTime.now().millisecondsSinceEpoch}";
                                  String? contactPhone = contact['number'];
                                  if (contactPhone == null) continue;
                                  // Trim the phone number and remove any spaces.
                                  contactPhone = contactPhone.trim().replaceAll(RegExp(r'\s+'), '');
                                  // Check if the phone number already has the "+91" prefix; if not, add it.
                                  if (!contactPhone.startsWith("+91")) {
                                    contactPhone = "+91" + contactPhone;
                                  }
                                  splitFutures.add(() async {
                                    final String avatarUrl =
                                    await uploadAvatar(uniqueFileName, contact['avatar']);
                                    return {
                                      'name': contact['name'],
                                      'splitAmount': (customContactShares != null &&
                                          customContactShares!.length > i)
                                          ? customContactShares![i]
                                          : splitCalculator.individualShare,
                                      'phoneNumber': contactPhone,
                                      'avatar': avatarUrl,
                                    };
                                  }());
                                  final notificationData = await getRandomNotification();
                                  String title = notificationData!['title']!;
                                  String body = notificationData['body']!;
                                  body = body.replaceAll("\$groupOwnerName", groupOwnerName!);
                                  await pushService.sendPushNotification(
                                    contactPhone: contactPhone,
                                    title:title,
                                    body:body

                                  );
                                }

                                final List<Map<String, dynamic>> splitsList =
                                await Future.wait(splitFutures);

                                Map<String, dynamic> groupData = {
                                  'groupname': widget.groupName,
                                  'groupOwnerAvatar':groupOwnerAvatar,
                                  'groupOwnerName':groupOwnerName,
                                  'groupOwnerNumber':userPhone,
                                  'type': widget.expenseItems,
                                  'splits': splitsList,
                                };

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userPhone)
                                    .set({
                                  'groups': {widget.groupName: groupData}
                                }, SetOptions(merge: true));

                                // Now update the friends node.
                                await updateFriends();

                                await updateGroupForContacts(widget.groupName, groupData);

                                // <-- New functionality: update each contact's friends mapping.
                                await updateFriendsForContacts(groupOwnerName ?? '');



                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Split transaction sent successfully.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => BottomNavigationMainScreen(),
                                  ),
                                );

                              } on FirebaseException catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to send split transaction: ${e.message}'),
                                    backgroundColor: AppConstants.errorColor,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('An unexpected error occurred: $e'),
                                    backgroundColor: AppConstants.errorColor,
                                  ),
                                );
                              } finally {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              ),
                            ),
                            child: const Text(
                              "Send Split",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'InterSemiBold',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
