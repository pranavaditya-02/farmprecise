import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:farmprecise/components/bottom_navigation.dart';
import 'package:farmprecise/components/custom_appbar.dart';
import 'package:farmprecise/components/custom_drawer.dart';
import 'package:flutter/services.dart' show rootBundle;

class CropScannerScreen extends StatefulWidget {
  @override
  _CropScannerScreenState createState() => _CropScannerScreenState();
}

class _CropScannerScreenState extends State<CropScannerScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, String>? _diseaseData;
  int _selectedIndex = 0;
  Map<String, dynamic> _diseaseDetails = {};

  String _selectedCrop = 'Cotton'; // Default selected crop
  final List<String> _crops = ['Cotton', 'Corn', 'Paddy', 'SugarCane'];

  @override
  void initState() {
    super.initState();
    _loadDiseaseDetails();
  }

  Future<void> _loadDiseaseDetails() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/diseasedata.json');
      setState(() {
        _diseaseDetails = json.decode(jsonString);
      });
    } catch (e) {
      print("Error loading disease details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load disease details: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Pick an image from the gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      if (await image.exists()) {
        setState(() {
          _selectedImage = image;
          // Show sample disease data when image is selected
          _showSampleDiseaseData();
        });
      }
    }
  }

  /// Show sample disease data from JSON
  void _showSampleDiseaseData() {
    if (_diseaseDetails.isNotEmpty) {
      // Get first disease entry for the selected crop as sample
      final sampleDisease = _diseaseDetails.entries.first;
      setState(() {
        _diseaseData = {
          'Crop Type': _selectedCrop,
          'Disease Name': sampleDisease.value['Disease Name'] ?? 'Sample Disease',
          'Cause': sampleDisease.value['Cause'] ?? 'Sample Cause',
          'Details': sampleDisease.value['Details'] ?? 'Sample Details',
          'Solutions (Traditional)': sampleDisease.value['Solutions (Traditional)'] ?? 'Sample Traditional Solutions',
          'Solutions (Modern)': sampleDisease.value['Solutions (Modern)'] ?? 'Sample Modern Solutions',
          'Recommended Manures': sampleDisease.value['Recommended Manures'] ?? 'Sample Manures',
          'Recommended Fertilizers': sampleDisease.value['Recommended Fertilizers'] ?? 'Sample Fertilizers',
          'Additional Info': sampleDisease.value['Additional Info'] ?? 'Sample Additional Info',
          'Confidence': '95.5%', // Sample confidence score
        };
      });
    }
  }

  /// Submit image for showing sample data
  void _submitImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Please select an image first.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.orange.withOpacity(0.8),
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.white,
              width: 1.5,
            ),
          ),
          margin: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showSampleDiseaseData();
  }

  /// Handles navigation item selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Dummy method for crop model loading (can be expanded for actual ML model integration)
  void _loadModel(String cropName) {
    // For now, just reload disease details or perform any crop-specific logic if needed.
    // You can implement actual model loading logic here if required.
    _loadDiseaseDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: CustomDrawer(onItemTapped: _onItemTapped),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Select a crop to identify potential diseases :',
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCrop,
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue != _selectedCrop) {
                            setState(() {
                              _selectedCrop = newValue;
                              _diseaseData = null; // Clear previous results
                            });
                            _loadModel(newValue); // Load new model
                          }
                        },
                        items:
                            _crops.map<DropdownMenuItem<String>>((String crop) {
                          return DropdownMenuItem<String>(
                            value: crop,
                            child: Text(crop),
                          );
                        }).toList(),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16.0,
                        ),
                        dropdownColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        _selectedImage!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Center(
                        child: Text(
                          'Upload a photo to detect crop diseases.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt, color: Colors.green),
                    label:
                        Text('Camera', style: TextStyle(color: Colors.green)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, color: Colors.green),
                    label:
                        Text('Gallery', style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _submitImage,
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 20.0),
              if (_diseaseData != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disease Information',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.0),
                        ..._diseaseData!.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                    color: Colors.green[800],
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  entry.value,
                                  style: TextStyle(fontSize: 16.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 1,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
