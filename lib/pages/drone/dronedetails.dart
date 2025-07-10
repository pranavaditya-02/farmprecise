import 'package:farmprecise/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:farmprecise/pages/drone/drone.dart';

class DroneMonitoringScreen extends StatelessWidget {
  final String backgroundImage;

  const DroneMonitoringScreen({
    Key? key,
    this.backgroundImage = 'assets/solution-5-web.jpg.webp', // Local asset
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF0A5F4B),
                );
              },
            ),
          ),

          // Semi-transparent overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),

          // App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
              ),
              title: const Text(
                'Airdrone Detail',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
          ),

          // Drone Info Card
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AirDroneDetailScreen(),
                  ),
                );
              },
              child: _DroneInfoCard(),
            ),
          ),

          // Field Info Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _FieldInfoCard(),
          ),
        ],
      ),
    );
  }
}

class _DroneInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D725C),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'X8 Airdrone 5143',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Spreading Fertilizer',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/drone.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.flight, size: 80, color: Colors.white);
            },
          ),
        ],
      ),
    );
  }
}

class _FieldInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/corn.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.grass, size: 24);
                },
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Corn Field - Plot 12',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Field Area 124.56 AC',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FieldMetric(
                      icon: Icons.thermostat,
                      label: 'Temperature',
                      value: '29° C',
                      showRightBorder: true,
                      showBottomBorder: true,
                    ),
                  ),
                  Expanded(
                    child: _FieldMetric(
                      icon: Icons.water_drop,
                      label: 'Air Humidity',
                      value: '32%',
                      showBottomBorder: true,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _FieldMetric(
                      icon: Icons.landscape,
                      label: 'Land Moisture',
                      value: '27%',
                      showRightBorder: true,
                    ),
                  ),
                  Expanded(
                    child: _FieldMetric(
                      icon: Icons.grass,
                      label: 'Land Fertility',
                      value: '68%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showRightBorder;
  final bool showBottomBorder;

  const _FieldMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.showRightBorder = false,
    this.showBottomBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          right: showRightBorder
              ? const BorderSide(color: Colors.grey, width: 0.5)
              : BorderSide.none,
          bottom: showBottomBorder
              ? const BorderSide(color: Colors.grey, width: 0.5)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Color.fromARGB(255, 1, 62, 63),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
