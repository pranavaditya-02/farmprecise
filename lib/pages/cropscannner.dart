import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:farmprecise/components/bottom_navigation.dart';
import 'package:farmprecise/components/custom_appbar.dart';
import 'package:farmprecise/components/custom_drawer.dart';

class CropScannerScreen extends StatefulWidget {
  @override
  _CropScannerScreenState createState() => _CropScannerScreenState();
}

class _CropScannerScreenState extends State<CropScannerScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, String>? _diseaseData;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  /// Load the TFLite model
  Future<void> _loadModel() async {
    Tflite.close();
    try {
      String? result = await Tflite.loadModel(
        model: "assets/cotton_model.tflite",
        labels: "assets/cotton_labels.txt",
      );
      print(result);
      if (result != null) {
        print("Model loaded successfully: $result");
      } else {
        print("Failed to load model.");
      }
    } catch (e) {
      print("failed to load image : $e");
    }
  }

  /// Dispose of TFLite resources
  @override
  void dispose() {
    super.dispose();
  }

  /// Predict the disease based on the image
  Future<void> _predictDisease(File image) async {
    try {
      // Running the model on the input image
      var recognitions = await Tflite.runModelOnImage(
        path: image.path, // Path to the image
        imageMean: 0.0, // Default normalization
        imageStd: 255.0, // Default normalization
        numResults: 5, // Maximum number of predictions
        threshold: 0.5, // Confidence threshold
        asynch: true,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        // Format the output
        var formattedData = recognitions.map((recognition) {
          return {
            'index':
                recognition['index'] ?? -1, // Default to -1 if index is missing
            'label': recognition['label'] ?? 'Unknown',
            'confidence': recognition['confidence'] ?? 0.0,
          };
        }).toList();

        // Logging formatted data
        print("Formatted data: $formattedData");

        setState(() {
          // Assuming we display the first recognition result for simplicity
          _diseaseData = {
            'Index': formattedData[0]['index'].toString(),
            'Disease Name': formattedData[0]['label'],
            'Confidence':
                (formattedData[0]['confidence'] * 100).toStringAsFixed(2) + '%',
          };
        });
      } else {
        setState(() {
          _diseaseData = {'Disease Name': 'Unknown', 'Confidence': 'N/A'};
        });
      }
    } catch (e) {
      print("Error while predicting disease: $e");
      setState(() {
        _diseaseData = {'Disease Name': 'Error', 'Confidence': 'N/A'};
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Pick an image from the gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      if (await image.exists()) {
        print("Image exists at path: ${image.path}");
        setState(() {
          _selectedImage = image;
          _diseaseData = null; // Reset disease data when a new image is picked
        });
      } else {
        print("Image does not exist at path: ${image.path}");
      }
    }
  }

  /// Submit image for prediction
  void _submitImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    await _predictDisease(_selectedImage!);
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
                  'Upload a Photo to Detect Crop Diseases',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                          'No Image Selected',
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
                      style: TextStyle(color: Colors.green),
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
                      style: TextStyle(color: Colors.green),
                    ),
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
