import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'friends_screen.dart';
import 'ProfilePage.dart';
import 'groupsPage.dart';
import 'home_page.dart';

class BottomNavigationMainScreen extends StatefulWidget {
  @override
  _BottomNavigationMainScreenState createState() =>
      _BottomNavigationMainScreenState();
}

class _BottomNavigationMainScreenState
    extends State<BottomNavigationMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomePage(),
    GroupsPage(),
    FriendsScreen(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: _selectedIndex == 1 || _selectedIndex == 2 ||  _selectedIndex == 3// Hide for Groups and Friends
            ? null // No app bar
            : AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Split_wise.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {},
              tooltip: 'Profile',
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: _screens[_selectedIndex],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[500]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home, 0),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.search, 1),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.notifications, 2),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person, 3),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background square with slight downward shift
            if (_selectedIndex == index)
              Transform.translate(
                offset: Offset(1, 8), // Adjust the Y-axis to move it down
                child: Container(
                  width: 65, // Slightly larger than the main square
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF00C6FB),
                        Color(0xFFFFF176), // Ending color of the gradient
                      ],
                      begin: Alignment.topLeft, // Start the gradient from the top left
                      end: Alignment.bottomRight, // End the gradient at the bottom right
                    ),
                    borderRadius: BorderRadius.circular(20), // Matches the rounded corners
                  ),
                ),
              ),
            // Main square
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _selectedIndex == index ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: _selectedIndex == index ? Colors.white : Colors.black,
                size: 25,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getNavLabel(index),
          style: TextStyle(
            color: _selectedIndex == index ? Colors.black : Colors.grey,
            fontSize: 10,
            fontFamily: 'interBold',
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _getNavLabel(int index) {
    switch (index) {
      case 0:
        return 'HOME';
      case 1:
        return 'Groups';
      case 2:
        return 'Friends';
      case 3:
        return 'PROFILE';
      default:
        return '';
    }
  }
}
