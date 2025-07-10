import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CropPlanningScreen extends StatefulWidget {
  @override
  _CropPlanningScreenState createState() => _CropPlanningScreenState();
}

class _CropPlanningScreenState extends State<CropPlanningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  
  String _selectedCrop = 'Rice';
  String _soilType = 'Loamy';
  String _season = 'Kharif';
  bool _isLoading = false;
  String _result = '';

  final List<String> _crops = [
    'Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane', 
    'Tomato', 'Potato', 'Onion', 'Soybean', 'Mustard'
  ];
  
  final List<String> _soilTypes = [
    'Loamy', 'Clay', 'Sandy', 'Silt', 'Peat', 'Chalk'
  ];
  
  final List<String> _seasons = ['Kharif', 'Rabi', 'Zaid'];

  // Replace with your actual Google Gemini API key
  final String _apiKey = 'AIzaSyCJJ1esglN4bxEtSGHN7a0tGCEHE4nG-cQ';

  Future<void> _generateCropPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final response = await _callGeminiAPI(
        "Generate a detailed crop planning schedule for $_selectedCrop in ${_locationController.text}. "
        "Farm details: Size: ${_farmSizeController.text} acres, Soil type: $_soilType, Season: $_season. "
        "Include planting dates, fertilizer schedule, irrigation plan, and harvest timing. "
        "Additional notes: ${_additionalNotesController.text}. "
        "Please provide a comprehensive farming guide with specific recommendations."
      );

      setState(() {
        _result = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Add this method to display formatted AI response
  Widget _buildFormattedContent(String content) {
    return SelectableText(
      content,
      style: TextStyle(
        fontSize: 15,
        color: Colors.black87,
        height: 1.5,
      ),
    );
  }

  // Helper method to build info chips for quick info bar
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF4CAF50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Color(0xFF388E3C)),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF388E3C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _callGeminiAPI(String prompt) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': _apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': prompt
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1000,
          'topP': 0.9,
          'topK': 40
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Debug: Print the response structure
      print('Gemini API Response: ${response.body}');
      
      // Extract text from Gemini API response with detailed debugging
      try {
        // Check if response has candidates
        if (data['candidates'] == null) {
          print('No candidates found in response');
          return 'Error: No candidates in API response';
        }
        
        if (data['candidates'].isEmpty) {
          print('Candidates array is empty');
          return 'Error: Empty candidates array';
        }
        
        final candidate = data['candidates'][0];
        print('First candidate: $candidate');
        
        // Check if candidate has content
        if (candidate['content'] == null) {
          print('No content found in candidate');
          return 'Error: No content in candidate';
        }
        
        final content = candidate['content'];
        print('Content: $content');
        
        // Check if content has parts
        if (content['parts'] == null) {
          print('No parts found in content');
          return 'Error: No parts in content';
        }
        
        if (content['parts'].isEmpty) {
          print('Parts array is empty');
          return 'Error: Empty parts array';
        }
        
        final part = content['parts'][0];
        print('First part: $part');
        
        // Check if part has text
        if (part['text'] == null) {
          print('No text found in part');
          return 'Error: No text in part';
        }
        
        final text = part['text'];
        print('Extracted text: $text');
        
        return text;
        
      } catch (e) {
        print('Error parsing response: $e');
        print('Full response data: $data');
        return 'Error parsing response: $e';
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        return 'API Error (${response.statusCode}): $errorMessage';
      } catch (e) {
        return 'HTTP Error (${response.statusCode}): ${response.body}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Planning'),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFFF1F8E9),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.agriculture, size: 50, color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          'Smart Crop Planning',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Get AI-powered planting schedules',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 25),
                
                // Form Fields
                _buildInputCard([
                  _buildDropdownField(
                    'Select Crop',
                    _selectedCrop,
                    _crops,
                    (value) => setState(() => _selectedCrop = value!),
                    Icons.eco,
                  ),
                  SizedBox(height: 15),
                  _buildTextFormField(
                    'Location',
                    _locationController,
                    'Enter your farm location',
                    Icons.location_on,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter location';
                      }
                      return null;
                    },
                  ),
                ]),
                
                SizedBox(height: 20),
                
                _buildInputCard([
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          'Soil Type',
                          _soilType,
                          _soilTypes,
                          (value) => setState(() => _soilType = value!),
                          Icons.landscape,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: _buildDropdownField(
                          'Season',
                          _season,
                          _seasons,
                          (value) => setState(() => _season = value!),
                          Icons.calendar_today,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  _buildTextFormField(
                    'Farm Size (acres)',
                    _farmSizeController,
                    'Enter farm size in acres',
                    Icons.square_foot,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter farm size';
                      }
                      return null;
                    },
                  ),
                ]),
                
                SizedBox(height: 20),
                
                _buildInputCard([
                  _buildTextFormField(
                    'Additional Notes (Optional)',
                    _additionalNotesController,
                    'Any specific requirements or conditions',
                    Icons.note,
                    maxLines: 3,
                  ),
                ]),
                
                SizedBox(height: 30),
                
                // Generate Button
                Container(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateCropPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Generating Plan...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Generate Crop Plan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Result Card
                if (_result.isNotEmpty)
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [Colors.white, Color(0xFFF8FFF8)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with enhanced styling
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.agriculture, color: Colors.white, size: 28),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'AI-Generated Crop Planning Schedule',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Powered by Gemini',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // Formatted content
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFFE0E0E0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Quick Info Bar
                                Row(
                                  children: [
                                    _buildInfoChip(Icons.eco, 'Crop: $_selectedCrop'),
                                    SizedBox(width: 8),
                                    _buildInfoChip(Icons.landscape, 'Soil: $_soilType'),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildInfoChip(Icons.calendar_today, 'Season: $_season'),
                                    SizedBox(width: 8),
                                    _buildInfoChip(Icons.square_foot, 'Size: ${_farmSizeController.text} acres'),
                                  ],
                                ),
                                SizedBox(height: 20),
                                
                                // Formatted AI Response
                                Container(
                                  width: double.infinity,
                                  child: _buildFormattedContent(_result),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Add functionality to save or share
                                  },
                                  icon: Icon(Icons.save_alt, size: 18),
                                  label: Text('Save Plan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Add functionality to share
                                  },
                                  icon: Icon(Icons.share, size: 18),
                                  label: Text('Share'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Color(0xFF4CAF50),
                                    side: BorderSide(color: Color(0xFF4CAF50)),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTextFormField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Color(0xFF4CAF50)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF4CAF50)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            filled: true,
            fillColor: Color(0xFFF8F9FA),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Color(0xFFF8F9FA),
            border: Border.all(color: Color(0xFF4CAF50)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFF4CAF50)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}