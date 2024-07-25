import 'package:farmprecise/pages/cropcalendar.dart';
import 'package:farmprecise/pages/drone.dart';
import 'package:farmprecise/pages/rentpage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:farmprecise/pages/homepage.dart';
import 'package:farmprecise/pages/login_page.dart';
import 'package:farmprecise/dashboard/farmercommunity.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.green,
        hintColor: Colors.greenAccent,
        scaffoldBackgroundColor: Colors.lightGreen[300],
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
    CropScanners(),
    CommunityScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onDrawerItemTapped(int index) {
    Navigator.pop(context);
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CommunityScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CropSuggestionsPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CropScannerPage()),
      );
    } else {
      _onItemTapped(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text(
          'Farm Precise',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: true,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green,
                ),
                accountName: Text(
                  'FARMER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  'FARMER@example.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    'F',
                    style: TextStyle(
                      fontSize: 24.0,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home, color: Colors.green),
                title: Text('Home'),
                onTap: () => _onDrawerItemTapped(0),
              ),
              ListTile(
                leading: Icon(Icons.shopping_bag, color: Colors.green),
                title: Text('Rent Products'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RentProductsForm()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.green),
                title: Text('Crop Calendar'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CropSuggestionsPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.people, color: Colors.green),
                title: Text('Community'),
                onTap: () => _onDrawerItemTapped(2),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Colors.green),
                title: Text('Crop Scanner'),
                onTap: () => _onDrawerItemTapped(3),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.green),
                title: Text('Drone Data'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AirDroneDetailScreen()),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.green),
                title: Text('Logout'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Started()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.green,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.7),
          selectedFontSize: 14.0,
          unselectedFontSize: 14.0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Crop Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Community',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class CropScanners extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Crop Scanners',
          style: TextStyle(color: Colors.green, fontSize: 24),
        ),
      ),
    );
  }
}

class CropCalendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Crop Calendar"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Text(
          'Crop Calendar',
          style: TextStyle(color: Colors.green, fontSize: 24),
        ),
      ),
    );
  }
}

class CropScannerPage extends StatefulWidget {
  @override
  _CropScannerPageState createState() => _CropScannerPageState();
}

class _CropScannerPageState extends State<CropScannerPage> {
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crop Scanner',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Find Your Crop Disease',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: _image == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera,
                              color: Colors.black,
                              size: 50,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tap to pick an image',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      )
                    : Image.file(
                        _image!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Community',
          style: TextStyle(color: Colors.green, fontSize: 24),
        ),
      ),
    );
  }
}

class Started extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[700],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100),
              Image.network(
                'https://static.vecteezy.com/system/resources/previews/003/184/204/original/smart-farming-and-agriculture-technology-icon-vector.jpg',
                height: 150,
              ),
              SizedBox(height: 40),
              Text(
                'PRECISION AGRICULTURE TECHNOLOGY',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                'Empowering Farmers with Data-driven Solutions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            LoginScreen(), // Navigate to LoginScreen
                      ),
                    );
                  },
                  child: Text(
                    'Connect Your Farm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
