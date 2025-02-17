import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitter/addFriendsPage.dart';
import 'package:splitter/repository/GroupRepository.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final GroupRepository _groupsRepository = GroupRepository();
  List<Map<String, dynamic>> friends = [];
  bool _isLoading = true; // Added loading flag

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    friends = await _groupsRepository.fetchFriends();
    setState(() {
      _isLoading = false;
    });
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
              // Header Row with title and add friend button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Friends',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
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
              // Summary section
              Text(
                'Summary',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                '\$126,00',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(height: 16),
              // Tab Buttons (UI for filtering, not functional in this snippet)
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
              // Friends List or Loading/Empty state
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : friends.isEmpty
                    ? Center(child: Text("No friends found!"))
                    : ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                        AssetImage(friend['image']),
                      ),
                      title: Text(friend['name'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(friend['date'],
                          style: TextStyle(color: Colors.grey)),
                      trailing: Text(
                        '\$${(friend['amount'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: friend['isOwed']
                              ? Colors.green
                              : Colors.red,
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

  // Tab button widget
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
