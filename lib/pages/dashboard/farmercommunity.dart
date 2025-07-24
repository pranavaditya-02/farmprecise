import 'package:farmprecise/Ip.dart';
import 'package:farmprecise/components/bottom_navigation.dart';
import 'package:farmprecise/components/custom_appbar.dart';
import 'package:farmprecise/components/custom_drawer.dart';
import 'package:farmprecise/pages/crops/cropcalendar.dart';
import 'package:farmprecise/pages/cropscanner/cropscannner.dart';
import 'package:farmprecise/pages/drone/dronedetails.dart';
import 'package:farmprecise/pages/homepage.dart';
import 'package:farmprecise/pages/rent/rentpage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String POSTS_CACHE_KEY = 'cached_posts';
  static const String CACHE_TIMESTAMP_KEY = 'cache_timestamp';
  static const Duration CACHE_DURATION = Duration(hours: 12); 
  
  static Future<void> cachePosts(List<Map<String, dynamic>> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = jsonEncode(posts);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setString(POSTS_CACHE_KEY, postsJson);
    await prefs.setInt(CACHE_TIMESTAMP_KEY, timestamp);
  }
  
  static Future<List<Map<String, dynamic>>?> getCachedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPostsJson = prefs.getString(POSTS_CACHE_KEY);
    final cacheTimestamp = prefs.getInt(CACHE_TIMESTAMP_KEY);
    
    if (cachedPostsJson == null || cacheTimestamp == null) {
      return null;
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final cacheAge = Duration(milliseconds: now - cacheTimestamp);
    
    if (cacheAge > CACHE_DURATION) {
      await clearCache();
      return null;
    }
    
    final List<dynamic> postsJson = jsonDecode(cachedPostsJson);
    return postsJson.cast<Map<String, dynamic>>();
  }
  
  static Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheTimestamp = prefs.getInt(CACHE_TIMESTAMP_KEY);
    
    if (cacheTimestamp == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final cacheAge = Duration(milliseconds: now - cacheTimestamp);
    
    return cacheAge <= CACHE_DURATION;
  }
  
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(POSTS_CACHE_KEY);
    await prefs.remove(CACHE_TIMESTAMP_KEY);
  }
  
  static Future<void> addPostToCache(Map<String, dynamic> newPost) async {
    final cachedPosts = await getCachedPosts();
    if (cachedPosts != null) {
      cachedPosts.add(newPost);
      await cachePosts(cachedPosts);
    }
  }
}

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PostItem> _posts = [];
  List<PostItem> _filteredPosts = [];
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _lastSearchQuery;
  
  // In-memory cache for search results
  Map<String, List<PostItem>> _searchCache = {};
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts({bool forceRefresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to load from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedPosts = await CacheManager.getCachedPosts();
        if (cachedPosts != null) {
          setState(() {
            _posts = cachedPosts
                .map((post) => PostItem(
                      username: post['USERNAME'],
                      date: post['DATE'],
                      title: post['TITLE'],
                      content: post['CONTENT'],
                      commentsCount: post['commentsCount'] ?? 0,
                    ))
                .toList();
            _filteredPosts = _posts;
            _isLoading = false;
          });
          return;
        }
      }

      // Fetch from server
      await _fetchPostsFromServer();
    } catch (e) {
      // If network fails, try to load stale cache
      final cachedPosts = await _loadStaleCache();
      if (cachedPosts != null) {
        setState(() {
          _posts = cachedPosts;
          _filteredPosts = _posts;
        });
        _showSnackBar('Loaded cached data. Pull to refresh for latest posts.');
      } else {
        _showSnackBar('Failed to load posts. Please check your connection.');
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _fetchPostsFromServer() async {
    final response = await http.get(
      Uri.parse('http://$ipaddress:3000/community'),
      headers: {'Cache-Control': 'no-cache'},
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> postsJson = json.decode(response.body);
      final posts = postsJson
          .map((post) => PostItem(
                username: post['USERNAME'],
                date: post['DATE'],
                title: post['TITLE'],
                content: post['CONTENT'],
                commentsCount: 0,
              ))
          .toList();

      // Cache the posts
      await CacheManager.cachePosts(postsJson.cast<Map<String, dynamic>>());

      setState(() {
        _posts = posts;
        _filteredPosts = _posts;
      });
      
      // Clear search cache when new data is loaded
      _searchCache.clear();
    } else {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  Future<List<PostItem>?> _loadStaleCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPostsJson = prefs.getString(CacheManager.POSTS_CACHE_KEY);
    
    if (cachedPostsJson == null) return null;
    
    final List<dynamic> postsJson = jsonDecode(cachedPostsJson);
    return postsJson
        .map((post) => PostItem(
              username: post['USERNAME'],
              date: post['DATE'],
              title: post['TITLE'],
              content: post['CONTENT'],
              commentsCount: post['commentsCount'] ?? 0,
            ))
        .toList();
  }

  void _searchPosts(String query) {
    // Use cached search results if available
    if (_searchCache.containsKey(query)) {
      setState(() {
        _filteredPosts = _searchCache[query]!;
        _lastSearchQuery = query;
      });
      return;
    }

    final filtered = _posts.where((post) {
      final postContent = post.content.toLowerCase();
      final postTitle = post.title.toLowerCase();
      final searchQuery = query.toLowerCase();
      return postContent.contains(searchQuery) || postTitle.contains(searchQuery);
    }).toList();

    // Cache the search result
    _searchCache[query] = filtered;
    
    setState(() {
      _filteredPosts = filtered;
      _lastSearchQuery = query;
    });
  }

  Future<void> _addNewPost(String username, String title, String content) async {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://$ipaddress:3000/community'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'USERNAME': username,
          'TITLE': title,
          'CONTENT': content,
          'DATE': date,
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 201) {
        final newPost = PostItem(
          username: username,
          date: date,
          title: title,
          content: content,
          commentsCount: 0,
        );

        setState(() {
          _posts.insert(0, newPost); // Add to beginning
          _filteredPosts = _posts;
        });

        // Update cache
        await CacheManager.addPostToCache({
          'USERNAME': username,
          'TITLE': title,
          'CONTENT': content,
          'DATE': date,
          'commentsCount': 0,
        });

        // Clear search cache as data has changed
        _searchCache.clear();
        
        _showSnackBar('Post added successfully!');
      } else {
        throw Exception('Failed to add post: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Failed to add post. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadPosts(forceRefresh: true);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: CustomDrawer(onItemTapped: _onItemTapped),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://mitsloanedtech.mit.edu/wp-content/uploads/2022/01/Blog_FourTipsToDesignAnEngagingDiscussionInCanvas.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                  ),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome To The Community!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Text(
                            'Ask a question & help\nprovide answers to people\'s questions.',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cache status indicator
                  if (_isRefreshing)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Refreshing...',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for a question',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _filteredPosts = _posts;
                                _lastSearchQuery = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: _searchPosts,
                ),
              ),
              SizedBox(height: 16),
              if (_isLoading && _posts.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filteredPosts.isEmpty && _lastSearchQuery != null)
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No posts found for "${_lastSearchQuery}"',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else if (_filteredPosts.isEmpty)
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.forum, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          'Be the first to start a discussion!',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._filteredPosts,
              SizedBox(height: 80), // Extra space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : () => _showAddPostDialog(context),
        backgroundColor: _isLoading 
            ? Colors.grey 
            : Colors.green.withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isLoading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 2,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  void _showAddPostDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(usernameController, 'Username'),
                SizedBox(height: 8),
                _buildTextField(titleController, 'Title'),
                SizedBox(height: 8),
                _buildTextField(contentController, 'Content', maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (usernameController.text.trim().isNotEmpty &&
                    titleController.text.trim().isNotEmpty &&
                    contentController.text.trim().isNotEmpty) {
                  _addNewPost(
                    usernameController.text.trim(),
                    titleController.text.trim(),
                    contentController.text.trim(),
                  );
                  Navigator.of(context).pop();
                } else {
                  _showSnackBar('Please fill in all fields');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class PostItem extends StatelessWidget {
  final String username;
  final String date;
  final String title;
  final String content;
  final int commentsCount;

  PostItem({
    required this.username,
    required this.date,
    required this.title,
    required this.content,
    required this.commentsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://icons.veryicon.com/png/o/internet--web/prejudice/user-128.png',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(date, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(content),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.comment, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('$commentsCount Comments',
                      style: TextStyle(color: Colors.grey)),
                  Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text('Reply'),
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