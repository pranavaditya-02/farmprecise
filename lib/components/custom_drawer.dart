import 'package:flutter/material.dart';
import 'package:farmprecise/dashboard/farmercommunity.dart';
import 'package:farmprecise/pages/cropscannner.dart';
import 'package:farmprecise/pages/dronedetails.dart';
import 'package:farmprecise/pages/homepage.dart';
import 'package:farmprecise/pages/cropcalendar.dart';
import 'package:farmprecise/pages/rentpage.dart';
import 'package:farmprecise/main.dart';

class CustomDrawer extends StatelessWidget {
  final Function(int) onItemTapped;

  const CustomDrawer({Key? key, required this.onItemTapped}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
            // Home Screen Navigation
            ListTile(
              leading: Icon(Icons.home, color: Colors.green),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                onItemTapped(0); // Update index for bottom nav
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: Colors.green),
              title: Text('Crop Scanner'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                onItemTapped(1); // Update index for bottom nav
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CropScannerScreen()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.people, color: Colors.green),
              title: Text('Community'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                onItemTapped(2); // Update index for bottom nav
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CommunityScreen()),
                );
              },
            ),

            // Rent Products Screen Navigation
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
            // Crop Calendar Screen Navigation
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.green),
              title: Text('Crop Suggestions'),
              onTap: () {
                Navigator.pop(context); // Close the drawer

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CropSuggestionsPage()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.airline_stops, color: Colors.green),
              title: Text('Drone Data'),
              onTap: () {
                Navigator.pop(context); // Close the drawer

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DroneMonitoringScreen()),
                );
              },
            ),
            Divider(),
            // Logout
            ListTile(
              leading: Icon(Icons.logout, color: Colors.green),
              title: Text('Logout'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Started()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
