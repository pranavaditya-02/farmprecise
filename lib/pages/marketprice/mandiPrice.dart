import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MandiPricesScreen extends StatefulWidget {
  @override
  _MandiPricesScreenState createState() => _MandiPricesScreenState();
}

class _MandiPricesScreenState extends State<MandiPricesScreen> {
  List<MandiPrice> mandiPrices = [];
  List<MandiPrice> filteredPrices = [];
  bool isLoading = true;
  String? selectedState;
  String? selectedDistrict;
  String? selectedMarket;
  String? selectedCommodity;
  
  Set<String> states = {};
  Set<String> districts = {};
  Set<String> markets = {};
  Set<String> commodities = {};
  
  TextEditingController searchController = TextEditingController();
  int totalRecords = 0;

  // Cache configuration
  static const String CACHE_KEY = 'mandi_prices_cache';
  static const String CACHE_TIMESTAMP_KEY = 'mandi_prices_timestamp';
  static const Duration CACHE_DURATION = Duration(hours: 12); // Cache for 12 hours

  @override
  void initState() {
    super.initState();
    loadMandiPrices();
  }

  Future<void> loadMandiPrices({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      // Try to load from cache first
      final cachedData = await loadFromCache();
      if (cachedData != null) {
        setState(() {
          mandiPrices = cachedData;
          filteredPrices = cachedData;
          isLoading = false;
          totalRecords = cachedData.length;
          
          // Extract unique values for filters
          districts = cachedData.map((p) => p.district).toSet();
          markets = cachedData.map((p) => p.market).toSet();
          commodities = cachedData.map((p) => p.commodity).toSet();
        });
        return;
      }
    }

    // If no cached data or force refresh, fetch from API
    await fetchMandiPrices();
  }

  Future<List<MandiPrice>?> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(CACHE_KEY);
      final timestampMs = prefs.getInt(CACHE_TIMESTAMP_KEY);
      
      if (cachedJson != null && timestampMs != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
        final now = DateTime.now();
        
        // Check if cache is still valid
        if (now.difference(cacheTime) < CACHE_DURATION) {
          final List<dynamic> jsonList = json.decode(cachedJson);
          final List<MandiPrice> cachedPrices = jsonList
              .map((json) => MandiPrice.fromJson(json))
              .toList();
          
          return cachedPrices;
        }
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
    return null;
  }

