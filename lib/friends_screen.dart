import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitter/addFriendsPage.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Map<String, dynamic>> friends = [];

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String phoneNumber = user.phoneNumber!; // Get authenticated user's phone number

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('friends')) {
          Map<String, dynamic> friendsMap = data['friends'];
          List<Map<String, dynamic>> friendList = friendsMap.entries.map((entry) {
            Map<String, dynamic> friendData = entry.value;
            return {
              'name': friendData['name'] ?? 'Unknown',
              'date': friendData['date'] ?? 'N/A',
              'amount': friendData['theyOwe'] ?? 0.00,
              'isOwed': friendData['isOwed'] ?? false,
              'image': friendData['image'] ?? 'assets/logo/img3.png',
            };
          }).toList();

          setState(() {
            friends = friendList;
          });
        }
      }
    } catch (e) {
      print('Error fetching friends: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Friends',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  IconButton(
                    icon: Icon(Icons.person_add, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddFriendPage()),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Summary',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                '\$126,00',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _tabButton('Overall', true),
                    _tabButton('I owe', false),
                    _tabButton('Owns me', false),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: friends.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(friend['image']),
                      ),
                      title: Text(friend['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(friend['date'], style: TextStyle(color: Colors.grey)),
                      trailing: Text(
                        '\$${(friend['amount'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: friend['isOwed'] ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _tabButton(String title, bool isSelected) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [Color(0xFF00C6FB), Color(0xFFFFF176)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
