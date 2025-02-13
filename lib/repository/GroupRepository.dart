import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class GroupRepository {
  final Logger logger;

  GroupRepository({Logger? logger}) : logger = logger ?? Logger();

  Future<List<Map<String, dynamic>>> fetchUserGroups(String phoneNumber) async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (!userDoc.exists) {
        logger.e("User document not found for phone: $phoneNumber");
        return [];
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final groupsMap = data['groups'] as Map<String, dynamic>?;

      List<Map<String, dynamic>> groups = [];
      if (groupsMap != null) {
        groupsMap.forEach((groupId, groupData) {
          if (groupData is Map<String, dynamic>) {
            final groupName = groupData['groupname'] ?? 'Unnamed Group';
            final splits = groupData['splits'] as List<dynamic>? ?? [];
            List<String> avatars = [];
            double owedAmount = 0.0;

            final groupOwnerNumber = groupData['groupOwnerNumber'] as String? ?? '';
            final isGroupOwner = (groupOwnerNumber == phoneNumber);

            for (var split in splits) {
              if (split is Map<String, dynamic>) {
                final avatar = split['avatar'] as String? ?? '';
                if (avatar.isNotEmpty) {
                  avatars.add(avatar);
                }
                final splitValue = split['splitAmount'] ?? split['splitamount'];
                if (splitValue != null) {
                  owedAmount += double.tryParse(splitValue.toString()) ?? 0.0;
                }
              }
            }

            groups.add({
              'groupId': groupId,
              'groupName': groupName,
              'owedAmount': owedAmount,
              'avatars': avatars,
              'splits': splits,
              'isgroupowner': isGroupOwner,
            });
          }
        });
      }
      return groups;
    } catch (e, stackTrace) {
      logger.e("Error fetching user groups: $e", error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Fetches group data from the current user's Firestore document.
  Future<Map<String, dynamic>?> fetchGroupData(String phoneNumber, String groupId) async {
    try {
      final DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(phoneNumber).get();

      if (!userDoc.exists) {
        logger.e("User document not found for phone: $phoneNumber");
        return null;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final groups = data['groups'] as Map<String, dynamic>?;

      if (groups == null || !groups.containsKey(groupId)) {
        logger.e("Group data not found for groupId: $groupId");
        return null;
      }

      return groups[groupId] as Map<String, dynamic>;
    } catch (e, stackTrace) {
      logger.e("Error fetching group details", error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Executes a transaction to “settle up” between the current user and the group owner.
  Future<void> settleUp(String groupId, String currentUserPhone, Map<String, dynamic> groupData) async {
    final String? groupOwnerNumber = groupData['groupOwnerNumber'];
    if (groupOwnerNumber == null || groupOwnerNumber.isEmpty) {
      throw Exception("Group owner number is missing.");
    }

    final DocumentReference userRef =
    FirebaseFirestore.instance.collection('users').doc(currentUserPhone);
    final DocumentReference ownerRef =
    FirebaseFirestore.instance.collection('users').doc(groupOwnerNumber);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final ownerSnapshot = await transaction.get(ownerRef);

        if (!userSnapshot.exists) throw Exception("User document not found.");
        if (!ownerSnapshot.exists) throw Exception("Group owner document not found.");

        final userData = userSnapshot.data() as Map<String, dynamic>;
        final ownerData = ownerSnapshot.data() as Map<String, dynamic>;

        // --- Update Current User Document ---
        if (userData.containsKey('groups') && userData['groups'][groupId] != null) {
          Map<String, dynamic> groupEntry =
          Map<String, dynamic>.from(userData['groups'][groupId]);
          if (groupEntry.containsKey('splits') && groupEntry['splits'] is List) {
            List<dynamic> splits = List<dynamic>.from(groupEntry['splits']);
            List<dynamic> updatedSplits = splits.map((split) {
              if (split is Map<String, dynamic> && split['phoneNumber'] == currentUserPhone) {
                split['splitAmount'] = 0;
              }
              return split;
            }).toList();
            groupEntry['splits'] = updatedSplits;
            Map<String, dynamic> groups = Map<String, dynamic>.from(userData['groups']);
            groups[groupId] = groupEntry;
            transaction.update(userRef, {'groups': groups});
          } else {
            throw Exception("Splits data not found in current user group.");
          }

          if (userData.containsKey('friends') && userData['friends'] is Map) {
            Map<String, dynamic> friends = Map<String, dynamic>.from(userData['friends']);
            bool friendUpdated = false;
            friends.forEach((key, friend) {
              if (friend is Map<String, dynamic> && friend['phoneNumber'] == groupOwnerNumber) {
                friend['youOwe'] = 0;
                friendUpdated = true;
              }
            });
            if (friendUpdated) {
              transaction.update(userRef, {'friends': friends});
            } else {
              throw Exception("Group owner's friend entry not found in current user document.");
            }
          } else {
            throw Exception("Friends data not found in current user document.");
          }
        } else {
          throw Exception("Group data not found in current user's groups.");
        }

        // --- Update Group Owner Document ---
        if (ownerData.containsKey('groups') && ownerData['groups'][groupId] != null) {
          Map<String, dynamic> groupEntryOwner =
          Map<String, dynamic>.from(ownerData['groups'][groupId]);
          if (groupEntryOwner.containsKey('splits') && groupEntryOwner['splits'] is List) {
            List<dynamic> splitsOwner = List<dynamic>.from(groupEntryOwner['splits']);
            List<dynamic> updatedSplitsOwner = splitsOwner.map((split) {
              if (split is Map<String, dynamic> && split['phoneNumber'] == currentUserPhone) {
                split['splitAmount'] = 0;
              }
              return split;
            }).toList();
            groupEntryOwner['splits'] = updatedSplitsOwner;
            Map<String, dynamic> groupsOwner = Map<String, dynamic>.from(ownerData['groups']);
            groupsOwner[groupId] = groupEntryOwner;
            transaction.update(ownerRef, {'groups': groupsOwner});
          } else {
            throw Exception("Splits data not found in group owner's group.");
          }

          if (ownerData.containsKey('friends') && ownerData['friends'] is Map) {
            Map<String, dynamic> friendsOwner = Map<String, dynamic>.from(ownerData['friends']);
            bool friendUpdatedOwner = false;
            friendsOwner.forEach((key, friend) {
              if (friend is Map<String, dynamic> && friend['phoneNumber'] == currentUserPhone) {
                friend['theyOwe'] = 0;
                friendUpdatedOwner = true;
              }
            });
            if (friendUpdatedOwner) {
              transaction.update(ownerRef, {'friends': friendsOwner});
            } else {
              throw Exception("Current user's friend entry not found in group owner's document.");
            }
          } else {
            throw Exception("Friends data not found in group owner's document.");
          }
        } else {
          throw Exception("Group data not found in group owner's groups.");
        }
      });
    } catch (e, stackTrace) {
      logger.e("Error in settleUp", error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Updates expense for a given group.
  Future<void> updateExpenseForGroup({
    required String phoneNumber,
    required String groupId,
    required List<dynamic> splits,
    required Map<String, dynamic> historyEntry,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(phoneNumber).update({
        'groups.$groupId.splits': splits,
        'groups.$groupId.history': FieldValue.arrayUnion([historyEntry]),
      });
    } catch (e, stackTrace) {
      logger.e("Error updating expense for group: $e", error: e, stackTrace: stackTrace);
      // Fallback: try using set with merge.
      try {
        await FirebaseFirestore.instance.collection('users').doc(phoneNumber).set({
          'groups': {
            groupId: {
              'splits': splits,
              'history': FieldValue.arrayUnion([historyEntry]),
            },
          },
        }, SetOptions(merge: true));
      } catch (setError, setStackTrace) {
        logger.e("Error updating expense using set with merge: $setError", error: setError, stackTrace: setStackTrace);
        rethrow;
      }
    }
  }
  /// Update the friends map for expense sharing.
  Future<void> updateFriendsForExpense(String phoneNumber, List<dynamic> splits, double expensePerFriend) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};
      Map<String, dynamic> friendsMap = {};

      if (userData.containsKey('friends') && userData['friends'] is Map) {
        friendsMap = Map<String, dynamic>.from(userData['friends']);
      }

      for (var split in splits) {
        if (split is Map<String, dynamic>) {
          final contactPhone = split['phoneNumber'];
          final contactName = split['name'] ?? 'Unknown';
          if (contactPhone == null) continue;

          double additionalAmount = expensePerFriend;
          if (friendsMap.containsKey(contactPhone)) {
            Map<String, dynamic> friendData = Map<String, dynamic>.from(friendsMap[contactPhone]);
            double existingOwe = double.tryParse(friendData['theyOwe'].toString()) ?? 0.0;
            friendData['theyOwe'] = (existingOwe + additionalAmount).toStringAsFixed(2);
            friendsMap[contactPhone] = friendData;
          } else {
            friendsMap[contactPhone] = {
              'name': contactName,
              'phoneNumber': contactPhone,
              'theyOwe': additionalAmount.toStringAsFixed(2),
            };
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .update({'friends': friendsMap});
    } catch (e, stackTrace) {
      logger.e("Error updating friends for expense: $e", error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
