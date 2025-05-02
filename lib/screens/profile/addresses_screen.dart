import 'package:gudmerchant/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressModel {
  final String id;
  final String name;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.isDefault = false,
  });

  String get fullAddress => '$street, $city, $state $zipCode, $country';

  // In a real app, you would have methods to convert to/from database format
}

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({Key? key}) : super(key: key);

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  // Example addresses
  List<AddressModel> _addresses = [
    AddressModel(
      id: '1',
      name: 'Home',
      street: '123 Main St',
      city: 'New York',
      state: 'NY',
      zipCode: '10001',
      country: 'United States',
      isDefault: true,
    ),
    AddressModel(
      id: '2',
      name: 'Work',
      street: '456 Market St',
      city: 'San Francisco',
      state: 'CA',
      zipCode: '94103',
      country: 'United States',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        elevation: 0,
      ),
      body: _addresses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                return _buildAddressCard(_addresses[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditAddressDialog();
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No addresses found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an address to make checkout faster',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showAddEditAddressDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            title: Row(
              children: [
                Text(
                  address.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                address.fullAddress,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
              radius: 22,
              child: Icon(
                Icons.location_on,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit Button
                TextButton.icon(
                  onPressed: () {
                    _showAddEditAddressDialog(existingAddress: address);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                
                // Set as Default Button
                if (!address.isDefault)
                  TextButton.icon(
                    onPressed: () {
                      _setAsDefault(address.id);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Set as Default'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                
                // Delete Button
                TextButton.icon(
                  onPressed: () {
                    _confirmDeleteAddress(address);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(String addressId) {
    setState(() {
      for (var i = 0; i < _addresses.length; i++) {
        if (_addresses[i].id == addressId) {
          _addresses[i] = AddressModel(
            id: _addresses[i].id,
            name: _addresses[i].name,
            street: _addresses[i].street,
            city: _addresses[i].city,
            state: _addresses[i].state,
            zipCode: _addresses[i].zipCode,
            country: _addresses[i].country,
            isDefault: true,
          );
        } else if (_addresses[i].isDefault) {
          _addresses[i] = AddressModel(
            id: _addresses[i].id,
            name: _addresses[i].name,
            street: _addresses[i].street,
            city: _addresses[i].city,
            state: _addresses[i].state,
            zipCode: _addresses[i].zipCode,
            country: _addresses[i].country,
            isDefault: false,
          );
        }
      }
    });
    
    Get.snackbar(
      'Default Address',
      'Address has been set as default',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _confirmDeleteAddress(AddressModel address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.name}" address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteAddress(address.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAddress(String addressId) {
    setState(() {
      _addresses.removeWhere((address) => address.id == addressId);
    });
    
    Get.snackbar(
      'Address Deleted',
      'Address has been removed',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showAddEditAddressDialog({AddressModel? existingAddress}) {
    final isEditing = existingAddress != null;
    final formKey = GlobalKey<FormState>();
    
    final nameController = TextEditingController(text: existingAddress?.name ?? '');
    final streetController = TextEditingController(text: existingAddress?.street ?? '');
    final cityController = TextEditingController(text: existingAddress?.city ?? '');
    final stateController = TextEditingController(text: existingAddress?.state ?? '');
    final zipCodeController = TextEditingController(text: existingAddress?.zipCode ?? '');
    final countryController = TextEditingController(text: existingAddress?.country ?? 'United States');
    
    bool makeDefault = existingAddress?.isDefault ?? _addresses.isEmpty;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Address Name',
                          hintText: 'e.g., Home, Work',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an address name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: streetController,
                        decoration: const InputDecoration(
                          labelText: 'Street Address',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a street address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: stateController,
                              decoration: const InputDecoration(
                                labelText: 'State',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: zipCodeController,
                              decoration: const InputDecoration(
                                labelText: 'ZIP Code',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: countryController,
                              decoration: const InputDecoration(
                                labelText: 'Country',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Set as default address'),
                        value: makeDefault,
                        activeColor: AppConstants.primaryColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            makeDefault = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (isEditing) {
                        _updateAddress(
                          existingAddress.id,
                          nameController.text,
                          streetController.text,
                          cityController.text,
                          stateController.text,
                          zipCodeController.text,
                          countryController.text,
                          makeDefault,
                        );
                      } else {
                        _addNewAddress(
                          nameController.text,
                          streetController.text,
                          cityController.text,
                          stateController.text,
                          zipCodeController.text,
                          countryController.text,
                          makeDefault,
                        );
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                  ),
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addNewAddress(
    String name,
    String street,
    String city,
    String state,
    String zipCode,
    String country,
    bool isDefault,
  ) {
    final newAddress = AddressModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      street: street,
      city: city,
      state: state,
      zipCode: zipCode,
      country: country,
      isDefault: isDefault,
    );
    
    setState(() {
      // If new address is default, update other addresses
      if (isDefault) {
        for (var i = 0; i < _addresses.length; i++) {
          if (_addresses[i].isDefault) {
            _addresses[i] = AddressModel(
              id: _addresses[i].id,
              name: _addresses[i].name,
              street: _addresses[i].street,
              city: _addresses[i].city,
              state: _addresses[i].state,
              zipCode: _addresses[i].zipCode,
              country: _addresses[i].country,
              isDefault: false,
            );
          }
        }
      }
      
      _addresses.add(newAddress);
    });
    
    Get.snackbar(
      'Address Added',
      'New address has been added',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _updateAddress(
    String id,
    String name,
    String street,
    String city,
    String state,
    String zipCode,
    String country,
    bool isDefault,
  ) {
    setState(() {
      // If this address is being set as default, update other addresses
      if (isDefault) {
        for (var i = 0; i < _addresses.length; i++) {
          if (_addresses[i].id != id && _addresses[i].isDefault) {
            _addresses[i] = AddressModel(
              id: _addresses[i].id,
              name: _addresses[i].name,
              street: _addresses[i].street,
              city: _addresses[i].city,
              state: _addresses[i].state,
              zipCode: _addresses[i].zipCode,
              country: _addresses[i].country,
              isDefault: false,
            );
          }
        }
      }
      
      // Update the address
      final index = _addresses.indexWhere((address) => address.id == id);
      if (index != -1) {
        _addresses[index] = AddressModel(
          id: id,
          name: name,
          street: street,
          city: city,
          state: state,
          zipCode: zipCode,
          country: country,
          isDefault: isDefault,
        );
      }
    });
    
    Get.snackbar(
      'Address Updated',
      'Address has been updated',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
} 