import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:farmprecise/components/bottom_navigation.dart';
import 'package:farmprecise/components/custom_appbar.dart';
import 'package:farmprecise/components/custom_drawer.dart';

class CropScannerScreen extends StatefulWidget {
  @override
  _CropScannerScreenState createState() => _CropScannerScreenState();
}

class _CropScannerScreenState extends State<CropScannerScreen> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  Map<String, String>? _diseaseData;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can upload a maximum of 5 images.')),
      );
      return;
    }

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
        _diseaseData = null; // Reset disease data when a new image is picked
      });
    }
  }

  void _submitImages() {
    if (_selectedImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least 3 images.')),
      );
      return;
    }

    setState(() {
      // Simulate disease detection (You can replace this with real logic)
      _diseaseData = {
        'Disease Name': 'Bacterial Leaf Blight',
        'Cause':
            'Caused by the bacterium Xanthomonas oryzae, which infects the plant tissue and leads to leaf lesions.',
        'Details': 'Bacterial leaf blight is caused by Xanthomonas oryzae.',
        'Solutions (Traditional)':
            'Use resistant varieties, ensure proper drainage, and avoid over-irrigation.',
        'Solutions (Modern)':
            'Use copper-based bactericides and adopt AI-based disease monitoring systems.',
        'Recommended Manures': 'Cow dung compost, green manure.',
        'Recommended Fertilizers': 'Nitrogen-rich fertilizers like urea.',
        'Additional Info':
            'Commonly affects paddy crops during humid conditions. It spreads through water splashes and infected seeds.',
      };
    });
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
              Center(
                child: Text(
                  'Upload Photos to Detect Crop Diseases',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20.0),
              _selectedImages.isNotEmpty
                  ? Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: _selectedImages.map((image) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                image,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.remove(image);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    )
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Center(
                        child: Text(
                          'No Images Selected',
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
                    icon: Icon(
                      Icons.camera_alt,
                      color: Colors.green,
                    ),
                    label: Text(
                      'Camera',
                      style: TextStyle(
                          color:
                              Colors.green), // Set the desired text color here
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(
                      Icons.photo_library,
                      color: Colors.green,
                    ),
                    label: Text(
                      'Gallery',
                      style: TextStyle(
                          color:
                              Colors.green), // Set the desired text color here
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _submitImages,
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Button background color
                  foregroundColor: Colors.white, // Text color
                ),
              ),
              SizedBox(height: 20.0),
              _diseaseData != null
                  ? Card(
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.key}:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            4.0), // Add spacing between key and value
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        'No Disease Data Available',
                        style: TextStyle(fontSize: 16.0),
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
