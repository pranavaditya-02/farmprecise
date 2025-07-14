import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CropPlanningScreen extends StatefulWidget {
  @override
  _CropPlanningScreenState createState() => _CropPlanningScreenState();
}

class _CropPlanningScreenState extends State<CropPlanningScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
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

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateCropPlan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_apiKey.isEmpty) {
      _showErrorDialog('API Configuration Error', 
          'Please add GEMINI_API_KEY to your .env file');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final response = await _callGeminiAPI(
        "Generate a comprehensive crop planning schedule for $_selectedCrop in ${_locationController.text}. "
        "Farm details: Size: ${_farmSizeController.text} acres, Soil type: $_soilType, Season: $_season. "
        "Please provide detailed information including:\n"
        "1. Optimal planting dates and timeline\n"
        "2. Soil preparation requirements\n"
        "3. Fertilizer schedule with specific quantities\n"
        "4. Irrigation plan and water requirements\n"
        "5. Pest management strategies\n"
        "6. Expected harvest timing and yield\n"
        "7. Market considerations and pricing\n"
        "Additional notes: ${_additionalNotesController.text}. "
        "Format the response in a clear, structured manner suitable for farmers."
      );

      setState(() {
        _result = response;
        _isLoading = false;
      });
      
      _animationController.forward();
      
      // Auto-scroll to result
      await Future.delayed(Duration(milliseconds: 300));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      setState(() {
        _result = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      _showErrorDialog('Generation Error', e.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedResult(String content) {
    // Parse and format the content for better readability
    final sections = _parseContent(content);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with plan summary
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.agriculture,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crop Planning Report',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$_selectedCrop • ${_farmSizeController.text} acres • $_season season',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'AI Generated',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Quick stats cards
        _buildQuickStatsRow(),
        
        SizedBox(height: 24),
        
        // Main content sections
        ...sections.map((section) => _buildContentSection(section)).toList(),
        
        SizedBox(height: 24),
        
        // Action buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Location', _locationController.text, Icons.location_on)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Soil Type', _soilType, Icons.landscape)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Season', _season, Icons.calendar_today)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE8F5E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF4CAF50), size: 20),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(Map<String, dynamic> section) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  section['icon'] as IconData,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section['title'] as String,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: SelectableText(
              section['content'] as String,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF424242),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _saveOrExportPlan(),
                  icon: Icon(Icons.download, size: 20),
                  label: Text('Export Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sharePlan(),
                  icon: Icon(Icons.share, size: 20),
                  label: Text('Share Plan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF4CAF50),
                    side: BorderSide(color: Color(0xFF4CAF50)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _generateNewPlan(),
            icon: Icon(Icons.refresh, size: 20),
            label: Text('Generate New Plan'),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF4CAF50),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _parseContent(String content) {
    // Simple content parsing - in a real app, you'd want more sophisticated parsing
    final sections = <Map<String, dynamic>>[];
    final lines = content.split('\n');
    
    String currentSection = '';
    String currentContent = '';
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      // Check if line looks like a section header
      if (line.contains('1.') || line.contains('2.') || line.contains('3.') ||
          line.contains('4.') || line.contains('5.') || line.contains('6.') ||
          line.contains('7.') || line.toLowerCase().contains('planting') ||
          line.toLowerCase().contains('fertilizer') || line.toLowerCase().contains('irrigation') ||
          line.toLowerCase().contains('harvest') || line.toLowerCase().contains('pest')) {
        
        // Save previous section if exists
        if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
          sections.add(_createSection(currentSection, currentContent));
        }
        
        currentSection = line;
        currentContent = '';
      } else {
        currentContent += line + '\n';
      }
    }
    
    // Add the last section
    if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
      sections.add(_createSection(currentSection, currentContent));
    }
    
    // If no sections were parsed, return the whole content as one section
    if (sections.isEmpty) {
      sections.add({
        'title': 'Crop Planning Recommendations',
        'content': content,
        'icon': Icons.agriculture,
      });
    }
    
    return sections;
  }

  Map<String, dynamic> _createSection(String title, String content) {
    IconData icon = Icons.agriculture;
    
    if (title.toLowerCase().contains('plant')) {
      icon = Icons.eco;
    } else if (title.toLowerCase().contains('fertilizer')) {
      icon = Icons.science;
    } else if (title.toLowerCase().contains('irrigation') || title.toLowerCase().contains('water')) {
      icon = Icons.water_drop;
    } else if (title.toLowerCase().contains('harvest')) {
      icon = Icons.grass;
    } else if (title.toLowerCase().contains('pest')) {
      icon = Icons.bug_report;
    } else if (title.toLowerCase().contains('market') || title.toLowerCase().contains('price')) {
      icon = Icons.trending_up;
    }
    
    return {
      'title': title,
      'content': content.trim(),
      'icon': icon,
    };
  }

  void _saveOrExportPlan() {
    // Implement save/export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality will be implemented'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _sharePlan() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality will be implemented'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _generateNewPlan() {
    setState(() {
      _result = '';
      _animationController.reset();
    });
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
          'maxOutputTokens': 2000,
          'topP': 0.9,
          'topK': 40
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      try {
        return data['candidates'][0]['content']['parts'][0]['text'];
      } catch (e) {
        return 'Error parsing response: $e';
      }
    } else {
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
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Smart Crop Planning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero section
              _buildHeroSection(),
              SizedBox(height: 24),
              
              // Input forms
              _buildInputSection(),
              SizedBox(height: 24),
              
              // Generate button
              _buildGenerateButton(),
              SizedBox(height: 32),
              
              // Results section
              if (_result.isNotEmpty)
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                        child: _buildFormattedResult(_result),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.agriculture,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'AI-Powered Crop Planning',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Get personalized farming recommendations based on your location, soil type, and season',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        _buildInputCard([
          _buildDropdownField(
            'Select Crop',
            _selectedCrop,
            _crops,
            (value) => setState(() => _selectedCrop = value!),
            Icons.eco,
          ),
          SizedBox(height: 20),
          _buildTextFormField(
            'Farm Location',
            _locationController,
            'Enter your farm location (city, state)',
            Icons.location_on,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your farm location';
              }
              return null;
            },
          ),
        ]),
        
        SizedBox(height: 16),
        
        _buildInputCard([
          LayoutBuilder(
            builder: (context, constraints) {
              // Use Column layout for small screens, Row for larger screens
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    _buildDropdownField(
                      'Soil Type',
                      _soilType,
                      _soilTypes,
                      (value) => setState(() => _soilType = value!),
                      Icons.landscape,
                    ),
                    SizedBox(height: 16),
                    _buildDropdownField(
                      'Season',
                      _season,
                      _seasons,
                      (value) => setState(() => _season = value!),
                      Icons.calendar_today,
                    ),
                  ],
                );
              } else {
                return Row(
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
                    SizedBox(width: 16),
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
                );
              }
            },
          ),
          SizedBox(height: 20),
          _buildTextFormField(
            'Farm Size',
            _farmSizeController,
            'Enter area in acres',
            Icons.square_foot,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter farm size';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
        ]),
        
        SizedBox(height: 16),
        
        _buildInputCard([
          _buildTextFormField(
            'Additional Notes',
            _additionalNotesController,
            'Any specific requirements, local conditions, or concerns',
            Icons.notes,
            maxLines: 3,
          ),
        ]),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generateCropPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[300],
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
                  SizedBox(width: 12),
                  Text(
                    'Generating Your Plan...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Generate Crop Plan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
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
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Color(0xFF4CAF50)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            filled: true,
            fillColor: Color(0xFFFAFAFA),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            color: Color(0xFFFAFAFA),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFF4CAF50)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}