import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as markdown;

import 'dart:math' as math;

class CropPlanningScreen extends StatefulWidget {
  final String? selectedCropName; // Add this parameter

  const CropPlanningScreen({Key? key, this.selectedCropName}) : super(key: key);
  @override
  _CropPlanningScreenState createState() => _CropPlanningScreenState();
}

class TableBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  TableBuilder(this.context);

  @override
  Widget? visitElementAfter(
      markdown.Element element, TextStyle? preferredStyle) {
    if (element.tag != 'table') return null;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
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
          // Scroll indicator
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.swipe, size: 16, color: Color(0xFF666666)),
                SizedBox(width: 8),
                Text(
                  'Swipe left/right to view all columns',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Spacer(),
                Icon(Icons.table_chart, size: 16, color: Color(0xFF4CAF50)),
              ],
            ),
          ),
          // Enhanced horizontal scrollable table
          Container(
            height: _calculateTableHeight(element),
            child: Scrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              controller: ScrollController(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Container(
                  // Ensure minimum width for proper scrolling
                  constraints: BoxConstraints(
                    minWidth: _calculateMinTableWidth(element),
                  ),
                  child: _buildEnhancedTable(element),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTableHeight(markdown.Element element) {
    int rowCount = 0;

    for (var child in element.children ?? []) {
      if (child.tag == 'thead' || child.tag == 'tbody') {
        for (var row in child.children ?? []) {
          if (row.tag == 'tr') rowCount++;
        }
      } else if (child.tag == 'tr') {
        rowCount++;
      }
    }

    // Header row (60px) + data rows (80px each) + padding
    return math.min(400.0, (rowCount * 80.0) + 100);
  }

  double _calculateMinTableWidth(markdown.Element element) {
    int maxColumns = 0;

    for (var child in element.children ?? []) {
      if (child.tag == 'thead' || child.tag == 'tbody') {
        for (var tableRow in child.children ?? []) {
          if (tableRow.tag == 'tr') {
            int columnCount = tableRow.children
                    ?.where((c) => c.tag == 'td' || c.tag == 'th')
                    .length ??
                0;
            maxColumns = math.max(maxColumns, columnCount);
          }
        }
      } else if (child.tag == 'tr') {
        int columnCount = child.children
                ?.where((c) => c.tag == 'td' || c.tag == 'th')
                .length ??
            0;
        maxColumns = math.max(maxColumns, columnCount);
      }
    }

    // Minimum 180px per column for better readability
    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedWidth = maxColumns * 180.0;

    // Ensure table is at least 1.2x screen width for proper scrolling
    return math.max(calculatedWidth, screenWidth * 1.2);
  }

  // Fix for the _buildEnhancedTable method in your CropPlanningScreen

  Widget _buildEnhancedTable(markdown.Element element) {
    List<List<String>> tableData = [];
    bool hasHeader = false;

    // Parse table structure
    for (var child in element.children ?? []) {
      if (child.tag == 'thead') {
        hasHeader = true;
        for (var row in child.children ?? []) {
          if (row.tag == 'tr') {
            tableData.add(_extractRowData(row));
          }
        }
      } else if (child.tag == 'tbody') {
        for (var row in child.children ?? []) {
          if (row.tag == 'tr') {
            tableData.add(_extractRowData(row));
          }
        }
      } else if (child.tag == 'tr') {
        // Fix: Use 'child' instead of 'row' since 'row' is not defined in this scope
        tableData.add(_extractRowData(child));
      }
    }

    if (tableData.isEmpty) return Container();

    // Calculate column count and normalize data
    int maxColumns = tableData.fold<int>(
        0, (max, row) => row.length > max ? row.length : max);

    // Ensure all rows have the same number of columns
    for (var row in tableData) {
      while (row.length < maxColumns) {
        row.add('');
      }
    }

    return DataTable(
      border: TableBorder(
        horizontalInside: BorderSide(color: Color(0xFFE8E8E8), width: 0.5),
        verticalInside: BorderSide(color: Color(0xFFE8E8E8), width: 0.5),
      ),
      headingRowColor: MaterialStateProperty.all(Color(0xFFF8F9FA)),
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32),
        fontSize: 14,
      ),
      dataTextStyle: TextStyle(
        color: Color(0xFF424242),
        fontSize: 13,
      ),
      // Enhanced spacing for better mobile experience
      columnSpacing: 20,
      horizontalMargin: 0,
      headingRowHeight: 60,
      dataRowHeight: 80,
      // Enable row selection for better UX
      showCheckboxColumn: false,
      columns: _buildEnhancedDataColumns(
          tableData.isNotEmpty ? tableData.first : [], hasHeader, maxColumns),
      rows: _buildEnhancedDataRows(tableData, hasHeader),
    );
  }

  List<String> _extractRowData(markdown.Element row) {
    List<String> rowData = [];
    for (var cell in row.children ?? []) {
      if (cell.tag == 'td' || cell.tag == 'th') {
        String cellText = cell.textContent.trim();
        // Handle long text by adding line breaks for better mobile display
        if (cellText.length > 30) {
          cellText = cellText.replaceAll(RegExp(r'(.{30})'), '\n');
        }
        rowData.add(cellText);
      }
    }
    return rowData;
  }

  List<DataColumn> _buildEnhancedDataColumns(
      List<String> headerRow, bool hasHeader, int columnCount) {
    // Fixed column width for consistent scrolling
    double columnWidth = 160.0;

    if (!hasHeader || headerRow.isEmpty) {
      // Generate generic column headers if no header exists
      return List.generate(
        headerRow.isEmpty ? columnCount : headerRow.length,
        (index) => DataColumn(
          label: Container(
            width: columnWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_rows, size: 16, color: Color(0xFF4CAF50)),
                SizedBox(height: 4),
                Text(
                  'Col ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return headerRow
        .map((header) => DataColumn(
              label: Container(
                width: columnWidth,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      header,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  List<DataRow> _buildEnhancedDataRows(
      List<List<String>> tableData, bool hasHeader) {
    // Skip header row if it exists
    List<List<String>> dataRows = hasHeader && tableData.isNotEmpty
        ? tableData.skip(1).toList()
        : tableData;

    double columnWidth = 160.0;

    return dataRows.asMap().entries.map((entry) {
      int index = entry.key;
      List<String> row = entry.value;

      return DataRow(
        // Alternate row colors for better readability
        color: MaterialStateProperty.all(
            index.isEven ? Colors.white : Color(0xFFFAFAFA)),
        cells: row
            .map((cellData) => DataCell(
                  Container(
                    width: columnWidth,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cellData.isNotEmpty ? cellData : '-',
                          textAlign: TextAlign.left,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cellData.isNotEmpty
                                ? Color(0xFF424242)
                                : Color(0xFF999999),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: cellData.isNotEmpty
                      ? () {
                          // Show full cell content in a dialog for long text
                          if (cellData.length > 50) {
                            _showCellContentDialog(cellData);
                          }
                        }
                      : null,
                ))
            .toList(),
      );
    }).toList();
  }

  void _showCellContentDialog(String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text('Cell Content', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Container(
            constraints: BoxConstraints(maxWidth: 300),
            child: SingleChildScrollView(
              child: Text(
                content,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Color(0xFF4CAF50))),
            ),
          ],
        );
      },
    );
  }
}

class _CropPlanningScreenState extends State<CropPlanningScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _scrollController = ScrollController();
  final _cropController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedLanguage = 'en-IN';
  final Map<String, String> _languages = {
    'en-IN': 'English (India)',
    'hi-IN': 'हिंदी (Hindi)',
    'ta-IN': 'தமிழ் (Tamil)',
    'kn-IN': 'ಕನ್ನಡ (Kannada)',
    'te-IN': 'తెలుగు (Telugu)',
    'ml-IN': 'മലയാളം (Malayalam)',
    'bn-IN': 'বাংলা (Bengali)',
    'gu-IN': 'ગુજરાતી (Gujarati)',
    'mr-IN': 'मराठी (Marathi)',
    'pa-IN': 'ਪੰਜਾਬੀ (Punjabi)',
  };
  String _soilType = 'Loamy';
  bool _isLoading = false;
  String _detectedSeason = '';
  String _result = '';
  String _detectSeasonFromLocation(String location) {
    // Get current month
    DateTime now = DateTime.now();
    int month = now.month;

    // Basic season detection based on Indian agricultural calendar
    // This can be enhanced with more sophisticated location-based logic
    if (month >= 6 && month <= 10) {
      return 'Kharif'; // Monsoon season crops (June-October)
    } else if (month >= 11 || month <= 3) {
      return 'Rabi'; // Winter season crops (November-March)
    } else {
      return 'Zaid'; // Summer season crops (April-May)
    }
  }

  final List<String> _soilTypes = [
    'Loamy',
    'Clay',
    'Sandy',
    'Silt',
    'Peat',
    'Chalk'
  ];

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
  
  // Initialize crop controller with the passed crop name if available
  if (widget.selectedCropName != null && widget.selectedCropName!.isNotEmpty) {
    _cropController.text = widget.selectedCropName!;
  }
}

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _locationController.dispose();
    _farmSizeController.dispose();
    _additionalNotesController.dispose();
    _cropController.dispose();
    super.dispose();
  }

  Future<void> _generateCropPlan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_apiKey.isEmpty) {
      _showErrorDialog('API Configuration Error',
          'Please add GEMINI_API_KEY to your .env file');
      return;
    }

    // Detect season based on location
    _detectedSeason = _detectSeasonFromLocation(_locationController.text);

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      String languageInstruction = _selectedLanguage == 'en-IN'
          ? ''
          : 'Please respond in ${_languages[_selectedLanguage]} language. ';

      final response = await _callGeminiAPI(
          "${languageInstruction}Generate a comprehensive crop planning schedule for ${_cropController.text} in ${_locationController.text}. "
          "Farm details: Size: ${_farmSizeController.text} acres, Soil type: $_soilType, Season: $_detectedSeason (auto-detected based on current time and location). "
          "Please provide detailed information including:\n"
          "1. **Optimal Planting Dates and Timeline**\n"
          "2. **Soil Preparation Requirements**\n"
          "3. **Fertilizer Schedule with Specific Quantities**\n"
          "4. **Irrigation Plan and Water Requirements**\n"
          "5. **Pest Management Strategies**\n"
          "6. **Expected Harvest Timing and Yield**\n"
          "7. **Market Considerations and Pricing**\n"
          "Additional notes: ${_additionalNotesController.text}. "
          "Format your response using proper markdown with tables where appropriate. "
          "Use | for table columns, ## for main headings, ### for subheadings, **bold** for emphasis, and * for bullet points.");

      setState(() {
        _result = response;
        _isLoading = false;
      });

      _animationController.forward();

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

  String _cleanTextForTts(String text) {
    return text
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'\*{1,2}([^*]+)\*{1,2}'), r'$1')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .replaceAll(RegExp(r'[_~\[\](){}|]'), '')
        .replaceAll(RegExp(r'[🌱🦠📊🧪🌍📈💡📸🖼️📄]'), '')
        .replaceAll(RegExp(r'[•\-]\s*'), 'Point: ')
        .replaceAll(RegExp(r'\n\s*\n'), '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                'Location', _locationController.text, Icons.location_on)),
        SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Soil Type', _soilType, Icons.landscape)),
        SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Season', _detectedSeason, Icons.calendar_today)),
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
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF4CAF50), size: 20),
          SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: MarkdownBody(
        data: _result,
        builders: {
          'table': TableBuilder(context),
        },
        styleSheet: MarkdownStyleSheet(
          h1: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32)),
          h2: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50)),
          h3: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32)),
          p: TextStyle(fontSize: 15, color: Color(0xFF424242), height: 1.6),
          strong:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
          listBullet: TextStyle(color: Color(0xFF4CAF50), fontSize: 16),
          // Enhanced table styling
          tableHead: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
              fontSize: 14),
          tableBody: TextStyle(color: Color(0xFF424242), fontSize: 14),
          tableBorder: TableBorder.all(color: Color(0xFFE0E0E0), width: 1),
          tableHeadAlign: TextAlign.center,
          tableCellsPadding: EdgeInsets.all(12),
        ),
        selectable: true,
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
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showSnackBar('Export functionality will be implemented'),
                  icon: Icon(Icons.download, size: 20),
                  label: Text('Export Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showSnackBar('Share functionality will be implemented'),
                  icon: Icon(Icons.share, size: 20),
                  label: Text('Share Plan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF4CAF50),
                    side: BorderSide(color: Color(0xFF4CAF50)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() {
              _result = '';
              _animationController.reset();
            }),
            icon: Icon(Icons.refresh, size: 20),
            label: Text('Generate New Plan'),
            style: TextButton.styleFrom(
                foregroundColor: Color(0xFF4CAF50),
                padding: EdgeInsets.symmetric(vertical: 12)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFF4CAF50)),
    );
  }

  Future<String> _callGeminiAPI(String prompt) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _apiKey
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
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
          final errorMessage =
              errorData['error']?['message'] ?? 'Unknown error';
          return 'API Error (${response.statusCode}): $errorMessage';
        } catch (e) {
          return 'HTTP Error (${response.statusCode}): ${response.body}';
        }
      }
    } catch (e) {
      return 'Network Error: Please check your internet connection. $e';
    }
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
              offset: Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Text('AI-Powered Crop Planning',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text(
              'Get personalized farming recommendations based on your location, soil type, and season',
              style:
                  TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
              textAlign: TextAlign.center),
        ],
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
              offset: Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller,
      String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32))),
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
                borderSide: BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red)),
            filled: true,
            fillColor: Color(0xFFFAFAFA),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items,
      Function(String?) onChanged, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32))),
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: items
                .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: TextStyle(fontSize: 16))))
                .toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Smart Crop Planning',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (String value) {
              setState(() {
                _selectedLanguage = value;
              });
              // Optional: Add any initialization function if needed
              // _initializeTts(); // Add this if you have TTS functionality
            },
            itemBuilder: (BuildContext context) {
              return _languages.entries.map((entry) {
                return PopupMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(),
              SizedBox(height: 24),

              // Input forms
              _buildInputCard([
                _buildTextFormField(
                    'Crop Name',
                    _cropController,
                    'Enter the crop you want to grow (e.g., Rice, Wheat, Tomato)',
                    Icons.eco,
                    validator: (value) => value?.isEmpty == true
                        ? 'Please enter crop name'
                        : null),
                SizedBox(height: 20),
                _buildTextFormField('Farm Location', _locationController,
                    'Enter your farm location (city, state)', Icons.location_on,
                    validator: (value) => value?.isEmpty == true
                        ? 'Please enter your farm location'
                        : null),
              ]),

              SizedBox(height: 16),

              _buildInputCard([
                _buildDropdownField(
                    'Soil Type',
                    _soilType,
                    _soilTypes,
                    (value) => setState(() => _soilType = value!),
                    Icons.landscape),
                SizedBox(height: 20),
                _buildTextFormField('Farm Size', _farmSizeController,
                    'Enter area in acres', Icons.square_foot,
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty == true
                        ? 'Please enter farm size'
                        : double.tryParse(value!) == null
                            ? 'Please enter a valid number'
                            : null),
              ]),

              SizedBox(height: 16),

              _buildInputCard([
                _buildTextFormField(
                    'Additional Notes',
                    _additionalNotesController,
                    'Any specific requirements, local conditions, or concerns',
                    Icons.notes,
                    maxLines: 3),
              ]),

              SizedBox(height: 24),

              // Generate button
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateCropPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                                    color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Generating Your Plan...',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 24),
                            SizedBox(width: 12),
                            Text('Generate Crop Plan',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),

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
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            _buildQuickStats(),
                            SizedBox(height: 24),
                            _buildMarkdownContent(),
                            SizedBox(height: 24),
                            _buildActionButtons(),
                          ],
                        ),
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
}
