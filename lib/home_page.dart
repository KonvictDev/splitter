import 'dart:ui';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Secondary card placed in the background
            Positioned(
              top: MediaQuery.of(context).size.height * 0.025, // 2.5% of the screen height
              left: 0,
              right: 0,
              child: _buildSecondaryCard(context),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(context),
              ],
            ),
            // Summary cards directly below the secondary card
            Positioned(
              top: MediaQuery.of(context).size.height * 0.26, // Adjust to place below secondary card
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard('YOU OWE', 'You should pay to others','\₹562.72',  'assets/icons/debit.png'),
                  Container(
                    width: 1,
                    height: 50, // Adjust the height of the line based on your card's height
                    color: Colors.grey, // Color of the vertical line
                  ),
                  _buildSummaryCard('YOU OWED', 'Others should pay to you','\₹38,822.72',  'assets/icons/credit.png'),
                ],
              ),
            ),
      Positioned(
        top: MediaQuery.of(context).size.height * 0.5, // Further adjusted position for text and button
        left: 0,
        right: 0,
        child: Column(
          children: [
            const Center(
              child: Text(
                "You've reached your monthly expense limit. Upgrade your plan",
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'interSemiBold',
                  fontSize: 14,
                ),
                textAlign: TextAlign.center, // Ensures the text itself is centered
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () {
                  // Add your navigation or action logic here
                },
                child: Container(
                  width: double.infinity, // Make the button span the screen width
                  margin: const EdgeInsets.symmetric(horizontal: 16), // Add margin for spacing
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [   Color(0xFF27BDB5),
                        Color(0xFF27BDB5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center the icon and text
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(
                        Icons.arrow_forward, // Replace with your preferred icon
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'VIEW PLANS',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'interSemiBold',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),


      ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double cardHeight = screenHeight * 0.16;

    return Container(
      width: MediaQuery.of(context).size.width,
      height: cardHeight,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00C6FB),
            Color(0xFFFFF176),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 8),
              Text(
                'Total Balance',
                style: TextStyle(
                  fontFamily: 'interRegular',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '\$76,256.91',
                style: TextStyle(
                  fontFamily: 'interBold',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
          Image.asset(
            'assets/logo/splitzoWhite.png',
            width: 60,
            height: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCard(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double cardHeight = screenHeight * 0.2;

    return Container(
      width: MediaQuery.of(context).size.width,
      height: cardHeight,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: const Text(
          '+ ADD EXPENSE',
          style: TextStyle(
            fontFamily: 'interBold',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String description, String amount, String imagePath) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            imagePath,
            height: 40, // Adjust the size of the image
            width: 40,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontFamily: 'interBold', fontWeight: FontWeight.bold),
          ),
          Text(
            description,
            style: const TextStyle(fontFamily: 'interRegular', fontSize: 8),
          ),
          const SizedBox(height: 15 ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
            ),
            child: Text(
              amount,
              style: const TextStyle(fontFamily: 'interBold', fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

}
