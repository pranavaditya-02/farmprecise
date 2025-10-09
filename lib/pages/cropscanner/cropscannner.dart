import 'dart:convert';
import 'package:flutter/material.dart';  
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:farmprecise/components/bottom_navigation.dart';
import 'package:farmprecise/components/custom_appbar.dart';
import 'package:farmprecise/components/custom_drawer.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CropScannerScreen extends StatefulWidget {
  @override
  _CropScannerScreenState createState() => _CropScannerScreenState();
}

class _CropScannerScreenState extends State<CropScannerScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
Map<String, dynamic>? _diseaseData;
  int _selectedIndex = 0;
  Map<String, dynamic> _diseaseDetails = {};
  
  // Description related variables
  final TextEditingController _descriptionController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _selectedLanguage = 'en_US'; // Default language
  
  // Available languages for speech recognition
  final Map<String, String> _languages = {
    'en_US': 'English',
    'hi_IN': 'Hindi',
    'ta_IN': 'Tamil',
    'te_IN': 'Telugu',
    'kn_IN': 'Kannada',
    'ml_IN': 'Malayalam',
    'bn_IN': 'Bengali',
    'gu_IN': 'Gujarati',
    'mr_IN': 'Marathi',
    'pa_IN': 'Punjabi',
  };

  String _selectedCrop = 'Cotton'; // Default selected crop
  final List<String> _crops = ['Cotton', 'Corn', 'Paddy', 'SugarCane'];

  // Map to store model and label paths for each crop
  final Map<String, Map<String, String>> _modelPaths = {
    'Cotton': {
      'model': 'assets/cotton_model.tflite',
      'labels': 'assets/cotton_labels.txt'
    },
    'Corn': {
      'model': 'assets/Corn_Model.tflite',
      'labels': 'assets/Corn_Labels.txt'
    },
    'Paddy': {
      'model': 'assets/rice_model.tflite',
      'labels': 'assets/rice_labels.txt'
    },
    'SugarCane': {
      'model': 'assets/sugarcane.tflite',
      'labels': 'assets/sugarcane_labels.txt'
    },
  };

  @override
  void initState() {
    super.initState();
    _loadModel(_selectedCrop);
    _loadDiseaseDetails();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Initialize speech recognition
  void _initializeSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize();
    if (!available) {
      print("Speech recognition not available");
    }
  }

  // Start/Stop listening for speech
  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _descriptionController.text = result.recognizedWords;
            });
          },
          localeId: _selectedLanguage,
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          onSoundLevelChange: (level) {},
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _loadDiseaseDetails() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/diseasedata.json');
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

  /// Load the TFLite model based on selected crop
  Future<void> _loadModel(String crop) async {
    Tflite.close(); // Close any previously loaded model
    try {
      final modelPath = _modelPaths[crop]?['model'];
      final labelPath = _modelPaths[crop]?['labels'];

      if (modelPath == null || labelPath == null) {
        print("Model paths not found for crop: $crop");
        return;
      }

      String? result = await Tflite.loadModel(
        model: modelPath,
        labels: labelPath,
      );

      if (result != null) {
        print("Model loaded successfully for $crop: $result");
      } else {
        print("Failed to load model for $crop");
      }
    } catch (e) {
      print("Failed to load model for $crop: $e");
    }
  }

  /// Predict the disease based on the image
  Future<void> _predictDisease(File image) async {
    try {
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 0.0,
        imageStd: 255.0,
        numResults: 5,
        threshold: 0.5,
        asynch: true,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        String detectedLabel = recognitions[0]['label'] ?? 'Unknown';
        double confidence = (recognitions[0]['confidence'] ?? 0.0) * 100;

        // Check if the detected object is not a crop
        if (detectedLabel.contains('Human_Men') ||
            detectedLabel.contains('Human_Women') ||
            detectedLabel.contains('Vehicle') ||
            detectedLabel.contains('Weeds')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ $detectedLabel - Oops! Invalid image detected. Please upload a clear crop image for disease detection🌱📸',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red.withOpacity(0.7),
              duration: Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              margin: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Clear the disease data and selected image
          setState(() {
            _diseaseData = null;
            _selectedImage = null;
          });

          return;
        }

        setState(() {
  _diseaseData = {
    'Crop Type': _selectedCrop,
    'Disease Name': _diseaseDetails[detectedLabel]?['Disease Name'] ??
        detectedLabel,
    'Cause': _diseaseDetails[detectedLabel]?['Cause'] ?? 'N/A',
    'Details': _diseaseDetails[detectedLabel]?['Details'] ?? 'N/A',
    'Solutions (Organic)': _diseaseDetails[detectedLabel]
            ?['Solutions (Traditional)'] ??
        'N/A',
    'Solutions (Inorganic)':
        _diseaseDetails[detectedLabel]?['Solutions (Modern)'] ?? 'N/A',
    'Recommended Manures':
        _diseaseDetails[detectedLabel]?['Recommended Manures'] ?? 'N/A',
    'Recommended Fertilizers': _diseaseDetails[detectedLabel]
            ?['Recommended Fertilizers'] ??
        'N/A',
      'Product Links': _diseaseDetails[detectedLabel]?['Product Links'],
    'Nearby Shops': _diseaseDetails[detectedLabel]?['Nearby Shops'],
    'Additional Info':
        _diseaseDetails[detectedLabel]?['Additional Info'] ?? 'N/A',
    'Confidence': '${confidence.toStringAsFixed(2)}%',
    
  };
});

      } else {
        setState(() {
          _diseaseData = {
            'Crop Type': _selectedCrop,
            'Disease Name': 'Unknown',
            'User Description': _descriptionController.text.isNotEmpty 
                ? _descriptionController.text 
                : 'No description provided',
            'Confidence': 'N/A'
          };
        });
      }
    } catch (e) {
      print("Error while predicting disease: $e");
      setState(() {
        _diseaseData = {
          'Crop Type': _selectedCrop,
          'Disease Name': 'Error',
          'User Description': _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : 'No description provided',
          'Confidence': 'N/A'
        };
      });
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
          _diseaseData = null;
        });
      }
    }
  }

  /// Submit image for prediction
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

    await _predictDisease(_selectedImage!);
  }

  /// Handles navigation item selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildResultCard(String key, dynamic value) {
  if (key == 'Product Links' && value is Map && value.isNotEmpty) {
    return _buildProductLinksSection(value);
  } else if (key == 'Nearby Shops' && value is Map && value.isNotEmpty) {
    return _buildNearbyShopsSection(value);
  } else if (value is String) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$key:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            value,
            style: TextStyle(fontSize: 16.0),
          ),
        ],
      ),
    );
  }
  return SizedBox.shrink();
}

