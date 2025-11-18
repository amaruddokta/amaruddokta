import 'package:amar_uddokta/myuddokta/Controllers/AdminDeliveryFeeController.dart';
import 'package:amar_uddokta/myuddokta/data/location_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDeliveryFeeScreen extends StatefulWidget {
  const AdminDeliveryFeeScreen({super.key});

  @override
  State<AdminDeliveryFeeScreen> createState() => _AdminDeliveryFeeScreenState();
}

class _AdminDeliveryFeeScreenState extends State<AdminDeliveryFeeScreen> {
  final AdminDeliveryFeeController controller =
      Get.put(AdminDeliveryFeeController());

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _divisionController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _upazilaController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();

  String? _editingDocId;

  List<String> _divisions = [];
  List<String> _districts = [];
  List<String> _upazilas = [];

  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedUpazila;

  @override
  void initState() {
    super.initState();
    _divisions = locationData.keys.toList();
  }

  @override
  void dispose() {
    _divisionController.dispose();
    _districtController.dispose();
    _upazilaController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _divisionController.clear();
    _districtController.clear();
    _upazilaController.clear();
    _feeController.clear();
    setState(() {
      _editingDocId = null;
      _selectedDivision = null;
      _selectedDistrict = null;
      _selectedUpazila = null;
      _districts = [];
      _upazilas = [];
    });
  }

  void _editFee(Map<String, dynamic> feeData) {
    _selectedDivision = feeData['division'];
    _selectedDistrict = feeData['district'];
    _selectedUpazila = feeData['upazila'];

    _divisionController.text = _selectedDivision ?? '';
    _districtController.text = _selectedDistrict ?? '';
    _upazilaController.text = _selectedUpazila ?? '';
    _feeController.text = feeData['fee'].toString();

    _updateDistricts(_selectedDivision);
    _updateUpazilas(_selectedDivision, _selectedDistrict);

    setState(() {
      _editingDocId = feeData['id'];
    });
  }

  void _updateDistricts(String? division) {
    setState(() {
      _selectedDistrict = null;
      _selectedUpazila = null;
      _districts = [];
      _upazilas = [];
      if (division != null && locationData.containsKey(division)) {
        _districts = locationData[division]!.keys.toList();
      }
    });
  }

  void _updateUpazilas(String? division, String? district) {
    setState(() {
      _selectedUpazila = null;
      _upazilas = [];
      if (division != null &&
          district != null &&
          locationData.containsKey(division) &&
          locationData[division]!.containsKey(district)) {
        _upazilas = locationData[division]![district]!.keys.toList();
      }
    });
  }

  Future<void> _saveFee() async {
    if (_formKey.currentState!.validate()) {
      final division = _selectedDivision;
      final district = _selectedDistrict;
      final upazila = _selectedUpazila;
      final fee = double.parse(_feeController.text.trim());

      if (division == null) {
        Get.snackbar('Error', 'Please select a division');
        return;
      }

      if (_editingDocId == null) {
        await controller.addDeliveryFee(
          division: division,
          district: district,
          upazila: upazila,
          fee: fee,
        );
      } else {
        await controller.updateDeliveryFee(
          id: _editingDocId!,
          division: division,
          district: district,
          upazila: upazila,
          fee: fee,
        );
      }
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Delivery Fee Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDivision,
                    hint: const Text('Select Division'),
                    items: _divisions.map((String division) {
                      return DropdownMenuItem<String>(
                        value: division,
                        child: Text(division),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDivision = newValue;
                        _updateDistricts(newValue);
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a division' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDistrict,
                    hint: const Text('Select District (Optional)'),
                    items: _districts.map((String district) {
                      return DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDistrict = newValue;
                        _updateUpazilas(_selectedDivision, newValue);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUpazila,
                    hint: const Text('Select Upazila (Optional)'),
                    items: _upazilas.map((String upazila) {
                      return DropdownMenuItem<String>(
                        value: upazila,
                        child: Text(upazila),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedUpazila = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _feeController,
                    decoration: const InputDecoration(labelText: 'Fee'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter fee';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _saveFee,
                        child: Text(
                            _editingDocId == null ? 'Add Fee' : 'Update Fee'),
                      ),
                      if (_editingDocId != null)
                        ElevatedButton(
                          onPressed: _clearForm,
                          child: const Text('Cancel Edit'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: controller.deliveryFees.length,
                  itemBuilder: (context, index) {
                    final feeData = controller.deliveryFees[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                            '${feeData['division']} > ${feeData['district'] ?? 'All'} > ${feeData['upazila'] ?? 'All'}'),
                        subtitle: Text('Fee: ${feeData['fee']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editFee(feeData),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  controller.deleteDeliveryFee(feeData['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
