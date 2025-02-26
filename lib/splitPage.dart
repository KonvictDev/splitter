import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitter/repository/GroupRepository.dart';
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
  final bool allContactsExist;

  const SplitTransactionScreen({
    Key? key,
    required this.expenseItems,
    required this.amount,
    required this.contacts,
    required this.groupName,
    required this.allContactsExist,
  }) : super(key: key);

  @override
  State<SplitTransactionScreen> createState() => _SplitTransactionScreenState();
}

class _SplitTransactionScreenState extends State<SplitTransactionScreen> {
  final GroupRepository _groupsRepository = GroupRepository();

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Use post-frame callback to show the SnackBar after the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.allContactsExist) {
        showCustomSnackBar(
            context, "Please select all required fields before proceeding.");
      }
    });
  }

  // SnackBar function
  void showCustomSnackBar(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }



  /// Normalizes a phone number by trimming, removing spaces, and ensuring the "+91" prefix.
  String? normalizePhone(String? phone) {
    if (phone == null) return null;
    String normalized = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (!normalized.startsWith("+91")) {
      normalized = "+91" + normalized;
    }
    return normalized;
  }

  /// Computes and returns the total of the custom split amounts.
  double get totalCustomSplit {
    double total = customUserShare ?? 0.0;
    if (customContactShares != null) {
      total += customContactShares!.fold(0.0, (prev, element) => prev + element);
    }
    return total;
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

  Future<Map<String, dynamic>> _processContact(
      Map<String, dynamic> contact, int index, String? groupOwnerName, Future<dynamic> notificationFuture) async {
    final String? rawPhone = contact['number'];
    final String? contactPhone = normalizePhone(rawPhone);
    if (contactPhone == null) return {};

    final String uniqueFileName = "${contact['number']}_${DateTime.now().millisecondsSinceEpoch}";
    final avatarUrl = await _groupsRepository.uploadAvatar(uniqueFileName, contact['avatar']);

    // Send push notification without awaiting the result.
    await _sendPushNotification(contactPhone, groupOwnerName, notificationFuture);

    return {
      'name': contact['name'],
      'splitAmount': (customContactShares != null && customContactShares!.length > index)
          ? customContactShares![index]
          : splitCalculator.individualShare,
      'phoneNumber': contactPhone,
      'avatar': avatarUrl,
    };
  }

  Future<void> _sendPushNotification(String contactPhone, String? groupOwnerName, Future<dynamic> notificationFuture) async {
    notificationFuture.then((notificationData) {
      if (notificationData != null) {
        String title = notificationData['title']!;
        String body = notificationData['body']!;
        body = body.replaceAll("\$groupOwnerName", groupOwnerName ?? '');
        pushService.sendPushNotification(
          contactPhone: contactPhone,
          title: title,
          body: body,
        ).catchError((_) {});
      }
    }).catchError((_) {});
  }

  Future<void> _handleSendSplit() async {
    // Early validations
    if (widget.contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No participants to split with. Please add contacts.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }
    if ((totalCustomSplit - widget.amount).abs() >= 0.01) {
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

    // Fetch current user details.
    String? groupOwnerAvatar;
    String? groupOwnerName;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userPhone).get();
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final pidata = data['pidata'] as Map<String, dynamic>?;
      groupOwnerName = pidata != null ? pidata['name'] as String? ?? '' : '';
      groupOwnerAvatar = pidata != null ? pidata['avatar'] as String? ?? '' : '';
    }

    setState(() {
      _isLoading = true;
    });

    // Start fetching notification data without waiting.
    final notificationFuture = _groupsRepository.getRandomNotification().catchError((_) => null);

    // Process all contacts concurrently.
    final List<Map<String, dynamic>> splitsList = await Future.wait(
      widget.contacts.asMap().entries.map((entry) => _processContact(
        entry.value,
        entry.key,
        groupOwnerName,
        notificationFuture,
      )),
    );

    // Build the group data.
    final Map<String, dynamic> groupData = {
      'groupname': widget.groupName,
      'groupOwnerAvatar': groupOwnerAvatar,
      'groupOwnerName': groupOwnerName,
      'groupOwnerNumber': userPhone,
      'type': widget.expenseItems,
      'splits': splitsList,
    };

    // Update Firestore and friends data (fire-and-forget).
    FirebaseFirestore.instance
        .collection('users')
        .doc(userPhone)
        .set({'groups': {widget.groupName: groupData}}, SetOptions(merge: true))
        .catchError((_) {});
    _groupsRepository
        .updateFriends(
      userPhone: userPhone,
      contacts: widget.contacts,
      customContactShares: customContactShares!,
      defaultShare: splitCalculator.individualShare,
    )
        .catchError((_) {});
    _groupsRepository
        .updateGroupForContacts(
      groupName: widget.groupName,
      groupData: groupData,
      contacts: widget.contacts,
    )
        .catchError((_) {});
    _groupsRepository
        .updateFriendsForContactsWithSplits(
      groupOwnerName: groupOwnerName ?? '',
      contacts: widget.contacts,
      customContactShares: customContactShares!,
      defaultShare: splitCalculator.individualShare,
    )
        .catchError((_) {});

    // Notify user and navigate.
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

    setState(() {
      _isLoading = false;
    });
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
                              onPressed: _handleSendSplit,
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
