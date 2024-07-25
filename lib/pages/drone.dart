import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AirDroneDetailScreen(),
    );
  }
}

class AirDroneDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF023047), // Background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Handle back button press
          },
        ),
        title: Text('Airdrone Detail', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                color: Color(0xFF669BBC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 12),
                          SizedBox(width: 8),
                          Text('Online', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      SizedBox(height: 16),
                      Image.network(
                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSe51Nf8qGu3eouQ-yXcdJHEeSxi5W13_Blxw&s', // Replace with your image URL or asset
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'X8 Airdrone 5143',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'S/N 5112345609',
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.timer, color: Colors.white70),
                              SizedBox(height: 4),
                              Text(
                                'Flight Duration',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '2 h 30 m',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.battery_full, color: Colors.white70),
                              SizedBox(height: 4),
                              Text(
                                'Battery Power',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '88%',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Drone Activities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      buildActivityRow('Watering Crops', '06.00 AM', true),
                      buildActivityRow(
                          'Spreading Fertilizer', '09.00 AM', true),
                      buildActivityRow('Patrolling Crops', '12.00 PM', false),
                      buildActivityRow('Watering Crops', '03.00 PM', false),
                      buildActivityRow('Patrolling Crops', '05.00 PM', false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildActivityRow(String activity, String time, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: isActive ? Colors.green : Colors.grey,
            size: 12,
          ),
          SizedBox(width: 8),
          Text(
            activity,
            style: TextStyle(
              fontSize: 16,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
          Spacer(),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
