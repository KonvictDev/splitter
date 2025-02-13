import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import 'groupCreationPage.dart'; // Import GroupCreationPage

class FriendsPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedContacts;

  const FriendsPage({super.key, required this.selectedContacts});
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isPermissionGranted = false;
  bool _isLoading = false;
  String _errorMessage = '';
  Set<Contact> _selectedContacts = Set();  // Track selected contacts

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

    if (permission.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      await _loadContacts();
    } else if (permission.isDenied || permission.isPermanentlyDenied) {
      setState(() {
        _errorMessage = 'Permission denied. Please allow access to contacts.';
      });
      _showPermissionDeniedDialog();
    }

    setState(() {
      _isLoading = false;
    });
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
      // After loading contacts, check if any selected contacts exist
      _markSelectedContacts();
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
  void _markSelectedContacts() {
    for (var selectedContactData in widget.selectedContacts) {
      for (var contact in _contacts) {
        if (contact.displayName == selectedContactData['name'] &&
            contact.phones?.isNotEmpty == true &&
            contact.phones?.first.value == selectedContactData['phone']) {
          setState(() {
            _selectedContacts.add(contact); // Mark contact as selected
          });
          break; // Stop once we find a match for the contact
        }
      }
    }
  }


  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Required'),
          content: Text(
            'To display your contacts, please allow access to your contacts. '
                'You can enable it in the app settings.',
          ),
          actions: [
            TextButton(
              child: Text('Go to Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Search Contacts',
          labelStyle: TextStyle(color: Color(0xFF020202)),
          hintText: 'Type a name...',
          hintStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFDEDEDE), width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFDEDEDE), width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          prefixIcon: Icon(Icons.search, color: Colors.black),
          filled: true,
          fillColor: Color(0xFFDEDEDE),
        ),
        onChanged: (query) {
          setState(() {
            _filteredContacts = _contacts
                .where((contact) =>
            contact.displayName != null &&
                contact.displayName!
                    .toLowerCase()
                    .contains(query.toLowerCase()))
                .toList();
          });
        },
      ),
    );
  }

  Widget _buildContactGrid() {
    return _filteredContacts.isEmpty
        ? Center(
      child: Text(
        'No contacts found.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    )
        : GridView.builder(
      physics: BouncingScrollPhysics(),
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
                  ? BorderSide(color: Colors.teal, width: 2)
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
                        backgroundColor: _isValidImage(contact.avatar)
                            ? Colors.transparent
                            : Colors.grey.shade300,
                        backgroundImage: _isValidImage(contact.avatar)
                            ? MemoryImage(contact.avatar!)
                            : null,
                        child: _isValidImage(contact.avatar)
                            ? null
                            : Icon(Icons.person, size: 30, color: Colors.white),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        contact.displayName ?? 'Unnamed Contact',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isValidImage(Uint8List? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return false;
    }
    try {
      MemoryImage(avatar);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8.0),
            ),
            height: 50,
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.8,
              ),
              padding: const EdgeInsets.all(16.0),
              itemCount: 12,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[300],
                      ),
                      SizedBox(height: 8.0),
                      Container(
                        width: 80,
                        height: 16,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Text(
                          'Friends',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 48),
                      ],
                    ),
                  ),
                  if (_isPermissionGranted)
                    _isLoading
                        ? Expanded(child: _buildShimmerLoading())
                        : Expanded(
                      child: Column(
                        children: [
                          _buildSearchBar(),
                          Expanded(child: _buildContactGrid()),
                        ],
                      ),
                    )
                  else if (_errorMessage.isNotEmpty)
                    Expanded(child: Center(child: Text(_errorMessage))),
                ],
              ),
              if (_selectedContacts.isNotEmpty)
                Positioned(
                  bottom: 30.0,
                  left: 16.0,
                  right: 16.0,
                  child: ElevatedButton(
                    onPressed: () {
                      // Create list of selected contacts' data
                      List<Map<String, dynamic>> selectedContactsData = _selectedContacts.map((contact) {
                        return {
                          'name': contact.displayName ?? 'Unnamed Contact',
                          'phone': contact.phones?.isNotEmpty == true ? contact.phones!.first.value : 'No phone',
                          'avatar': contact.avatar ?? Uint8List(0), // Pass avatar as Uint8List
                        };
                      }).toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupCreationPage(
                            selectedContacts: selectedContactsData,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: Text(
                      'Proceed (${_selectedContacts.length})',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