Widget _buildProductLinksSection(Map productLinks) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Links:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: Colors.green[800],
          ),
        ),
        SizedBox(height: 8.0),
        ...productLinks.entries.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: InkWell(
            onTap: () {
              print('Opening link: ${entry.value}');
            },
            child: Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart, color: Colors.blue[600], size: 20),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      '${entry.key}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Icon(Icons.open_in_new, color: Colors.blue[600], size: 16),
                ],
              ),
            ),
          ),
        )),
      ],
    ),
  );
}

Widget _buildNearbyShopsSection(Map nearbyShops) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nearby Shops:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: Colors.green[800],
          ),
        ),
        SizedBox(height: 8.0),
        ...nearbyShops.entries.map((entry) {
          final shopData = entry.value as Map;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, color: Colors.green[600], size: 20),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          shopData['name'] ?? 'Unknown Shop',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                      SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          shopData['location'] ?? 'Location not available',
                          style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.0),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.grey[600], size: 16),
                      SizedBox(width: 4.0),
                      InkWell(
                        onTap: () {
                          print('Calling: ${shopData['mobile']}');
                        },
                        child: Text(
                          shopData['mobile'] ?? 'No contact',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.blue[700],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
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
              
              // Description Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description (Optional)',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Describe any symptoms or issues you notice with your crop',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 12.0),
                      
                      // Language selection
                      Row(
                        children: [
                          Text(
                            'Language: ',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                isDense: true,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedLanguage = newValue;
                                    });
                                  }
                                },
                                items: _languages.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(fontSize: 14.0),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0),
                      
                      // Text field with voice input
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Describe the crop condition, symptoms, or any concerns...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14.0,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(12.0),
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8.0),
                                onTap: _toggleListening,
                                child: Container(
                                  padding: EdgeInsets.all(12.0),
                                  child: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none,
                                    color: _isListening ? Colors.red : Colors.green,
                                    size: 24.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isListening)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mic,
                                color: Colors.red,
                                size: 16.0,
                              ),
                              SizedBox(width: 4.0),
                              Text(
                                'Listening... Speak now in ${_languages[_selectedLanguage]}',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
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
                          (entry) => _buildResultCard(entry.key, entry.value),
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
