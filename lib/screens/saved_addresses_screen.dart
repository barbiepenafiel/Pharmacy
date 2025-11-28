import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'address_map_view_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      setState(() => _isLoading = true);
      final loadedAddresses = await _firebaseService.getUserAddresses();
      setState(() {
        addresses = loadedAddresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading addresses: $e')));
      }
    }
  }

  // Region 11 (Davao Region) Cities for dropdown
  final List<String> _region11Cities = [
    'Davao City',
    'Tagum City',
    'Panabo City',
    'Island Garden City of Samal (IGACOS)',
    'Digos City',
    'Mati City',
    'Asuncion',
    'Braulio E. Dujali',
    'Carmen',
    'Kapalong',
    'New Corella',
    'San Isidro',
    'Santo Tomas',
    'Talaingod',
    'Bansalan',
    'Hagonoy',
    'Kiblawan',
    'Magsaysay',
    'Malalag',
    'Matanao',
    'Padada',
    'Santa Cruz',
    'Sulop',
    'Banaybanay',
    'Baganga',
    'Boston',
    'Caraga',
    'Cateel',
    'Governor Generoso',
    'Lupon',
    'Manay',
    'San Isidro (Davao Oriental)',
    'Tarragona',
  ];

  void _showAddressDialog({Map<String, dynamic>? address}) {
    final typeController = TextEditingController(text: address?['type'] ?? '');
    final addressController = TextEditingController(
      text: address?['address'] ?? '',
    );
    final phoneController = TextEditingController(
      text: address?['phone'] ?? '',
    );

    // Extract city from full city string if editing
    String selectedCity = 'Davao City';
    if (address != null && address['city'] != null) {
      final cityText = address['city'] as String;
      for (var city in _region11Cities) {
        if (cityText.toLowerCase().contains(city.toLowerCase())) {
          selectedCity = city;
          break;
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(address == null ? 'Add Address' : 'Edit Address'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Address Type',
                      hintText: 'e.g., Home, Work, Mom\'s House',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                      hintText: 'Building, Street, Barangay',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'City/Municipality',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    isExpanded: true,
                    items: _region11Cities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(
                          city,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCity = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+63 917 123 4567',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Extract navigator and messenger BEFORE async operations
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  if (address == null) {
                    // Add new address
                    await _firebaseService.addAddress({
                      'type': typeController.text,
                      'address': addressController.text,
                      'city': '$selectedCity, Region 11',
                      'phone': phoneController.text,
                      'isDefault': false,
                    });
                  } else {
                    // Update existing address
                    await _firebaseService.updateAddress(address['id'], {
                      'type': typeController.text,
                      'address': addressController.text,
                      'city': '$selectedCity, Region 11',
                      'phone': phoneController.text,
                    });
                  }

                  // Reload addresses
                  await _loadAddresses();

                  // Use stored navigator and messenger (no context needed)
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        address == null
                            ? 'Address added successfully'
                            : 'Address updated successfully',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  nav.pop();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error saving address: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  nav.pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressOnMap(Map<String, dynamic> address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressMapViewScreen(address: address),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressDialog(),
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Saved Addresses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add an address to save for future orders',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: address['isDefault']
                          ? Colors.teal.shade700
                          : Colors.grey.shade200,
                      width: address['isDefault'] ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  address['type'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (address['isDefault'])
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Default',
                                      style: TextStyle(
                                        color: Colors.teal.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Text('Edit'),
                                  onTap: () =>
                                      _showAddressDialog(address: address),
                                ),
                                PopupMenuItem(
                                  child: const Text('Delete'),
                                  onTap: () async {
                                    try {
                                      await _firebaseService.deleteAddress(
                                        address['id'],
                                      );
                                      await _loadAddresses();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Address deleted successfully',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error deleting address: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                if (!address['isDefault'])
                                  PopupMenuItem(
                                    child: const Text('Set as Default'),
                                    onTap: () async {
                                      try {
                                        await _firebaseService
                                            .setDefaultAddress(address['id']);
                                        await _loadAddresses();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Default address updated',
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error setting default: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          address['address'],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address['city'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address['phone'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showAddressOnMap(address),
                                icon: const Icon(Icons.map),
                                label: const Text('View on Map'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
