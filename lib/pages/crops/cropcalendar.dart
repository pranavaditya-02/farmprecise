import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:farmprecise/pages/homepage.dart';
import 'package:farmprecise/Ip.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:farmprecise/pages/crops/cropplanning.dart';

class CropSuggestionsPage extends StatefulWidget {
  @override
  _CropSuggestionsPageState createState() => _CropSuggestionsPageState();
}

class _CropSuggestionsPageState extends State<CropSuggestionsPage> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _crops = [];
  bool _isLoading = true;
  String _selectedCropName = '';

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    try {
      await Future.delayed(Duration(seconds: 3)); // Ensures loading animation lasts at least 3 seconds
      final response = await http.get(Uri.parse('http://$ipaddress:3000/croprecommendation'));

      print(response.statusCode.toString());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("API Response: $data");

        Set<String> uniqueCropNames = {}; // Set to track unique crop names
        List<Map<String, dynamic>> uniqueCrops = [];

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
    } catch (e) {
      print("Error fetching crops: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSowingPlanModal(Map<String, dynamic> crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 20),

              // Crop image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  crop['image']!,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),

              // Title
              Text(
                'Plan for Sowing',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),

              // Question text
              Text(
                'Would you like to create a detailed crop planning schedule for ${crop['name']}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _proceedWithSowing(crop);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Proceed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  void _proceedWithSowing(Map<String, dynamic> crop) {
    // Store the crop name in state
    setState(() {
      _selectedCropName = crop['name'];
    });
    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CropPlanningScreen(
      selectedCropName: _selectedCropName, // Pass your state variable here
    ),
  ),
);
  }

  Widget _cropSuggestionCard(
      String name, dynamic harvest, dynamic waterNeeded, String imageUrl) {
    return GestureDetector(
      onTap: () {
        _showSowingPlanModal({
          'name': name,
          'harvest': harvest,
          'waterNeeded': waterNeeded,
          'image': imageUrl,
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 130,
                      height: 100,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      harvest.toString(),
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Water Needed: $waterNeeded',
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
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    filteredCrops.isEmpty
                        ? Center(
                            child: Text(
                              'No crops found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: filteredCrops.length,
                            itemBuilder: (context, index) {
                              final crop = filteredCrops[index];
                              return _cropSuggestionCard(
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