import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:splitter/repository/GroupRepository.dart';
import 'package:splitter/widgets/ActionButtonsWidget.dart';
import 'package:splitter/widgets/GridItemWidget.dart';
import 'package:splitter/widgets/HeaderWidge.dart';
import 'package:splitter/widgets/HistoryItemWidget.dart';
import 'package:splitter/widgets/OverlappingAvatarsWidge.dart';
import 'package:splitter/widgets/OwedTextWidget.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isGroupOwner;

  const GroupDetailsPage({Key? key, required this.groupId, required this.groupName, required this.isGroupOwner}) : super(key: key);

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  final GroupRepository _groupRepository = GroupRepository();
  final Logger _logger = Logger();
  Map<String, dynamic>? groupData;
  bool _isLoading = true;
  String? groupOwnerAvatar;
  String? userAvatar;
  String? currentUserPhone;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    final phoneNumber = user?.phoneNumber;
    if (phoneNumber == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "User phone number not found.";
      });
      showErrorNotification(context, _errorMessage!);
      return;
    }
    currentUserPhone = phoneNumber;
    try {
      final fetchedGroupData = await _groupRepository.fetchGroupData(phoneNumber, widget.groupId);
      if (fetchedGroupData != null) {
        setState(() {
          groupData = fetchedGroupData;
          // Example: extract avatars from group data (adjust as needed)
          userAvatar = fetchedGroupData['userAvatar'] ?? '';
          groupOwnerAvatar = fetchedGroupData['groupOwnerAvatar'] ?? '';
        });
      } else {
        setState(() {
          _errorMessage = "Group details not found.";
        });
        showErrorNotification(context, _errorMessage!);
      }
    } catch (e, stackTrace) {
      _logger.e("Error loading group details: $e");
      setState(() {
        _errorMessage = "Error loading group details: $e";
      });
      showErrorNotification(context, _errorMessage!);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _settleUp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.phoneNumber == null) {
      showErrorNotification(context, "User not logged in or phone number missing");
      return;
    }
    final currentUserPhone = user.phoneNumber!;
    if (groupData == null) {
      showErrorNotification(context, "Group data is not loaded.");
      return;
    }
    try {
      await _groupRepository.settleUp(widget.groupId, currentUserPhone, groupData!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Settle up completed successfully."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      // Optionally reload group details to reflect changes.
      _loadGroupDetails();
    } catch (e, stackTrace) {
      _logger.e("Error settling up: $e");
      showErrorNotification(context, "Error settling up: $e");
    }
  }

  Future<void> _sendReminder() async {
    // Implement the actual reminder-sending logic here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reminder sent successfully."),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Builds the owed text widget. For owners, it displays "They owed:" with the total split amount.
  Widget _buildOwedTextWidget(double screenWidth) {
    if (widget.isGroupOwner) {
      double total = 0.0;
      List<dynamic> splits = groupData?['splits'] as List<dynamic>? ?? [];
      for (var split in splits) {
        if (split is Map<String, dynamic> && split['splitAmount'] != null) {
          double amount = 0.0;
          try {
            amount = double.parse(split['splitAmount'].toString());
          } catch (e) {
            amount = 0.0;
          }
          total += amount;
        }
      }
      return Padding(
        padding: const EdgeInsets.only(top: 20.0), // Adjust the padding as needed
        child: Container(
          width: screenWidth, // Ensures the container takes full screen width
          child: Column(
            children: [
              Text(
                "₹${total.toStringAsFixed(2)}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "they owe you",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return OwedTextWidget(
        groupData: groupData!,
        currentUserPhone: currentUserPhone,
        screenWidth: screenWidth,
      );
    }
  }





  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate total split amount if groupData is available
    double totalSplitAmount = 0.0;
    if (groupData != null && groupData!['splits'] != null) {
      final splitsList = groupData!['splits'] as List<dynamic>;
      for (var split in splitsList) {
        if (split is Map<String, dynamic>) {
          totalSplitAmount +=
              double.tryParse(split['splitAmount']?.toString() ?? '0') ?? 0.0;
        }
      }
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : groupData == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Group details not available',
                style: TextStyle(fontFamily: 'interSemiBold'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadGroupDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const HeaderWidget(title: 'Group Name'),
                    const SizedBox(height: 16),
                    OverlappingAvatarsWidget(
                      userAvatarUrl: userAvatar,
                      ownerAvatarUrl: groupOwnerAvatar,
                      screenWidth: screenWidth,
                    ),
                    _buildOwedTextWidget(screenWidth),
                    ActionButtonsWidget(
                      onSettleUp: widget.isGroupOwner ? _sendReminder : _settleUp,
                      isGroupOwner: widget.isGroupOwner,
                      label: widget.isGroupOwner
                          ? "Send Reminder"
                          : "Settle Up",
                      icon: widget.isGroupOwner
                          ? Icons.notifications
                          : Icons.check,
                    ),
                    const SizedBox(height: 13),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Splits:',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            // Grid and History sections continue...
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 600 ? 6 : 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final splitsList = groupData!['splits'] as List<dynamic>;
                    final split = splitsList[index];
                    if (split is Map<String, dynamic>) {
                      final String splitAmount = split['splitAmount']?.toString() ?? '0.00';
                      final String? avatarUrl = split['avatar'] as String?;
                      return GridItemWidget(splitAmount: splitAmount, avatarUrl: avatarUrl);
                    }
                    return const SizedBox.shrink();
                  },
                  childCount: (groupData!['splits'] as List<dynamic>).length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text(
                  'History:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final historyList = groupData!['history'] as List<dynamic>;
                  final entry = historyList[index];
                  if (entry is Map<String, dynamic>) {
                    final String note = entry['note']?.toString() ?? 'No note provided';
                    final String expense = entry['expense']?.toString() ?? '0.00';
                    final dynamic timestampValue = entry['date'];
                    DateTime? dateTime;
                    if (timestampValue != null) {
                      try {
                        dateTime = (timestampValue as Timestamp).toDate();
                      } catch (e) {
                        dateTime = null;
                      }
                    }
                    final String formattedDate = dateTime != null
                        ? DateFormat('yyyy-MM-dd').format(dateTime)
                        : 'Unknown date';
                    return HistoryItemWidget(
                        note: note, expense: expense, formattedDate: formattedDate);
                  }
                  return const SizedBox.shrink();
                },
                childCount: (groupData!['history'] as List<dynamic>? ?? []).length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

/// Utility function to display error notifications.
void showErrorNotification(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}
