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
        seconds: 3)); // Ensures loading animation lasts at least 3 seconds
    final response =
        await http.get(Uri.parse('http://$ipaddress:3000/croprecommendation'));

    print(response.statusCode.toString());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      print("API Response: $data");

      Set<String> uniqueCropNames = {}; // Set to track unique crop names
      List<Map<String, String>> uniqueCrops = [];

      for (var item in data) {
        String cropName = item['Recommended_Crop'] as String;

        if (!uniqueCropNames.contains(cropName)) {
          uniqueCropNames.add(cropName);
          uniqueCrops.add({
            'name': cropName,
            'harvest': 'Harvest in ${item['Days_Required']} days',
            'waterNeeded': item['Water_Needed'] as String,
            'image': item['Crop_Image'] as String,
          });
        }
      }

      setState(() {
        _crops = uniqueCrops;
        _isLoading = false;
      });
    } else {
      print("Failed to load crops");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _cropsuggestionCard(
      String name, dynamic harvest, dynamic waterNeeded, String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with rounded corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 130,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        harvest.toString(),
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Water Needed: $waterNeeded ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
          'Crop Suggestions',
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
                      itemCount: filteredCrops.length,
                      itemBuilder: (context, index) {
                        final crop = filteredCrops[index];
                        return _cropsuggestionCard(
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
