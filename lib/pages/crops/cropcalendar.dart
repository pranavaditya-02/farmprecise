import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  
  // Cache configuration
  static const String _cacheKey = 'crop_suggestions_cache';
  static const String _cacheTimestampKey = 'crop_suggestions_timestamp';
  static const Duration _cacheExpiration = Duration(hours: 12); // Cache expires after 24 hours

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    try {
      await Future.delayed(Duration(seconds: 1)); // Reduced loading time due to caching
      
      // First check if we have valid cached data
      bool hasCachedData = await _loadFromCache();
      
      if (!hasCachedData) {
        // No valid cache, try API first
        bool apiSuccess = await _fetchCropsFromAPI();
        
        // If API fails, load from local JSON
        if (!apiSuccess) {
          await _loadCropsFromAssets();
        }
      }
      
    } catch (e) {
      print("Error in _fetchCrops: $e");
      // If everything fails, try loading from assets as last resort
      await _loadCropsFromAssets();
    }
  }

  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cachedData != null && cacheTimestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
        final now = DateTime.now();
        
        // Check if cache is still valid
        if (now.difference(cacheTime) < _cacheExpiration) {
          print("Loading crops from cache...");
          final List<dynamic> data = json.decode(cachedData);
          
          if (data.isNotEmpty) {
            _processCropData(data);
            setState(() {
              _isLoading = false;
            });
            
            // Optionally fetch fresh data in background after loading from cache
            _fetchFreshDataInBackground();
            
            return true;
          }
        } else {
          print("Cache expired, clearing...");
          await _clearCache();
        }
      }
    } catch (e) {
      print("Error loading from cache: $e");
    }
    
    return false;
  }

  Future<void> _saveToCache(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = json.encode(data);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString(_cacheKey, dataString);
      await prefs.setInt(_cacheTimestampKey, timestamp);
      
      print("Data saved to cache");
    } catch (e) {
      print("Error saving to cache: $e");
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      print("Cache cleared");
    } catch (e) {
      print("Error clearing cache: $e");
    }
  }

  // Fetch fresh data in background after loading from cache
  Future<void> _fetchFreshDataInBackground() async {
    try {
      print("Fetching fresh data in background...");
      final response = await http.get(
        Uri.parse('http://$ipaddress:3000/croprecommendation'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> freshData = json.decode(response.body);
        
        if (freshData.isNotEmpty) {
          // Save fresh data to cache
          await _saveToCache(freshData);
          
          // Update UI with fresh data
          _processCropData(freshData);
          print("Background refresh completed");
        }
      }
    } catch (e) {
      print("Background refresh failed: $e");
    }
  }

  Future<bool> _fetchCropsFromAPI() async {
    try {
      print("Fetching crops from API...");
      final response = await http.get(
        Uri.parse('http://$ipaddress:3000/croprecommendation'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      print("API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("API Response: $data");

        if (data.isNotEmpty) {
          // Save to cache before processing
          await _saveToCache(data);
          
          _processCropData(data);
          setState(() {
            _isLoading = false;
          });
          return true;
        }
      }
    } catch (e) {
      print("API Error: $e");
    }
    
    return false;
  }

  Future<void> _loadCropsFromAssets() async {
    try {
      print("Loading crops from local assets...");
      
      String jsonString = await rootBundle.loadString('assets/crop_recommendation.json');
      final List<dynamic> data = json.decode(jsonString);
      
      print("Local JSON Data loaded: ${data.length} items");
      
      if (data.isNotEmpty) {
        // Save local data to cache as well
        await _saveToCache(data);
        
        _processCropData(data);
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _crops = [];
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print("Error loading from assets: $e");
      setState(() {
        _crops = [];
        _isLoading = false;
      });
    }
  }

  void _processCropData(List<dynamic> data) {
    Set<String> uniqueCropNames = {};
    List<Map<String, dynamic>> uniqueCrops = [];

    print("Processing ${data.length} crop items...");

    for (var item in data) {
      print("Processing item: $item");
      
      String cropName = item['Recommended_Crop']?.toString() ?? 
                       item['recommended_crop']?.toString() ?? 
                       item['name']?.toString() ?? 
                       item['crop_name']?.toString() ?? 
                       item['cropName']?.toString() ?? 
                       'Unknown Crop';
      
      String daysRequired = item['Days_Required']?.toString() ?? 
                           item['days_required']?.toString() ?? 
                           item['harvest_days']?.toString() ?? 
                           item['harvestDays']?.toString() ?? 
                           'N/A';
      
      String waterNeeded = item['Water_Needed']?.toString() ?? 
                          item['water_needed']?.toString() ?? 
                          item['water_requirement']?.toString() ?? 
                          item['waterRequirement']?.toString() ?? 
                          'N/A';
      
      String imageUrl = item['Crop_Image']?.toString() ?? 
                       item['crop_image']?.toString() ?? 
                       item['image']?.toString() ?? 
                       item['imageUrl']?.toString() ?? 
                       '';
      
      print("Processed: $cropName, Days: $daysRequired, Water: $waterNeeded");
      
      if (!uniqueCropNames.contains(cropName) && cropName != 'Unknown Crop') {
        uniqueCropNames.add(cropName);
        uniqueCrops.add({
          'name': cropName,
          'harvest': 'Harvest in $daysRequired days',
          'waterNeeded': waterNeeded,
          'image': imageUrl,
        });
      }
    }

    print("Final processed crops: ${uniqueCrops.length} unique items");

    setState(() {
      _crops = uniqueCrops;
    });
  }

  // Method to manually refresh data and clear cache
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    
    await _clearCache();
    await _fetchCrops();
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
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 20),

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

              Text(
                'Plan for Sowing',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),

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
    setState(() {
      _selectedCropName = crop['name'];
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropPlanningScreen(
          selectedCropName: _selectedCropName,
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
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.green,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh
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
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty 
                                      ? 'No crops available'
                                      : 'No crops found matching "$_searchQuery"',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                      child: Text('Clear search'),
                                    ),
                                ],
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
            ),
    );
  }
}