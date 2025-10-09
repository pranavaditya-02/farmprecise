import 'dart:async';
import 'dart:ui';
import 'package:farmprecise/pages/chatbot/chatbotscreen.dart';
import 'package:farmprecise/pages/dashboard/farmercommunity.dart';
import 'package:farmprecise/pages/crops/cropcalendar.dart';
import 'package:farmprecise/pages/cropscanner/cropscannner.dart';
import 'package:farmprecise/pages/drone/dronedetails.dart';
import 'package:farmprecise/pages/rent/rentpage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:farmprecise/components/custom_appbar.dart';
import 'package:farmprecise/components/custom_drawer.dart';
import 'package:farmprecise/components/bottom_navigation.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String temperature = '';
  String humidity = '';
  String windSpeed = '';
  String location = '';
  String conditionText = '';
  String conditionIconUrl = '';

  final String light = 'Light';
  String rainfall = '';
  final String soilMoisture = '65%';
  final String fire = 'No fire';
  int _selectedIndex = 0;
  bool isLoading = true;

  final List<Widget> _pages = [
    HomePage(),
    CropScannerScreen(),
    CommunityScreen(),
    RentProductsForm(),
    CropSuggestionsPage(),
    RentProductsForm(),
    DroneMonitoringScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  // Method to navigate to chatbot screen
  void _openChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FarmingChatbot()),
    );
  }

  Timer? _timer; // Timer instance

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
    // Set up a timer to fetch data every 60 seconds
    _timer = Timer.periodic(Duration(seconds: 60), (Timer timer) {
      fetchWeatherData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> fetchWeatherData() async {
    final response = await http.get(Uri.parse(
        'http://api.weatherapi.com/v1/current.json?key=2a78e81f9890453aaf4122524252301&q=12.8699,80.2184'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        temperature = '${data['current']['temp_c']}°C';
        humidity = '${data['current']['humidity']}%';
        windSpeed = '${data['current']['wind_kph'].toStringAsFixed(1)} km/h';
        location =
            '${data['location']['name'].toLowerCase()}, ${data['location']['region'].toLowerCase()}';
        conditionText = data['current']['condition']['text'];
        conditionIconUrl = 'http:${data['current']['condition']['icon']}';
        rainfall = '${data['current']['precip_mm']} mm';
        isLoading = false; // Data is loaded
      });
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Widget _buildWeatherInfo(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF9BEC00), Color(0xFF06D001)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Hi, Welcome!',
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Color(0xFF06D001),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      temperature.isNotEmpty
                          ? Text(
                              temperature,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 24),
                            )
                          : LoadingAnimationWidget.waveDots(
                              color: Colors.white, size: 24),
                      Row(
                        children: [
                          if (conditionIconUrl
                              .isNotEmpty) // Only show the image if URL is available
                            Image.network(
                              conditionIconUrl,
                              width: 32,
                              height: 32,
                            ),
                          const SizedBox(width: 8),
                          conditionText.isNotEmpty
                              ? Text(
                                  conditionText,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                )
                              : LoadingAnimationWidget.waveDots(
                                  color: Colors.white, size: 16),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  location.isNotEmpty
                      ? Text(
                          location,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        )
                      : LoadingAnimationWidget.waveDots(
                          color: Colors.white, size: 16),
                  const SizedBox(height: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: _buildWeatherInfo(
                                  light, 'Medium', Icons.lightbulb)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWeatherInfo(
                                'Humidity',
                                humidity.isNotEmpty ? humidity : 'Loading...',
                                Icons.water_drop),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWeatherInfo(
                                'Rainfall',
                                rainfall.isNotEmpty ? rainfall : 'Loading...',
                                Icons.grain),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: _buildWeatherInfo(
                                  'CO2', '400ppm', Icons.cloud)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWeatherInfo(
                              fire,
                              'No fire',
                              Icons.local_fire_department,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWeatherInfo(
                                'Wind',
                                windSpeed.isNotEmpty ? windSpeed : 'Loading...',
                                Icons.air),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildWeatherInfo(
                                'Soil Moisture', '65%', Icons.opacity),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'My fields',
                style: TextStyle(color: Colors.black, fontSize: 24),
              ),
            ),
            const SizedBox(height: 10),
            ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildFieldCard(
                  'Paddy (Rice)',
                  'Harvest on Nov 10, 2025',
                  'Maturing',
                  '110 cm', // height/elevation in cm
                  'https://safalseeds.in/public/images/paddy-seeds.jpg',
                ),
                _buildFieldCard(
                  'Maize',
                  'Harvest on Dec 05, 2025',
                  'Ready',
                  '220 cm', // cm
                  'https://media.istockphoto.com/id/1485792634/photo/ripe-yellow-corn-cob-on-the-field.jpg?s=612x612&w=0&k=20&c=5Lhbh5a15DNMdyaxBPGR4XAIjTPXz1Ct52i2WcoVOQs=',
                ),
                _buildFieldCard(
                  'Turmeric',
                  'Harvest on Jan 20, 2026',
                  'Harvest soon',
                  '90 cm', // cm
                  'https://media.istockphoto.com/id/954270512/photo/turmeric-root-herb-plant.jpg?s=612x612&w=0&k=20&c=vccQL2B2NTOBzBkfP6oIx_jkD8WOVDWrYU57cjNJfOE=',
                ),
                _buildFieldCard(
                  'Groundnut',
                  'Harvest on Oct 30, 2025',
                  'Good',
                  '45 cm', // cm
                  'https://www.protectourlivelihood.in/wp-content/uploads/2025/04/Image-Groundnut.jpg',
                ),
                _buildFieldCard(
                  'Banana',
                  'Harvest on Mar 15, 2026',
                  'Fruit set',
                  '250 cm', // cm
                  'https://cdn4.volusion.store/uyqbk-sezkn/v/vspfiles/photos/FRUBAN-FRU-S-TX-STAR-2.jpg?v-cache=1729145494',
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped, // Handle bottom nav item taps
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openChatbot,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade600,
                  Colors.green.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 2, 51, 4).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Lottie.asset(
              'assets/ChatBotAnimatedIcon.json',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard(String title, String subtitle, String status,
      String length, String imageUrl) {
    return GestureDetector(
      onTap: () => _showCropDetailsDialog(context, title, length, subtitle, status),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF06D001),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    status,
                    style: const TextStyle(color: Color(0xFF9BEC00)),
                  ),
                  Text(
                    length,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCropDetailsDialog(
      BuildContext context, String cropName, String length, String subtitle, String status) {
    String harvestDate = subtitle.replaceAll('Harvest on ', '');

    // Infer phase from status (simple heuristic)
    String inferPhase(String s) {
      final lower = s.toLowerCase();
      if (lower.contains('fruit') || lower.contains('flower') || lower.contains('set')) return 'Flowering / Reproductive';
      if (lower.contains('mature') || lower.contains('maturing') || lower.contains('ready') || lower.contains('harvest')) return 'Maturity / Late season';
      if (lower.contains('harvest soon')) return 'Reproductive / Near maturity';
      return 'Vegetative';
    }

    // More accurate, concise and layman-friendly guidance.
    // Each entry: short "what to look for" (symptoms), likely causes (pathogen/pest) and simple prevention / first-aid steps.
    Map<String, Map<String, Map<String, String>>> cropGuidance = {
      'paddy': {
        'Vegetative': {
          'issues':
              'Symptoms: small brown/grey spots on leaves, tilted/necrotic patches. Likely: Rice blast (fungus) or brown spot.',
          'prevention':
              'Use resistant seed, treat seed before sowing, avoid excess nitrogen, maintain stable water level and remove straw/volunteer plants. If spots spread, contact extension for recommended fungicide and spray timing.'
        },
        'Reproductive': {
          'issues':
              'Symptoms: yellowing and wilting of leaves, hollowness in grains. Likely: Bacterial leaf blight or sheath rot.',
          'prevention':
              'Avoid stagnant water, clean field debris, use balanced fertilizer, and harvest on time. For severe outbreaks, seek local extension advice for appropriate control.'
        },
        'Maturity / Late season': {
          'issues':
              'Symptoms: lodging, discoloured grains or rot in wet weather. Likely: grain rot or secondary rots.',
          'prevention':
              'Harvest promptly after maturity, dry grain well before storage to prevent storage molds.'
        }
      },
      'maize': {
        'Vegetative': {
          'issues':
              'Symptoms: elongated grey/brown leaf lesions, holes on leaves from caterpillars. Likely: leaf blights or stem/leaf borers (insects).',
          'prevention':
              'Plant certified seed, rotate crops, remove residues, monitor for caterpillars and use pheromone traps/biocontrol where available. Ask extension before using insecticide.'
        },
        'Maturity / Late season': {
          'issues':
              'Symptoms: discoloured kernels, mouldy ears when wet. Likely: ear rots (fungal) and storage molds.',
          'prevention':
              'Harvest at correct moisture, dry well, avoid mechanical damage to cobs and store in dry, ventilated place.'
        }
      },
      'turmeric': {
        'Vegetative': {
          'issues':
              'Symptoms: yellow/black spots on leaves, soft/rotten rhizomes in wet soil. Likely: leaf spot (fungus) or rhizome rot (waterlogged soil causing Pythium/Phytophthora).',
          'prevention':
              'Use healthy, disease-free rhizomes for planting, raise beds for good drainage, avoid waterlogging, and practise crop rotation. Remove and burn badly infected plants.'
        },
        'Reproductive': {
          'issues':
              'Symptoms: rotting of harvested rhizomes, poor curing. Likely: rhizome rot and secondary rots if harvested wet.',
          'prevention':
              'Harvest when soil is not waterlogged, cure rhizomes properly in shade/dry place, and store dry. For persistent rot problems, consult extension for seed treatment options.'
        }
      },
      'groundnut': {
        'Vegetative': {
          'issues':
              'Symptoms: small dark spots on leaves or defoliation. Likely: early/late leaf spot (fungal).',
          'prevention':
              'Use tolerant varieties, keep proper spacing for airflow, remove old pods/residues, and rotate with non-host crops. Follow extension advice if sprays are needed.'
        },
        'Maturity / Late season': {
          'issues':
              'Symptoms: rotted pods or discoloured kernels; storage contamination. Likely: pod rot and aflatoxin from Aspergillus when not dried properly.',
          'prevention':
              'Harvest on time, dry pods thoroughly in sun on clean surfaces, and store in cool, dry places. Avoid mixing damaged pods into stock.'
        }
      },
      'banana': {
        'Vegetative': {
          'issues':
              'Symptoms: yellowing leaves, stunted growth, root decline. Likely: nematodes or Panama wilt (Fusarium) in some areas.',
          'prevention':
              'Plant disease-free suckers, keep fields well drained, practice crop sanitation and consider nematode management (mulch/organic amendments). Contact extension if wilt symptoms spread.'
        },
        'Flowering / Reproductive': {
          'issues':
              'Symptoms: dark/brown patches on fingers, bunch rots in humid weather. Likely: Sigatoka/leaf spot diseases and bacterial/fungal rots.',
          'prevention':
              'Ensure good airflow (prune leaves), avoid bruising fruit, harvest timely. If outbreaks occur, seek extension guidance for safe control methods.'
        }
      }
    };

    final phase = inferPhase(status);
    final key = cropName.toLowerCase();
    String issuesText = 'No specific issues identified for this crop and phase.';
    String preventionText = 'Keep field clean, use healthy seed/suckers, rotate crops and monitor regularly. Contact local agricultural extension for exact measures.';

    if (cropGuidance.keys.any((k) => key.contains(k))) {
      final matched = cropGuidance.keys.firstWhere((k) => key.contains(k));
      final phaseMap = cropGuidance[matched]!;
      if (phaseMap.containsKey(phase)) {
        issuesText = phaseMap[phase]!['issues']!;
        preventionText = phaseMap[phase]!['prevention']!;
      } else if (phaseMap.containsKey('Vegetative')) {
        issuesText = phaseMap['Vegetative']!['issues']!;
        preventionText = phaseMap['Vegetative']!['prevention']!;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        cropName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow('Days After Seeding', '28 Days',
                        valueColor: Colors.green[300]!),
                    const SizedBox(height: 16),
                    _buildDetailRow('Phase', phase,
                        valueColor: Colors.green[300]!),
                    const SizedBox(height: 16),
                    _buildDetailRow('Season', 'Dry',
                        valueColor: Colors.green[300]!),
                    const SizedBox(height: 16),
                    _buildDetailRow('Elevation', length,
                        valueColor: Colors.green[300]!),
                    const SizedBox(height: 16),
                    _buildDetailRow('Harvest on', harvestDate,
                        valueColor: Colors.green[300]!),
                    const SizedBox(height: 24),

                    // Highlighted, clear disease + prevention block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Likely disease / pest (what to look for)',
                            style: TextStyle(
                              color: Colors.orange[200],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            issuesText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Simple prevention & first steps',
                            style: TextStyle(
                              color: Colors.green[200],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            preventionText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[200]!, Colors.green[400]!],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.timer, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            '+15 Days to Flowering Phase',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[100]!],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            LinearProgressIndicator(
                              value: 0.4,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green[400]!,
                              ),
                              minHeight: 12,
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Vegetative',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Flowering',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// Helper method to build detail rows
  Widget _buildDetailRow(String label, String value,
      {Color valueColor = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
