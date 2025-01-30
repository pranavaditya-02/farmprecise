import 'package:farmprecise/dashboard/dashboard.dart';
import 'package:farmprecise/pages/homepage.dart';
import 'package:flutter/material.dart';

class CropSuggestionsPage extends StatefulWidget {
  @override
  _CropSuggestionsPageState createState() => _CropSuggestionsPageState();
}

class _CropSuggestionsPageState extends State<CropSuggestionsPage> {
  DateTime? _selectedDate;
  String _searchQuery = '';

  final List<Map<String, String>> _crops = [
    {
      'name': 'Asparagus',
      'harvest': 'Harvest on Oct 5, 2025',
      'waterNeeded': '1 inch per week',
      'fertilizer': 'Compost',
      'image':
          'https://idsb.tmgrup.com.tr/ly/uploads/images/2021/08/03/133396.jpeg',
    },
    {
      'name': 'Tomato',
      'harvest': 'Harvest on Nov 12, 2025',
      'waterNeeded': '2 inches per week',
      'fertilizer': 'NPK 10-10-10',
      'image':
          'https://blog.lexmed.com/images/librariesprovider80/blog-post-featured-images/shutterstock_1896755260.jpg?sfvrsn=52546e0a_0',
    },
    {
      'name': 'Carrot',
      'harvest': 'Harvest on Dec 15, 2025',
      'waterNeeded': '1 inch per week',
      'fertilizer': 'Compost',
      'image':
          'https://strapi.myplantin.com/Depositphotos_118413036_L_min_0123b119ba.webp',
    },
    {
      'name': 'Lettuce',
      'harvest': 'Harvest on Jan 20, 2025',
      'waterNeeded': '1.5 inches per week',
      'fertilizer': 'NPK 10-10-10',
      'image':
          'https://www.allthatgrows.in/cdn/shop/articles/Feat_Image-Lettuce_1024x1024.jpg?v=1565168838',
    },
    {
      'name': 'Cucumber',
      'harvest': 'Harvest on Feb 25, 2025',
      'waterNeeded': '1 inch per week',
      'fertilizer': 'Compost',
      'image':
          'https://www.highmowingseeds.com/media/catalog/product/cache/6cbdb003cf4aae33b9be8e6a6cf3d7ad/2/4/2452-0_2.jpg',
    },
  ];

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildFieldCard(String name, String harvest, String waterNeeded,
      String fertilizer, String imageUrl) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Image.network(imageUrl),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(harvest),
            Text('Water Needed: $waterNeeded'),
            Text('Fertilizer: $fertilizer'),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _selectDate(context));
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredCrops = _crops.where((crop) {
      return crop['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text(
          'Crop Calendar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              _selectedDate == null
                  ? Container()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crop Suggestions',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Search',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: filteredCrops.length,
                          itemBuilder: (context, index) {
                            final crop = filteredCrops[index];
                            return _buildFieldCard(
                              crop['name']!,
                              crop['harvest']!,
                              crop['waterNeeded']!,
                              crop['fertilizer']!,
                              crop['image']!,
                            );
                          },
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
