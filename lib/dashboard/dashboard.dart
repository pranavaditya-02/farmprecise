// import 'package:farmprecise/pages/cropcalendar.dart';
// import 'package:farmprecise/pages/cropscannner.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:farmprecise/pages/homepage.dart';
// import 'package:farmprecise/dashboard/farmercommunity.dart';
// import 'package:farmprecise/components/custom_drawer.dart';

// class Dashboard extends StatefulWidget {
//   @override
//   _DashboardState createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard> {
//   int _selectedIndex = 0;

//   final List<Widget> _pages = [
//     HomePage(),
//     CropScannerScreen(),
//     CommunityScreen(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   void _onDrawerItemTapped(int index) {
//     Navigator.pop(context);
//     if (index == 2) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => CommunityScreen()),
//       );
//     } else if (index == 1) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => CropSuggestionsPage()),
//       );
//     } else if (index == 3) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => CropScannerScreen()),
//       );
//     } else {
//       _onItemTapped(index);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         centerTitle: true,
//         title: Text(
//           'Farm Precise',
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         automaticallyImplyLeading: true,
//       ),
//       drawer: CustomDrawer(onItemTapped: _onItemTapped),
//       body: _pages[_selectedIndex],
//       bottomNavigationBar: Container(
//         height: 57, // Increased height
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20.0),
//             topRight: Radius.circular(20.0),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 5.0,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: List.generate(3, (index) {
//             final isSelected = _selectedIndex == index;
//             final icons = [Icons.home, Icons.calendar_month, Icons.people];
//             final labels = ['Home', 'Crop Calendar', 'Community'];

//             return GestureDetector(
//               onTap: () => _onItemTapped(index),
//               child: AnimatedContainer(
//                 duration: Duration(milliseconds: 300),
//                 padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                 decoration: BoxDecoration(
//                   color:
//                       isSelected ? Colors.green.shade100 : Colors.transparent,
//                   borderRadius: BorderRadius.circular(20.0),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       icons[index],
//                       color: isSelected ? Colors.green : Colors.grey,
//                     ),
//                     if (isSelected)
//                       SizedBox(width: 8.0), // Space between icon and label
//                     if (isSelected)
//                       Text(
//                         labels[index],
//                         style: TextStyle(
//                           color: Colors.green,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             );
//           }),
//         ),
//       ),
//     );
//   }
// }
