import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:splitter/repository/GroupRepository.dart';
import 'package:splitter/widgets/ExpenseBottomSheet.dart';
import 'package:splitter/widgets/GroupCard.dart';

import 'GroupDetailsPage.dart';
import 'groupCreationPage.dart';

class GroupsPage extends StatefulWidget {
  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final GroupRepository _groupsRepository = GroupRepository();
  final Logger _logger = Logger();
  List<Map<String, dynamic>> groupList = [];
  bool _isLoading = true;

  // Constants for consistent spacing and styling.
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 16.0;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  /// Loads groups from Firestore via the repository.
  Future<void> _loadGroups() async {
    final user = FirebaseAuth.instance.currentUser;
    final phoneNumber = user?.phoneNumber;
    if (phoneNumber == null) {
      _updateLoadingState(false);
      _showErrorSnackbar('User phone number not found.');
      return;
    }

    try {
      final groups = await _groupsRepository.fetchUserGroups(phoneNumber);
      setState(() {
        groupList = groups;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.e("Error loading groups: $e", error: e, stackTrace: stackTrace);
      _updateLoadingState(false);
      _showErrorSnackbar('Error loading groups.');
    }
  }

  /// Helper to update loading state.
  void _updateLoadingState(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  /// Displays a Snackbar with an error or success message.
  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.black87,
      ),
    );
  }

  /// Displays an error message using a red Snackbar.
  void _showErrorSnackbar(String message) {
    _showSnackbar(message, isError: true);
  }

  /// Navigates to the GroupCreationPage.
  void _addGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupCreationPage()),
    );
  }

  /// Opens the expense bottom sheet by extracting the expense UI into a separate widget.
  void _addExpense(int index) {
    final group = groupList[index];
    final avatars = List<String>.from(group['avatars'] as List<dynamic>? ?? []);
    final splits = group['splits'] as List<dynamic>? ?? [];
    final groupId = group['groupId'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (BuildContext context) {
        return ExpenseBottomSheet(
          groupName: group['groupName'],
          avatars: avatars,
          splits: splits,
          groupId: groupId,
          onExpenseAdded: (expense, updatedSplits, historyEntry) async {
            // Update local state
            setState(() {
              groupList[index]['owedAmount'] += expense;
              groupList[index]['splits'] = updatedSplits;
            });
            final user = FirebaseAuth.instance.currentUser;
            if (user != null && user.phoneNumber != null) {
              final phoneNumber = user.phoneNumber!;
              try {
                await _groupsRepository.updateExpenseForGroup(
                  phoneNumber: phoneNumber,
                  groupId: groupId!,
                  splits: updatedSplits,
                  historyEntry: historyEntry,
                );
                _showSnackbar('Expense added successfully.');
              } catch (e, stackTrace) {
                _logger.e("Error updating expense: $e", error: e, stackTrace: stackTrace);
                _showErrorSnackbar('Failed to update expense.');
              }

              // Calculate split share and update friends.
              try {
                final splitShare = expense / (updatedSplits.length + 1);
                await _groupsRepository.updateFriendsForExpense(phoneNumber, updatedSplits, splitShare);
              } catch (e, stackTrace) {
                _logger.e("Error updating friends: $e", error: e, stackTrace: stackTrace);
              }
            }
          },
        );
      },
    );
  }

  /// Calculates the overall owed amount across all groups.
  double _calculateTotalOwed() {
    return groupList.fold(0.0, (sum, group) => sum + (group['owedAmount'] as double));
  }

  @override
  Widget build(BuildContext context) {
    final totalOwed = _calculateTotalOwed();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(horizontalPadding),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Groups',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall you are owed',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          '\$${totalOwed.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addGroup,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Group'),
                  ),
                ],
              ),
              const SizedBox(height: verticalPadding),
              Expanded(
                child: groupList.isEmpty
                    ? Center(
                  child: Text(
                    'No groups available.  Add a group to get started!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: groupList.length,
                  itemBuilder: (context, index) {
                    final group = groupList[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupDetailsPage(
                              groupId: group['groupId'],
                              groupName: group['groupName'],
                              isGroupOwner: group['isgroupowner'] ?? true,
                            ),
                          ),
                        );
                      },
                      child: GroupCard(
                        groupName: group['groupName'],
                        owedAmount: group['owedAmount'],
                        avatars: List<String>.from(group['avatars']),
                        isGroupOwner: group['isgroupowner'] ?? true,
                        onAddExpense: () => _addExpense(index),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


