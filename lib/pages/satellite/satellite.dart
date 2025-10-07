import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(FarmPreciseApp());
}

class FarmPreciseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarmPrecise',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'OpenSans',
      ),
      home: FarmDashboard(),
    );
  }
}

class FarmDashboard extends StatefulWidget {
  @override
  _FarmDashboardState createState() => _FarmDashboardState();
}

class _FarmDashboardState extends State<FarmDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FarmPrecise Dashboard'),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SatelliteRecommendationCard(),
              SizedBox(height: 16),
              LandMarkingCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'OpenSans',
            color: Colors.blue[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'OpenSans',
            color: Colors.blue[600],
          ),
        ),
      ],
    );
  }
}

class SatelliteRecommendationCard extends StatefulWidget {
  @override
  _SatelliteRecommendationCardState createState() =>
      _SatelliteRecommendationCardState();
}

class _SatelliteRecommendationCardState
    extends State<SatelliteRecommendationCard> {
  bool _isLoading = false;
  String _recommendation = '';
  double _ndvi = 0.0;
  double _soilMoisture = 0.0;
  String _error = '';

  // OpenWeather Agro API configuration
  final String _apiKey = 'YOUR_OPENWEATHER_API_KEY'; // Replace with actual API key
  final String _polyId = 'YOUR_POLYGON_ID'; // Replace with actual polygon ID

  @override
  void initState() {
    super.initState();
    _fetchSatelliteData();
  }

  Future<void> _fetchSatelliteData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // For demonstration, using mock data since we need actual API credentials
      // In production, uncomment the API call below
      await _fetchMockData();

      /*
      // Actual API call (uncomment when you have real credentials)
      final ndviUrl = 'http://api.openweathermap.org/agro/1.0/ndvi/history?'
          'polyid=$_polyId&start=${DateTime.now().subtract(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000}'
          '&end=${DateTime.now().millisecondsSinceEpoch ~/ 1000}&appid=$_apiKey';
      
      final soilUrl = 'http://api.openweathermap.org/agro/1.0/soil?'
          'polyid=$_polyId&appid=$_apiKey';

      final ndviResponse = await http.get(Uri.parse(ndviUrl));
      final soilResponse = await http.get(Uri.parse(soilUrl));

      if (ndviResponse.statusCode == 200 && soilResponse.statusCode == 200) {
        final ndviData = json.decode(ndviResponse.body);
        final soilData = json.decode(soilResponse.body);
        
        setState(() {
          _ndvi = ndviData.isNotEmpty ? ndviData.last['data']['mean'] : 0.0;
          _soilMoisture = soilData['moisture'] ?? 0.0;
          _recommendation = _generateRecommendation(_ndvi, _soilMoisture);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
      */
    } catch (e) {
      setState(() {
        _error = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMockData() async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 2));

    // Mock JSON response for testing
    final mockResponse = {
      "ndvi": 0.68,
      "soil_moisture": 18.0,
      "timestamp": DateTime.now().toIso8601String()
    };

    setState(() {
      _ndvi = mockResponse['ndvi'] as double;
      _soilMoisture = mockResponse['soil_moisture'] as double;
      _recommendation = _generateRecommendation(_ndvi, _soilMoisture);
      _isLoading = false;
    });
  }

  String _generateRecommendation(double ndvi, double soilMoisture) {
    String cropCondition = '';
    String moistureCondition = '';

    // NDVI-based recommendation
    if (ndvi < 0.4) {
      cropCondition = '⚠️ Crop stress detected. Immediate action required.';
    } else if (ndvi >= 0.4 && ndvi < 0.7) {
      cropCondition = '🌱 Crop condition moderate. Monitor closely.';
    } else {
      cropCondition = '✅ Crop condition healthy.';
    }

    // Soil moisture recommendation
    if (soilMoisture < 20) {
      moistureCondition = 'Irrigation needed soon.';
    } else {
      moistureCondition = 'Soil moisture adequate.';
    }

    return '$cropCondition $moistureCondition';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.satellite,
                  color: Colors.green[700],
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Satellite Recommendation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'OpenSans',
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fetching satellite data...',
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else if (_error.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: TextStyle(
                          fontFamily: 'OpenSans',
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data values
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDataCard('NDVI', _ndvi.toStringAsFixed(2), 
                          _ndvi >= 0.7 ? Colors.green : _ndvi >= 0.4 ? Colors.orange : Colors.red),
                      _buildDataCard('Soil Moisture', '${_soilMoisture.toStringAsFixed(1)}%',
                          _soilMoisture >= 20 ? Colors.blue : Colors.red),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Recommendation
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      _recommendation,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.w500,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'OpenSans',
                    color: Colors.grey[600],
                  ),
                ),
                IconButton(
                  onPressed: _fetchSatelliteData,
                  icon: Icon(Icons.refresh, color: Colors.green[700]),
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'OpenSans',
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'OpenSans',
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class LandMarkingCard extends StatefulWidget {
  @override
  _LandMarkingCardState createState() => _LandMarkingCardState();
}

class _LandMarkingCardState extends State<LandMarkingCard> {
  List<LandMark> _landMarks = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  String _selectedCropType = 'Wheat';
  
  final List<String> _cropTypes = [
    'Wheat', 'Rice', 'Corn', 'Soybeans', 'Cotton', 'Sugarcane', 'Barley', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.map,
                  color: Colors.green[700],
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Land Use Mapping',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'OpenSans',
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Add Land Form
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mark New Land Area',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'OpenSans',
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Field Name',
                      hintText: 'e.g., North Field',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.label),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            hintText: '0.0000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lngController,
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            hintText: '0.0000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCropType,
                    decoration: InputDecoration(
                      labelText: 'Crop Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.grass),
                    ),
                    items: _cropTypes.map((String crop) {
                      return DropdownMenuItem<String>(
                        value: crop,
                        child: Text(crop),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCropType = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addLandMark,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Add Land Mark',
                        style: TextStyle(
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Marked Lands List
            if (_landMarks.isNotEmpty) ...[
              Text(
                'Marked Land Areas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'OpenSans',
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              ..._landMarks.map((landMark) => _buildLandMarkItem(landMark)),
            ] else
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No land areas marked yet',
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addLandMark() {
    if (_nameController.text.isNotEmpty &&
        _latController.text.isNotEmpty &&
        _lngController.text.isNotEmpty) {
      try {
        double lat = double.parse(_latController.text);
        double lng = double.parse(_lngController.text);
        
        setState(() {
          _landMarks.add(LandMark(
            name: _nameController.text,
            latitude: lat,
            longitude: lng,
            cropType: _selectedCropType,
            dateAdded: DateTime.now(),
          ));
        });
        
        // Clear form
        _nameController.clear();
        _latController.clear();
        _lngController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Land mark added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter valid coordinates'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildLandMarkItem(LandMark landMark) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.green[50],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.location_pin,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  landMark.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'OpenSans',
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Crop: ${landMark.cropType}',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Lat: ${landMark.latitude.toStringAsFixed(4)}, Lng: ${landMark.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _landMarks.remove(landMark);
              });
            },
            icon: Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class LandMark {
  final String name;
  final double latitude;
  final double longitude;
  final String cropType;
  final DateTime dateAdded;

  LandMark({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.cropType,
    required this.dateAdded,
  });
}

// Weather API Service (Alternative free API)
class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = 'YOUR_FREE_WEATHER_API_KEY'; // Get from OpenWeatherMap

  static Future<Map<String, dynamic>?> getWeatherData(double lat, double lon) async {
    try {
      final url = '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Weather API Error: $e');
    }
    return null;
  }
}