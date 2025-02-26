import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For compute()
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';

import 'groupCreationPage.dart';

class FriendsPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedContacts;

  const FriendsPage({Key? key, required this.selectedContacts}) : super(key: key);
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isPermissionGranted = false;
  bool _isLoading = false;
  String _errorMessage = '';
  Set<String> _selectedContactKeys = {};

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _initializeSelectedContactKeys();
  }

  void _initializeSelectedContactKeys() {
    for (var selected in widget.selectedContacts) {
      String key = '${selected['name']}|${selected['phone']}';
      _selectedContactKeys.add(key);
    }
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
    } else {
      setState(() {
        _errorMessage = 'Permission denied. Please allow access to contacts.';
      });
      _showPermissionDeniedDialog();
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Load contacts and then offload heavy post-processing (i.e. marking selected contacts) to a background isolate.
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load contacts without thumbnails for performance.
      Iterable<Contact> contactsIterable = await ContactsService.getContacts(withThumbnails: false);
      List<Contact> contactsList = contactsIterable.toList();

      // Offload the matching process to a background isolate.
      // We pass both the contacts list and the preselected data.
      List<Contact> processedContacts = await compute(_markSelectedContacts, {
        'contacts': contactsList,
        'selectedData': widget.selectedContacts,
      });

      setState(() {
        _contacts = processedContacts;
        _filteredContacts = processedContacts;
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

  // This static function runs in an isolate.
  // It uses a Set for quick lookup of preselected contacts.
  static List<Contact> _markSelectedContacts(Map<String, dynamic> data) {
    List<Contact> contacts = List<Contact>.from(data['contacts']);
    List<Map<String, dynamic>> selectedData = List<Map<String, dynamic>>.from(data['selectedData']);

    // Create a set of keys from selected contacts for fast lookup.
    Set<String> selectedKeys = selectedData
        .map((sc) => '${sc['name']}|${sc['phone']}')
        .toSet();

    // For demonstration, we’ll “mark” a contact as selected by using a custom property.
    // Since Contact is from a package and may be immutable, you can instead return a list
    // of contacts that are selected or maintain a separate mapping.
    // Here, we simply print out which contacts are preselected.
    for (var contact in contacts) {
      String key = '${contact.displayName ?? ''}|${contact.phones?.isNotEmpty == true ? contact.phones!.first.value : ''}';
      if (selectedKeys.contains(key)) {
        // In a real scenario, you might want to wrap Contact in your own model that includes a 'selected' flag.
        // For now, we assume that marking means you know which ones are selected.
        // Example: print("Selected: ${contact.displayName}");
      }
    }
    return contacts;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'To display your contacts, please allow access to your contacts. '
                'You can enable it in the app settings.',
          ),
          actions: [
            TextButton(
              child: const Text('Go to Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<Uint8List> getDefaultAvatar() async {

    // List of default avatar asset paths
    final List<String> defaultAvatarPaths = [
      'assets/logo/img.png',
      'assets/logo/img2.png',
      'assets/logo/img3.png',
    ];

    final random = Random();

    // Pick a random path from the list
    final randomPath = defaultAvatarPaths[random.nextInt(defaultAvatarPaths.length)];
    final ByteData data = await rootBundle.load(randomPath);

    return data.buffer.asUint8List();
  }

  // Example search bar (omitted for brevity)
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Search Contacts',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFDEDEDE),
        ),
        onChanged: (query) {
          setState(() {
            _filteredContacts = _contacts.where((contact) {
              return (contact.displayName ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase());
            }).toList();
          });
        },
      ),
    );
  }

  // Lazy loading is implemented here using GridView.builder.
  // It builds only the visible items.
  Widget _buildContactGrid() {
    if (_filteredContacts.isEmpty) {
      return const Center(
        child: Text(
          'No contacts found.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.8,
      ),
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        String key = '${contact.displayName ?? ''}|${contact.phones?.isNotEmpty == true ? contact.phones!.first.value : ''}';
        final isSelected = _selectedContactKeys.contains(key);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedContactKeys.remove(key);
              } else {
                _selectedContactKeys.add(key);
              }
            });
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: isSelected
                  ? const BorderSide(color: Colors.teal, width: 2)
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
                        backgroundColor: contact.avatar != null && contact.avatar!.isNotEmpty
                            ? Colors.transparent
                            : Colors.grey.shade300,
                        backgroundImage: (contact.avatar != null && contact.avatar!.isNotEmpty)
                            ? MemoryImage(contact.avatar!)
                            : null,
                        child: (contact.avatar == null || contact.avatar!.isEmpty)
                            ? const Icon(Icons.person, size: 30, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        contact.displayName ?? 'Unnamed Contact',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.check, color: Colors.teal, size: 16),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            height: 50,
            color: Colors.grey[300],
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.8,
              ),
              padding: const EdgeInsets.all(16.0),
              itemCount: 12,
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(radius: 30, backgroundColor: Colors.grey[300]),
                      const SizedBox(height: 8.0),
                      Container(width: 80, height: 16, color: Colors.grey[300]),
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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Friends',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(width: 48),
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
            if (_selectedContactKeys.isNotEmpty)
              Positioned(
                bottom: 30.0,
                left: 16.0,
                right: 16.0,
                child: ElevatedButton(
                  onPressed: () async {
                    List<Map<String, dynamic>> selectedContactsData =
                    await Future.wait(
                      _contacts
                          .where((contact) {
                        String key =
                            '${contact.displayName ?? ''}|${contact.phones?.isNotEmpty == true ? contact.phones!.first.value : ''}';
                        return _selectedContactKeys.contains(key);
                      })
                          .map((contact) async {
                        // Load default avatar if needed.
                        final avatarBytes = (contact.avatar == null ||
                            contact.avatar!.isEmpty)
                            ? await getDefaultAvatar()
                            : contact.avatar;
                        return {
                          'name': contact.displayName ?? 'Unnamed Contact',
                          'phone': contact.phones?.isNotEmpty == true
                              ? contact.phones!.first.value
                              : 'No phone',
                          'avatar': avatarBytes,
                        };
                      })
                          .toList(),
                    );

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: Text(
                    'Proceed (${_selectedContactKeys.length})',
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
