import 'dart:ui';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitter/groupCreationPage.dart'; // Ensure this import is correct
import 'package:splitter/provider/balanceProvider.dart';
import 'package:splitter/repository/GroupRepository.dart';
import 'Constants/AppConstants.dart';

class HomePage extends ConsumerStatefulWidget  {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GroupRepository _groupsRepository = GroupRepository();
  String? _errorMessage;

  Future<void> _fetchBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber?.isEmpty ?? true) {
      setState(() {
        _errorMessage = 'User not logged in or phone number missing.';
      });
      return;
    }

    final String userPhone = user!.phoneNumber!;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_groupsRepository.normalizePhone(userPhone))
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'User document not found.';
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final Map<String, dynamic> friends = data['friends'] as Map<String, dynamic>? ?? {};

      double totalTheyOwe = 0.0;
      double totalYouOwe = 0.0;

      friends.forEach((key, friend) {
        if (friend is Map<String, dynamic>) {
          totalTheyOwe += ((friend['theyOwe'] ?? 0) as num).toDouble();
          totalYouOwe += ((friend['youOwe'] ?? 0) as num).toDouble();
        }
      });

      double balance = totalTheyOwe - totalYouOwe;

      // Ensure balance is not negative
      if (balance < 0) {
        balance = 0;
      }
      ref.read(balanceProvider.notifier).updateBalance(balance, totalTheyOwe, totalYouOwe);
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Firebase error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching balance: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(balanceProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.025,
              left: 0,
              right: 0,
              child: _buildSecondaryCard(context),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(context, balanceState.balance),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.26,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard('YOU OWE', 'You should pay to others', balanceState.youOwe, 'assets/icons/debit.png'),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey,
                  ),
                  _buildSummaryCard('YOU OWED', 'Others should pay to you', balanceState.theyOwe, 'assets/icons/credit.png'),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5,
              left: 0,
              right: 0,
              child: _buildUpgradePlanSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.16,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6FB), Color(0xFFFFF176)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  fontFamily: 'interRegular',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.00, end: balance),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Text(
                    "\₹${value.toStringAsFixed(2)}",
                    style: AppConstants.titleStyle,
                  );
                },
              ),
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
    return GestureDetector(
      onTap: () {
        // Navigate to GroupCreationPage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GroupCreationPage()),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.2,
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
        child: const Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            '+ ADD EXPENSE',
            style: TextStyle(
              fontFamily: 'interBold',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String description, double amount, String imagePath) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          Image.asset(imagePath, height: 40, width: 40),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontFamily: 'interBold', fontWeight: FontWeight.bold)),
          Text(description, style: const TextStyle(fontFamily: 'interRegular', fontSize: 8)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.00, end: amount),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Text(
                  "\₹${value.toStringAsFixed(2)}",
                  style: const TextStyle(fontFamily: 'interBold', fontSize: 16, color: Colors.black),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePlanSection() {
    return Column(
      children: [
        const Center(
          child: Text(
            "You've reached your monthly expense limit. Upgrade your plan",
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'interSemiBold',
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () {
              // Add your navigation or action logic here
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF27BDB5), Color(0xFF27BDB5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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
    );
  }
}