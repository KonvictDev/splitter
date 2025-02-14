import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'phone_auth/phone_auth_screen.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/logo/img3.png'),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text('John Doe',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'interBold')),
              Text('+123 456 7890',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'interRegular')),
              SizedBox(height: 20),
              _buildProfileOption(context, Icons.people, 'Splitzo Score with Friends'),
              _buildProfileOption(context, Icons.qr_code, 'Scan Code / Add Friend'),
              Divider(
                thickness: 2,
                indent: 18,
                endIndent: 18,
              ),
              _buildProfileOption(context, Icons.diamond, 'Splitzo Pro', isPremium: true),
              Divider(
                thickness: 2,
                indent: 18,
                endIndent: 18,
              ),
              _buildSectionHeader('Preferences'),
              _buildProfileOption(context, Icons.notifications, 'Device & Push Notifications'),
              _buildProfileOption(context, Icons.phone_android, 'Phone Settings'),
              Divider(
                thickness: 2,
                indent: 18,
                endIndent: 18,
              ),
              _buildSectionHeader('Feedback & Support'),
              _buildProfileOption(context, Icons.star, 'Rate Splitzo'),
              _buildProfileOption(context, Icons.support, 'Contact Support'),
              Divider(
                thickness: 2,
                indent: 18,
                endIndent: 18,
              ),
              _buildProfileOption(context, Icons.logout, 'Logout', isLogout: true),
              SizedBox(height: 20),
              Text('© 2025 Splitzo. All rights reserved.',
                  style: TextStyle(
                      color: Colors.grey, fontFamily: 'interRegular')),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title,
      {bool isPremium = false, bool isLogout = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isPremium ? Colors.orange : (isLogout ? Colors.red : Colors.blue),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'interSemiBold'),
      ),
      onTap: () async {
        if (isLogout) {
          // Sign out from Firebase Auth
          await FirebaseAuth.instance.signOut();
          // Navigate to the PhoneAuthPage (or your login screen)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PhoneAuthPage()),
          );
        } else {
          // Handle other profile option taps if needed
        }
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.grey[600],
            fontFamily: 'interExtraBold'),
      ),
    );
  }
}