  Future<void> saveToCache(List<MandiPrice> prices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prices.map((price) => price.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await prefs.setString(CACHE_KEY, jsonString);
      await prefs.setInt(CACHE_TIMESTAMP_KEY, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<void> fetchMandiPrices() async {
    try {
      // Get API key from environment, fallback to hardcoded if not found
      final apiKey = dotenv.env['MARKET_PRICE_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found');
      }

      // Step 1: Get total records with limit=1
      final metaResponse = await http.get(
        Uri.parse('https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?api-key=$apiKey&format=json&limit=9000'),
      );
      int recordCount = 0;
      if (metaResponse.statusCode == 200) {
        final metaData = json.decode(metaResponse.body);
        recordCount = int.tryParse(metaData['total']?.toString() ?? '0') ?? 0;
      }

      // Step 2: Fetch all records using the dynamic limit
      final response = await http.get(
        Uri.parse('https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?api-key=$apiKey&format=json&limit=$recordCount'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<MandiPrice> prices = [];

        for (var record in data['records']) {
          final mandiPrice = MandiPrice.fromJson(record);
          if (mandiPrice.state == 'Tamil Nadu') { 
            prices.add(mandiPrice);
          }
        }

        // Save to cache
        await saveToCache(prices);

        setState(() {
          mandiPrices = prices;
          filteredPrices = prices;
          isLoading = false;
          totalRecords = prices.length;

          // Extract unique values for filters (no state)
          districts = prices.map((p) => p.district).toSet();
          markets = prices.map((p) => p.market).toSet();
          commodities = prices.map((p) => p.commodity).toSet();
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void applyFilters() {
    setState(() {
      filteredPrices = mandiPrices.where((price) {
        bool matchesDistrict = selectedDistrict == null || price.district == selectedDistrict;
        bool matchesMarket = selectedMarket == null || price.market == selectedMarket;
        bool matchesCommodity = selectedCommodity == null || price.commodity == selectedCommodity;
        bool matchesSearch = searchController.text.isEmpty || 
            price.commodity.toLowerCase().contains(searchController.text.toLowerCase()) ||
            price.market.toLowerCase().contains(searchController.text.toLowerCase());
        
        return matchesDistrict && matchesMarket && matchesCommodity && matchesSearch;
      }).toList();
    });
  }

  // Get markets based on selected district
  List<String> getAvailableMarkets() {
    if (selectedDistrict == null) {
      return markets.toList();
    }
    return mandiPrices
        .where((price) => price.district == selectedDistrict)
        .map((price) => price.market)
        .toSet()
        .toList();
  }

  // Get commodities based on selected district and market
  List<String> getAvailableCommodities() {
    return mandiPrices.where((price) {
      bool matchesDistrict = selectedDistrict == null || price.district == selectedDistrict;
      bool matchesMarket = selectedMarket == null || price.market == selectedMarket;
      return matchesDistrict && matchesMarket;
    }).map((price) => price.commodity).toSet().toList();
  }

  void clearFilters() {
    setState(() {
      selectedDistrict = null;
      selectedMarket = null;
      selectedCommodity = null;
      searchController.clear();
      filteredPrices = mandiPrices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green[600],
        centerTitle: true,
        title: Text(
          'Market Prices',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Card(
            margin: EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.green[100]!,
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search commodity or market...',
                      prefixIcon: Icon(Icons.search, color: Colors.green[600]),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                      ),
                    ),
                    onChanged: (value) => applyFilters(),
                  ),
                  SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChipWithIcon(
                          icon: Icons.location_city,
                          label: 'District',
                          selectedValue: selectedDistrict,
                          options: districts.toList(),
                          onSelected: (value) {
                            setState(() {
                              selectedDistrict = value;
                              // Clear market and commodity when district changes
                              selectedMarket = null;
                              selectedCommodity = null;
                            });
                            applyFilters();
                          },
                        ),
                        SizedBox(width: 8),
                        _buildFilterChipWithIcon(
                          icon: Icons.store_mall_directory,
                          label: 'Market',
                          selectedValue: selectedMarket,
                          options: getAvailableMarkets(),
                          onSelected: (value) {
                            setState(() {
                              selectedMarket = value;
                              // Clear commodity when market changes
                              selectedCommodity = null;
                            });
                            applyFilters();
                          },
                        ),
                        SizedBox(width: 8),
                        _buildFilterChipWithIcon(
                          icon: Icons.shopping_basket,
                          label: 'Commodity',
                          selectedValue: selectedCommodity,
                          options: getAvailableCommodities(),
                          onSelected: (value) {
                            setState(() {
                              selectedCommodity = value;
                            });
                            applyFilters();
                          },
                        ),
                        SizedBox(width: 8),
                        // Clear Filters Button
                        if (selectedDistrict != null ||
                            selectedMarket != null ||
                            selectedCommodity != null)
                          ActionChip(
                            avatar: Icon(Icons.clear, color: Colors.red[700], size: 18),
                            label: Text('Clear All'),
                            onPressed: clearFilters,
                            backgroundColor: Colors.red[50],
                            labelStyle: TextStyle(color: Colors.red[700]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Price List
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingAnimationWidget.threeArchedCircle(
                          color: Colors.green[600]!,
                          size: 50,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading market prices...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredPrices.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredPrices.length,
                        itemBuilder: (context, index) {
                          return _buildPriceCard(filteredPrices[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? selectedValue, List<String> options, Function(String?) onSelected) {
    return FilterChip(
      label: Text(selectedValue ?? label),
      selected: selectedValue != null,
      onSelected: (bool selected) {
        if (options.isNotEmpty) {
          _showFilterDialog(label, options, selectedValue, onSelected);
        }
      },
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[700],
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: selectedValue != null ? Colors.green[600]! : Colors.grey[300]!,
      ),
    );
  }

  void _showFilterDialog(String title, List<String> options, String? selectedValue, Function(String?) onSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select $title'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: [
                ListTile(
                  title: Text('All ${title}s'),
                  leading: Radio<String?>(
                    value: null,
                    groupValue: selectedValue,
                    onChanged: (value) {
                      onSelected(value);
                      Navigator.pop(context);
                    },
                    activeColor: Colors.green[600],
                  ),
                ),
                ...options.map((option) => ListTile(
                  title: Text(option),
                  leading: Radio<String?>(
                    value: option,
                    groupValue: selectedValue,
                    onChanged: (value) {
                      onSelected(value);
                      Navigator.pop(context);
                    },
                    activeColor: Colors.green[600],
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: clearFilters,
            child: Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(MandiPrice price) {
    double priceSpread = price.maxPrice - price.minPrice;
    double spreadPercent = (priceSpread / price.modalPrice) * 100;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.green[100]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.commodity,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      if (price.variety != 'Other')
                        Text(
                          price.variety,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    price.grade,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Location Info
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${price.market}, ${price.district}, ${price.state}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Text(
                  price.arrivalDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Price Information
            Row(
              children: [
                Expanded(
                  child: _buildPriceInfo('Min Price', price.minPrice, Colors.red[600]!),
                ),
                Expanded(
                  child: _buildPriceInfo('Modal Price', price.modalPrice, Colors.green[700]!),
                ),
                Expanded(
                  child: _buildPriceInfo('Max Price', price.maxPrice, Colors.blue[600]!),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Price Spread Indicator
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Price Spread: ₹${priceSpread.toStringAsFixed(0)} (${spreadPercent.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, double price, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '₹${price.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChipWithIcon({
    required IconData icon,
    required String label,
    required String? selectedValue,
    required List<String> options,
    required Function(String?) onSelected,
  }) {
    return FilterChip(
      avatar: Icon(icon, size: 18, color: selectedValue != null ? Colors.green[700] : Colors.grey[500]),
      label: Text(selectedValue ?? label),
      selected: selectedValue != null,
      onSelected: (bool selected) {
        if (options.isNotEmpty) {
          _showFilterDialog(label, options, selectedValue, onSelected);
        }
      },
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[700],
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: selectedValue != null ? Colors.green[600]! : Colors.grey[300]!,
      ),
    );
  }
}

class MandiPrice {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String grade;
  final String arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;

  MandiPrice({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.grade,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
  });

  factory MandiPrice.fromJson(Map<String, dynamic> json) {
    return MandiPrice(
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      market: json['market'] ?? '',
      commodity: json['commodity'] ?? '',
      variety: json['variety'] ?? '',
      grade: json['grade'] ?? '',
      arrivalDate: json['arrival_date'] ?? '',
      minPrice: double.tryParse(json['min_price'].toString()) ?? 0.0,
      maxPrice: double.tryParse(json['max_price'].toString()) ?? 0.0,
      modalPrice: double.tryParse(json['modal_price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'district': district,
      'market': market,
      'commodity': commodity,
      'variety': variety,
      'grade': grade,
      'arrival_date': arrivalDate,
      'min_price': minPrice,
      'max_price': maxPrice,
      'modal_price': modalPrice,
    };
  }
}