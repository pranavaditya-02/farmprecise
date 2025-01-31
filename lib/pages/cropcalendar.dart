import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:farmprecise/pages/homepage.dart';
import 'package:farmprecise/Ip.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CropSuggestionsPage extends StatefulWidget {
  @override
  _CropSuggestionsPageState createState() => _CropSuggestionsPageState();
}

class _CropSuggestionsPageState extends State<CropSuggestionsPage> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _crops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    await Future.delayed(Duration(
        seconds: 3)); // Ensures loading animation lasts at least 2 seconds
    final response =
        await http.get(Uri.parse('http://$ipaddress:3000/croprecommendation'));

    print(response.statusCode.toString());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      print("API Response: $data");

      setState(() {
        _crops = data.map((item) {
          return {
            'name': item['Recommended_Crop'] as String,
            'harvest': 'Harvest in ${item['Days_Required']} days',
            'waterNeeded': item['Water_Needed'],
            'image': item['Crop_Image'] as String,
          };
        }).toList();

        _isLoading = false;
      });
    } else {
      print("Failed to load crops");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFieldCard(
      String name, dynamic harvest, dynamic waterNeeded, String imageUrl) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Image.network(imageUrl.toString(),
            width: 50, height: 50, fit: BoxFit.cover),
        title: Text(
          name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(harvest.toString()),
            Text('Water Needed: \$waterNeeded'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredCrops = _crops.where((crop) {
      return crop['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text(
          'Crop Calendar',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.inkDrop(
                color: Colors.green,
                size: 60,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
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
                          crop['image']!,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
