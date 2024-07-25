import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF06D001),
        hintColor: Color(0xFF9BEC00),
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
      ),
      home: Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    ListPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF06D001),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.white),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list, color: Colors.white),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.white),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Text(
        'List Page',
        style: TextStyle(color: Colors.black, fontSize: 24),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Text(
        'Profile Page',
        style: TextStyle(color: Colors.black, fontSize: 24),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    children: const [
                      Text(
                        '24°C',
                        style: TextStyle(color: Colors.white, fontSize: 32),
                      ),
                      Icon(Icons.cloud, color: Colors.white, size: 32),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Partly sunny',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
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
                                'Light', 'Medium', Icons.lightbulb),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWeatherInfo(
                                'Humidity', '42%', Icons.water_drop),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWeatherInfo(
                                'Rainfall', '10mm', Icons.grain),
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
                                'Fire', 'No fire', Icons.local_fire_department),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child:
                                _buildWeatherInfo('Wind', '4 km/h', Icons.air),
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
    );
  }

  static Widget _buildWeatherInfo(String label, String value, IconData icon) {
    // Define the order of weather information
    List<String> weatherLabels = [
      'Light', // Moved "Light" to the first position
      'Humidity',
      'Rainfall',
      'CO2',
      'Fire',
      'Wind',
      'Soil Moisture', // Moved "Soil Moisture" to the last position
    ];

    // Check if the label is in the desired order
    if (!weatherLabels.contains(label)) {
      return Container();
    }

    // Get the index of the label in the list
    int index = weatherLabels.indexOf(label);

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
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ],
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
          width: 80, // Adjusted image width
          height: 80, // Adjusted image height
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
