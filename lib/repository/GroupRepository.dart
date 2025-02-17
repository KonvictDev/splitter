import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:logger/logger.dart';

class GroupRepository {
  final Logger logger;

  GroupRepository({Logger? logger}) : logger = logger ?? Logger();

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

  /// Normalizes a phone number by trimming, removing spaces, and ensuring the "+91" prefix.
  String? normalizePhone(String? phone) {
    if (phone == null) return null;
    String normalized = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (!normalized.startsWith("+91")) {
      normalized = "+91" + normalized;
    }
    return normalized;
  }

  Future<void> updateFriends({
    required String userPhone,
    required List<Map<String, dynamic>> contacts,
    required List<double> customContactShares,
    required double defaultShare,
  }) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userPhone);

    for (int i = 0; i < contacts.length; i++) {
      final contact = contacts[i];
      final rawPhone = contact['number'];
      if (rawPhone == null) continue;

      String contactPhone = normalizePhone(rawPhone)!;
      double splitAmount = (customContactShares.length > i) ? customContactShares[i] : defaultShare;

      // Create the friend data map
      Map<String, dynamic> friendData = {
        'name': contact['name'],
        'phoneNumber': contactPhone,
        'theyOwe': FieldValue.increment(splitAmount),
      };

      // Update the specific friend's data within the 'friends' map
      batch.set(
        userRef,
        {
          'friends': {
            contactPhone: friendData,
          }
        },
        SetOptions(merge: true),
      );
    }
    // Commit the batch operation
    await batch.commit();
  }

  Future<void> updateGroupForContacts({
    required String groupName,
    required Map<String, dynamic> groupData,
    required List<Map<String, dynamic>> contacts,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();
    int batchCounter = 0;

    for (final contact in contacts) {
      final String? rawPhone = contact['number'];
      final String? contactPhone = normalizePhone(rawPhone);
      if (contactPhone == null) continue;

      final DocumentReference docRef = firestore.collection('users').doc(contactPhone);

      batch.set(
        docRef,
        {
          'groups': {groupName: groupData}
        },
        SetOptions(merge: true),
      );

      batchCounter++;

      // Commit the batch every 500 operations
      if (batchCounter == 500) {
        await batch.commit();
        batch = firestore.batch();
        batchCounter = 0;
      }
    }

    // Commit any remaining operations
    if (batchCounter > 0) {
      await batch.commit();
    }
  }


  Future<void> updateFriendsForContactsWithSplits({
    required String groupOwnerName,
    required List<Map<String, dynamic>> contacts,
    required List<double> customContactShares,
    required double defaultShare,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.phoneNumber == null) return;
    final String currentUserPhone = user.phoneNumber!;

    List<Future> futures = contacts.asMap().entries.map((entry) async {
      final int i = entry.key;
      final contact = entry.value;
      final String? contactPhone = normalizePhone(contact['number']);
      if (contactPhone == null) return;

      final docRef =
      FirebaseFirestore.instance.collection('users').doc(contactPhone);
      final DocumentSnapshot contactDoc = await docRef.get();

      if (contactDoc.exists) {
        final Map<String, dynamic> contactData =
        contactDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> friendsMap = {};
        if (contactData['friends'] is Map) {
          friendsMap = Map<String, dynamic>.from(contactData['friends']);
        }
        double splitAmount = (customContactShares.length > i)
            ? customContactShares[i]
            : defaultShare;
        if (friendsMap.containsKey(currentUserPhone)) {
          final friendData = friendsMap[currentUserPhone] as Map<String, dynamic>;
          double existingYouOwe =
              double.tryParse(friendData['youOwe']?.toString() ?? "0") ?? 0.0;
          friendData['youOwe'] =
              (existingYouOwe + splitAmount).toStringAsFixed(2);
        } else {
          friendsMap[currentUserPhone] = {
            'phoneNumber': currentUserPhone,
            'name': groupOwnerName,
            'youOwe': splitAmount.toStringAsFixed(2),
          };
        }
        await docRef.update({'friends': friendsMap});
      }
    }).toList();

    await Future.wait(futures);
  }

  Future<Map<String, String>?> getRandomNotification() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('notifications').get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      int randomIndex = Random().nextInt(snapshot.docs.length);
      DocumentSnapshot randomDoc = snapshot.docs[randomIndex];

      String title = randomDoc.get('title');
      String body = randomDoc.get('body');

      return {'title': title, 'body': body};
    } catch (e) {
      print('Error retrieving random notification: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchFriends() async {
    List<Map<String, dynamic>> friends = [];
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return friends;

      String phoneNumber = user.phoneNumber!; // Get the user's phone number

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('friends')) {
          Map<String, dynamic> friendsMap = data['friends'];
          friends = friendsMap.entries.map((entry) {
            Map<String, dynamic> friendData = entry.value;
            return {
              'name': friendData['name'] ?? 'Unknown',
              'date': friendData['date'] ?? 'N/A',
              'amount': friendData['theyOwe'] ?? 0.00,
              'isOwed': friendData['isOwed'] ?? false,
              'image': friendData['image'] ?? 'assets/logo/img3.png',
            };
          }).toList();
        }
      }
    } catch (e) {
      print('Error fetching friends: $e');
    }
    return friends;
  }

  Future<List<Map<String, dynamic>>> fetchUserGroups(String phoneNumber) async {
    try {
      // Fetch user document with minimal fields to speed up retrieval.
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get(GetOptions(source: Source.cache)); // Try cache first

      if (!userDoc.exists) {
        logger.e("User document not found for phone: $phoneNumber");
        return [];
      }

      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      final groupsMap = data['groups'] as Map<String, dynamic>? ?? {};

      if (groupsMap.isEmpty) return [];

      // Fetch all group details in parallel
      final List<Future<Map<String, dynamic>>> groupFutures = groupsMap.entries.map((entry) async {
        final groupId = entry.key;
        final groupData = entry.value as Map<String, dynamic>? ?? {};
        final groupName = groupData['groupname'] ?? 'Unnamed Group';
        final splits = List<Map<String, dynamic>>.from(groupData['splits'] ?? []);
        final groupOwnerNumber = groupData['groupOwnerNumber'] as String? ?? '';
        final isGroupOwner = groupOwnerNumber == phoneNumber;

        double owedAmount = 0.0;
        List<String> avatars = [];

        for (var split in splits) {
          final avatar = split['avatar'] as String? ?? '';
          if (avatar.isNotEmpty) avatars.add(avatar);

          final splitValue = split['splitAmount'] ?? split['splitamount'];
          if (splitValue != null) {
            owedAmount += (splitValue is num) ? splitValue.toDouble() : double.tryParse(splitValue.toString()) ?? 0.0;
          }
        }

        return {
          'groupId': groupId,
          'groupName': groupName,
          'owedAmount': owedAmount,
          'avatars': avatars,
          'splits': splits,
          'isgroupowner': isGroupOwner,
        };
      }).toList();

      return await Future.wait(groupFutures);
    } catch (e, stackTrace) {
      logger.e("Error fetching user groups: $e", error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Fetches group data from the current user's Firestore document.
  Future<Map<String, dynamic>?> fetchGroupData(String phoneNumber, String groupId) async {
    try {
      // Try fetching from cache first for faster access
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get(const GetOptions(source: Source.cache));

      if (!userDoc.exists) {
        logger.e("User document not found for phone: $phoneNumber");
        return null;
      }

      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      final groupData = (data['groups'] as Map<String, dynamic>?)?[groupId];

      if (groupData == null) {
        logger.e("Group data not found for groupId: $groupId");
        return null;
      }

      return groupData as Map<String, dynamic>;
    } catch (e, stackTrace) {
      logger.e("Error fetching group details", error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Executes a transaction to “settle up” between the current user and the group owner.
  // Future<void> settleUp(String groupId, String currentUserPhone, Map<String, dynamic> groupData) async {
  //   final String? groupOwnerNumber = groupData['groupOwnerNumber'];
  //   if (groupOwnerNumber == null || groupOwnerNumber.isEmpty) {
  //     throw Exception("Group owner number is missing.");
  //   }
  //
  //   final DocumentReference userRef =
  //   FirebaseFirestore.instance.collection('users').doc(currentUserPhone);
  //   final DocumentReference ownerRef =
  //   FirebaseFirestore.instance.collection('users').doc(groupOwnerNumber);
  //
  //   try {
  //     await FirebaseFirestore.instance.runTransaction((transaction) async {
  //       final userSnapshot = await transaction.get(userRef);
  //       final ownerSnapshot = await transaction.get(ownerRef);
  //
  //       if (!userSnapshot.exists) throw Exception("User document not found.");
  //       if (!ownerSnapshot.exists) throw Exception("Group owner document not found.");
  //
  //       final userData = userSnapshot.data() as Map<String, dynamic>;
  //       final ownerData = ownerSnapshot.data() as Map<String, dynamic>;
  //
  //       // --- Update Current User Document ---
  //       if (userData.containsKey('groups') && userData['groups'][groupId] != null) {
  //         Map<String, dynamic> groupEntry =
  //         Map<String, dynamic>.from(userData['groups'][groupId]);
  //         if (groupEntry.containsKey('splits') && groupEntry['splits'] is List) {
  //           List<dynamic> splits = List<dynamic>.from(groupEntry['splits']);
  //           List<dynamic> updatedSplits = splits.map((split) {
  //             if (split is Map<String, dynamic> && split['phoneNumber'] == currentUserPhone) {
  //               split['splitAmount'] = 0;
  //             }
  //             return split;
  //           }).toList();
  //           groupEntry['splits'] = updatedSplits;
  //           Map<String, dynamic> groups = Map<String, dynamic>.from(userData['groups']);
  //           groups[groupId] = groupEntry;
  //           transaction.update(userRef, {'groups': groups});
  //         } else {
  //           throw Exception("Splits data not found in current user group.");
  //         }
  //
  //         if (userData.containsKey('friends') && userData['friends'] is Map) {
  //           Map<String, dynamic> friends = Map<String, dynamic>.from(userData['friends']);
  //           bool friendUpdated = false;
  //           friends.forEach((key, friend) {
  //             if (friend is Map<String, dynamic> && friend['phoneNumber'] == groupOwnerNumber) {
  //               friend['youOwe'] = 0;
  //               friendUpdated = true;
  //             }
  //           });
  //           if (friendUpdated) {
  //             transaction.update(userRef, {'friends': friends});
  //           } else {
  //             throw Exception("Group owner's friend entry not found in current user document.");
  //           }
  //         } else {
  //           throw Exception("Friends data not found in current user document.");
  //         }
  //       } else {
  //         throw Exception("Group data not found in current user's groups.");
  //       }
  //
  //       // --- Update Group Owner Document ---
  //       if (ownerData.containsKey('groups') && ownerData['groups'][groupId] != null) {
  //         Map<String, dynamic> groupEntryOwner =
  //         Map<String, dynamic>.from(ownerData['groups'][groupId]);
  //         if (groupEntryOwner.containsKey('splits') && groupEntryOwner['splits'] is List) {
  //           List<dynamic> splitsOwner = List<dynamic>.from(groupEntryOwner['splits']);
  //           List<dynamic> updatedSplitsOwner = splitsOwner.map((split) {
  //             if (split is Map<String, dynamic> && split['phoneNumber'] == currentUserPhone) {
  //               split['splitAmount'] = 0;
  //             }
  //             return split;
  //           }).toList();
  //           groupEntryOwner['splits'] = updatedSplitsOwner;
  //           Map<String, dynamic> groupsOwner = Map<String, dynamic>.from(ownerData['groups']);
  //           groupsOwner[groupId] = groupEntryOwner;
  //           transaction.update(ownerRef, {'groups': groupsOwner});
  //         } else {
  //           throw Exception("Splits data not found in group owner's group.");
  //         }
  //
  //         if (ownerData.containsKey('friends') && ownerData['friends'] is Map) {
  //           Map<String, dynamic> friendsOwner = Map<String, dynamic>.from(ownerData['friends']);
  //           bool friendUpdatedOwner = false;
  //           friendsOwner.forEach((key, friend) {
  //             if (friend is Map<String, dynamic> && friend['phoneNumber'] == currentUserPhone) {
  //               friend['theyOwe'] = 0;
  //               friendUpdatedOwner = true;
  //             }
  //           });
  //           if (friendUpdatedOwner) {
  //             transaction.update(ownerRef, {'friends': friendsOwner});
  //           } else {
  //             throw Exception("Current user's friend entry not found in group owner's document.");
  //           }
  //         } else {
  //           throw Exception("Friends data not found in group owner's document.");
  //         }
  //       } else {
  //         throw Exception("Group data not found in group owner's groups.");
  //       }
  //     });
  //   } catch (e, stackTrace) {
  //     logger.e("Error in settleUp", error: e, stackTrace: stackTrace);
  //     rethrow;
  //   }
  // }

  Future<void> settleUp(String groupId, String currentUserPhone, Map<String, dynamic> groupData) async {
    final String? groupOwnerNumber = groupData['groupOwnerNumber'];
    if (groupOwnerNumber == null || groupOwnerNumber.isEmpty) {
      throw Exception("Group owner number is missing.");
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference userRef = firestore.collection('users').doc(currentUserPhone);
    final DocumentReference ownerRef = firestore.collection('users').doc(groupOwnerNumber);

    try {
      await firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final ownerSnapshot = await transaction.get(ownerRef);

        if (!userSnapshot.exists || !ownerSnapshot.exists) {
          throw Exception("User or group owner document not found.");
        }

        final userData = userSnapshot.data() as Map<String, dynamic>;
        final ownerData = ownerSnapshot.data() as Map<String, dynamic>;

        void updateGroupAndFriends(Map<String, dynamic> data, String targetPhone, DocumentReference ref) {
          final groups = data['groups'] as Map<String, dynamic>? ?? {};
          final friends = data['friends'] as Map<String, dynamic>? ?? {};

          if (groups.containsKey(groupId)) {
            final groupEntry = groups[groupId] as Map<String, dynamic>? ?? {};
            final splits = (groupEntry['splits'] as List<dynamic>?)?.map((split) {
              if (split is Map<String, dynamic> && split['phoneNumber'] == targetPhone) {
                split['splitAmount'] = 0;
              }
              return split;
            }).toList();

            if (splits != null) {
              groupEntry['splits'] = splits;
              transaction.update(ref, {'groups.$groupId': groupEntry});
            }
          }

          if (friends.containsKey(targetPhone)) {
            final friendEntry = friends[targetPhone] as Map<String, dynamic>? ?? {};
            friendEntry[targetPhone == currentUserPhone ? 'theyOwe' : 'youOwe'] = 0;
            transaction.update(ref, {'friends.$targetPhone': friendEntry});
          }
        }

        updateGroupAndFriends(userData, currentUserPhone, userRef);
        updateGroupAndFriends(ownerData, currentUserPhone, ownerRef);
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
    final DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(phoneNumber);

    try {
      await userRef.set({
        'groups.$groupId.splits': splits,
        'groups.$groupId.history': FieldValue.arrayUnion([historyEntry]),
      }, SetOptions(merge: true));
    } catch (e, stackTrace) {
      logger.e("Error updating expense for group", error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update the friends map for expense sharing.
  Future<void> updateFriendsForExpense(
      String phoneNumber, List<dynamic> splits, double expensePerFriend) async {
    final DocumentReference userRef =
    FirebaseFirestore.instance.collection('users').doc(phoneNumber);

    try {
      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data() as Map<String, dynamic>? ?? {};
      final friendsMap = userData['friends'] as Map<String, dynamic>? ?? {};

      Map<String, dynamic> updatedFriends = {};

      for (var split in splits) {
        if (split is! Map<String, dynamic> || split['phoneNumber'] == null) continue;

        final contactPhone = split['phoneNumber'];
        final contactName = split['name'] ?? 'Unknown';
        final existingOwe = double.tryParse(friendsMap[contactPhone]?['theyOwe']?.toString() ?? '0') ?? 0.0;

        updatedFriends['friends.$contactPhone'] = {
          'name': contactName,
          'phoneNumber': contactPhone,
          'theyOwe': (existingOwe + expensePerFriend).toStringAsFixed(2),
        };
      }

      if (updatedFriends.isNotEmpty) {
        await userRef.update(updatedFriends);
      }
    } catch (e, stackTrace) {
      logger.e("Error updating friends for expense", error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

}
