import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AddFriendPage extends StatefulWidget {
  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isPermissionGranted = false;
  bool _isLoading = false;
  String _errorMessage = '';
  Set<Contact> _selectedContacts = Set();

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    PermissionStatus permission = await Permission.contacts.request();

    print('Permission status: ${permission.isGranted}, ${permission.isDenied}, ${permission.isPermanentlyDenied}');

    if (permission.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      await _loadContacts();
    } else if (permission.isDenied) {
      setState(() {
        _errorMessage = 'Permission denied. Please allow access to contacts.';
      });
    } else if (permission.isPermanentlyDenied) {
      // Ensure the dialog is displayed after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showPermissionDialog() {
    print('Permission is permanently denied, showing dialog...');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Permission Denied'),
          content: Text('Please go to your app settings and enable the contacts permission.'),
          actions: <Widget>[
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Iterable<Contact> contacts = await ContactsService.getContacts();
      setState(() {
        _contacts = contacts.toList();
        _filteredContacts = _contacts;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load contacts. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Search Contacts',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (query) {
          setState(() {
            _filteredContacts = _contacts
                .where((contact) =>
            contact.displayName != null &&
                contact.displayName!.toLowerCase().contains(query.toLowerCase()))
                .toList();
          });
        },
      ),
    );
  }

  Widget _buildContactGrid() {
    return _filteredContacts.isEmpty
        ? Center(child: Text('No contacts found.'))
        : GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.8,
      ),
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final isSelected = _selectedContacts.contains(contact);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedContacts.remove(contact);
              } else {
                _selectedContacts.add(contact);
              }
            });
          },
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: isSelected
                  ? BorderSide(color: Colors.blue, width: 2)
                  : BorderSide.none,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: contact.avatar != null && contact.avatar!.isNotEmpty
                            ? MemoryImage(contact.avatar!)
                            : AssetImage('assets/logo/img2.png'), // Use your default image
                        child: contact.avatar == null
                            ? Icon(Icons.person, size: 30, color: Colors.white)
                            : null,
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        contact.displayName ?? 'Unnamed Contact',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator());
  }

  Future<void> _saveSelectedContacts() async {
    if (_selectedContacts.isEmpty) {
      return;
    }

    try {
      // Get the current user's phone number (Assume user is logged in)
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in';
        });
        return;
      }

      String userPhoneNumber = user.phoneNumber ?? '';

      Map<String, Map<String, String>> friendsMap = {};
      for (Contact contact in _selectedContacts) {
        String contactPhone = contact.phones?.isNotEmpty ?? false
            ? contact.phones?.first.value ?? ''
            : '';
        if (contactPhone.isNotEmpty) {
          friendsMap[contact.displayName ?? 'Unknown'] = {
            'name': contact.displayName ?? 'Unknown',
            'phoneNumber': contactPhone,
            'theyOwe':'',
            'youOwed':'',
          };
        }
      }

      if (friendsMap.isEmpty) {
        return;
      }

      // Adding a timeout to check if Firestore takes too long
      final timeout = Duration(seconds: 10);  // Adjust this time as needed

      // Start the Firestore operation with a timeout
      await FirebaseFirestore.instance.collection('users').doc(userPhoneNumber).set(
        {
          'friends': friendsMap,
        },
        SetOptions(merge: true),
      ).timeout(timeout, onTimeout: () {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save contacts. Timeout occurred.';
        });
        return;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friends added successfully!')),
      );

      Navigator.pop(context);  // Go back to the previous screen

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save contacts: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Friends'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (_isPermissionGranted)
              _isLoading
                  ? Expanded(child: _buildLoading())
                  : Expanded(
                child: Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(child: _buildContactGrid()),
                  ],
                ),
              )
            else
              Center(child: Text(_errorMessage.isEmpty ? 'Loading...' : _errorMessage)),
            if (_selectedContacts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _saveSelectedContacts,
                  child: Text('Proceed (${_selectedContacts.length})'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}