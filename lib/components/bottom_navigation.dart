import 'package:farmprecise/pages/dashboard/farmercommunity.dart';
import 'package:farmprecise/pages/cropscanner/cropscannner.dart';
import 'package:farmprecise/pages/homepage.dart';
import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  // Function to navigate to the corresponding page
  void _navigateToPage(int index, BuildContext context) {
    switch (index) {
      case 0:
        // Navigate to Home
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
        break;
      case 1:
        // Navigate to Crop Calendar
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropScannerScreen(),
          ),
        );
        break;
      case 2:
        // Navigate to Community
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icons = [Icons.home, Icons.photo_camera, Icons.people];
    final labels = ['Home', 'Crop Scanner', 'Community'];

    return Container(
      height: 57, // Increased height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (index) {
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () {
              onItemTapped(index); // Trigger the onItemTapped callback
              _navigateToPage(
                  index, context); // Perform navigation based on index
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green.shade100 : Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                children: [
                  Icon(
                    icons[index],
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  if (isSelected)
                    SizedBox(width: 8.0), // Space between icon and label
                  if (isSelected)
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
