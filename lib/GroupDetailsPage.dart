import 'dart:math';

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

import 'Constants/AppConstants.dart';
class AppTextStyles {
  static TextStyle interBold({double fontSize = 14, Color color = Colors.black}) {
    return TextStyle(
      fontFamily: 'interBold',
      fontSize: fontSize,
      color: color,
    );
  }

  static TextStyle interRegular({double fontSize = 14, Color color = Colors.black}) {
    return TextStyle(
      fontFamily: 'interRegular',
      fontSize: fontSize,
      color: color,
    );
  }

  static TextStyle interSemiBold({double fontSize = 14, Color color = Colors.black}) {
    return TextStyle(
      fontFamily: 'interSemiBold',
      fontSize: fontSize,
      color: color,
    );
  }
}



class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isGroupOwner;

  const GroupDetailsPage({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.isGroupOwner,
  }) : super(key: key);

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
      final fetchedGroupData =
      await _groupRepository.fetchGroupData(phoneNumber, widget.groupId);
      if (fetchedGroupData != null) {
        setState(() {
          groupData = fetchedGroupData;
          // Example: extract avatars from group data (adjust as needed)
          userAvatar = fetchedGroupData['avatar'] ?? '';
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

  /// -----------------------------
  /// BUILD VIEW FOR GROUP OWNERS
  /// -----------------------------
  Widget _buildOwnerView(BuildContext context) {
    // Calculate the total that others owe the owner.
    double totalOwed = 0.0;
    final splits = groupData?['splits'] as List<dynamic>? ?? [];
    for (var split in splits) {
      if (split is Map<String, dynamic> && split['splitAmount'] != null) {
        totalOwed += double.tryParse(split['splitAmount'].toString()) ?? 0.0;
      }
    }
    // Prepare history and favorites data.
    final historyList = groupData?['history'] as List<dynamic>? ?? [];
    final favorites = splits.take(5).toList(); // First 5 items

    return Column(
      children: [
        // Header section on a gray background with reduced vertical padding.
        Stack(
          children: [
            // Background color for the whole stack.
            Container(
              width: double.infinity,
              height: 150, // Use a fixed height, e.g., 250.0
              color: Colors.grey.shade100,
            ),

            // Positioned image behind the text and above the background.
            Positioned(
              top: -20,
              right: -50,
              child: Transform.rotate(
                angle: pi / -6, // Rotates the image 45 degrees.
                child: Image.asset(
                  'assets/logo/splitzoWhite.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Foreground content.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  HeaderWidget(title: ""),
                  // Rounded white box with an icon before the group name text and a dropdown icon after.
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group, // Primary icon before the group name.
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.groupName,
                          style: AppTextStyles.interSemiBold(fontSize: 18),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down, // Dropdown icon after the group name.
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Total Balance",
                    style: AppTextStyles.interRegular(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    "₹${totalOwed.toStringAsFixed(2)}",
                    style: AppTextStyles.interBold(fontSize: 36),
                  ),
                ],
              ),
            )


          ],
        ),

        // White container with rounded corners filling the rest of the screen.
        Expanded(
          child: Container(
            width: double.infinity,
            // Reduced top margin to bring content closer to header.
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.only(top: 16,right: 16,left: 16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        label: "Send Reminder",
                        icon: Icons.send_to_mobile,
                        onTap: () {
                          _sendReminder();
                        },
                        isGradient: true, // Gradient background for the first item.
                      ),
                      _buildActionButton(
                        label: "Custom Split",
                        icon: Icons.call_split, // You can choose another icon if desired.
                        onTap: () {
                          // Implement your custom split action.
                        },
                      ),
                      _buildActionButton(
                        label: "Expense",
                        icon: Icons.attach_money, // Represents expense; adjust as needed.
                        onTap: () {
                          // Implement your expense action.
                        },
                      ),
                    ],

                  ),
                  const SizedBox(height: 20),
                  // Friends Section
                  const Text(
                    "Friends",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: favorites.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = favorites[index];
                        final avatarUrl = (item is Map<String, dynamic>)
                            ? (item['avatar'] ?? "")
                            : "";
                        final contactName = (item is Map<String, dynamic>)
                            ? (item['name'] ?? "Unknown")
                            : "Unknown";
                        final double parsedSplitAmount = double.tryParse(
                            item is Map<String, dynamic>
                                ? item['splitAmount']?.toString() ?? "0"
                                : "0") ??
                            0.0;
                        final splitAmount = parsedSplitAmount.toStringAsFixed(2);

                        return Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl.isEmpty
                                      ? const Icon(Icons.person, size: 24)
                                      : null,
                                ),
                                Positioned(
                                  top: -8,
                                  right: -10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "₹$splitAmount",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontFamily: 'interSemiBold'
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              contactName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Latest Transactions Section
                  const Text(
                    "Transactions",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: historyList.map((entry) {
                      if (entry is Map<String, dynamic>) {
                        final String note =
                            entry['note']?.toString() ?? 'No note';
                        final String expense =
                            entry['expense']?.toString() ?? '0.00';
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
                            ? DateFormat('dd MMM yyyy').format(dateTime)
                            : 'Unknown date';

                        return _buildTransactionItem(
                          note: note,
                          expense: expense,
                          date: formattedDate,
                        );
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }





  /// -------------------------------
  /// BUILD VIEW FOR NON-OWNERS
  /// (original or simplified layout)
  /// -------------------------------
  Widget _buildMemberView(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // For the non-owner design, we reuse the older Sliver-based layout or a simpler version
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Original or simplified header
                const HeaderWidget(title: 'Group Name'),
                const SizedBox(height: 16),
                OverlappingAvatarsWidget(
                  userAvatarUrl: userAvatar,
                  ownerAvatarUrl: groupOwnerAvatar,
                  screenWidth: screenWidth,
                ),
                // Example OwedTextWidget usage
                OwedTextWidget(
                  groupData: groupData!,
                  currentUserPhone: currentUserPhone,
                  screenWidth: screenWidth,
                ),
                ActionButtonsWidget(
                  onSettleUp: _settleUp,
                  isGroupOwner: false,
                  label: "Settle Up",
                  icon: Icons.check,
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
                  final String splitAmount =
                      split['splitAmount']?.toString() ?? '0.00';
                  final String? avatarUrl = split['avatar'] as String?;
                  return GridItemWidget(
                    splitAmount: splitAmount,
                    avatarUrl: avatarUrl,
                  );
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
                final String note =
                    entry['note']?.toString() ?? 'No note provided';
                final String expense =
                    entry['expense']?.toString() ?? '0.00';
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
                  note: note,
                  expense: expense,
                  formattedDate: formattedDate,
                );
              }
              return const SizedBox.shrink();
            },
            childCount:
            (groupData!['history'] as List<dynamic>? ?? []).length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  /// Helper for building a transaction (history) item in the owner view
  Widget _buildTransactionItem({
    required String note,
    required String expense,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // A simple icon or avatar
          CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.shopping_cart, color: Colors.grey.shade800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "₹$expense",
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper for building a quick action button in the owner view
// Updated action button builder.
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isGradient = false, // New parameter.
  }) {
    // Determine circle and icon colors based on isGradient.
    final circleColor = isGradient ? Colors.black : Colors.white;
    final iconColor = isGradient ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 120, // Increase height to accommodate the text below the circle.
        decoration: BoxDecoration(
          // If isGradient is true, use the gradient; otherwise, use a grey background.
          gradient: isGradient
              ? LinearGradient(
            colors: [
              AppConstants.primaryColor,
              AppConstants.primaryGradientColor
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isGradient ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circle with icon.
            Container(
              width: 60, // Size of the circle.
              height: 60, // Size of the circle.
              decoration: BoxDecoration(
                color: circleColor, // Color based on isGradient.
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor), // Icon color based on isGradient.
            ),
            const SizedBox(height: 8), // Space between circle and text.
            // Text label.
            Text(
              label,
              style: const TextStyle(
                fontSize: 12, // Adjust text size.
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Sets overall page background to gray.
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
                style: TextStyle(fontFamily: 'InterSemiBold'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadGroupDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : widget.isGroupOwner
            ? _buildOwnerView(context) // Revised owner design.
            : _buildMemberView(context),
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
