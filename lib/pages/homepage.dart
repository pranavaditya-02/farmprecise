import 'dart:async';
import 'package:farmprecise/dashboard/farmercommunity.dart';
import 'package:farmprecise/pages/cropcalendar.dart';
import 'package:farmprecise/pages/cropscannner.dart';
import 'package:farmprecise/pages/dronedetails.dart';
import 'package:farmprecise/pages/rentpage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:farmprecise/components/custom_appbar.dart';
import 'package:farmprecise/components/custom_drawer.dart';
import 'package:farmprecise/components/bottom_navigation.dart';

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
        'http://api.weatherapi.com/v1/current.json?key=2a78e81f9890453aaf4122524252301&q=11.4979484,77.2782678'));

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
                      Text(
                        temperature.isNotEmpty ? temperature : 'Loading...',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 24),
                      ),
                      Row(
                        children: [
                          Image.network(
                              conditionIconUrl.isNotEmpty
                                  ? conditionIconUrl
                                  : 'https://via.placeholder.com/32',
                              width: 32,
                              height: 32),
                          const SizedBox(width: 8),
                          Text(
                            conditionText.isNotEmpty
                                ? conditionText
                                : 'Loading...',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location.isNotEmpty ? location : 'Loading...',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildWeatherInfo(
                                light, 'Medium', Icons.lightbulb),
                          ),
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
                            child:
                                _buildWeatherInfo('CO2', '400ppm', Icons.cloud),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWeatherInfo(
                                fire, 'No fire', Icons.local_fire_department),
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
                  'Asparagus',
                  'Harvest on Oct 5, 2022',
                  'Normal',
                  '6.6 cm',
                  'https://idsb.tmgrup.com.tr/ly/uploads/images/2021/08/03/133396.jpeg',
                ),
                _buildFieldCard(
                  'Tomato',
                  'Harvest on Nov 12, 2022',
                  'Need more',
                  '7.7 cm',
                  'https://blog.lexmed.com/images/librariesprovider80/blog-post-featured-images/shutterstock_1896755260.jpg?sfvrsn=52546e0a_0',
                ),
                _buildFieldCard(
                  'Carrot',
                  'Harvest on Dec 15, 2022',
                  'Normal',
                  '8.2 cm',
                  'https://strapi.myplantin.com/Depositphotos_118413036_L_min_0123b119ba.webp',
                ),
                _buildFieldCard(
                  'Lettuce',
                  'Harvest on Jan 20, 2023',
                  'Good',
                  '10.5 cm',
                  'https://www.allthatgrows.in/cdn/shop/articles/Feat_Image-Lettuce_1024x1024.jpg?v=1565168838',
                ),
                _buildFieldCard(
                  'Cucumber',
                  'Harvest on Feb 25, 2023',
                  'Excellent',
                  '12.0 cm',
                  'https://www.highmowingseeds.com/media/catalog/product/cache/6cbdb003cf4aae33b9be8e6a6cf3d7ad/2/4/2452-0_2.jpg',
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
    );
  }

  static Widget _buildFieldCard(String title, String subtitle, String status,
      String length, String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF06D001),
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
    );
  }
}
