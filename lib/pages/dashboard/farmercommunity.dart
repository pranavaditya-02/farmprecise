import 'package:farmprecise/Ip.dart';
import 'package:farmprecise/components/bottom_navigation.dart';
import 'package:farmprecise/components/custom_appbar.dart';
import 'package:farmprecise/components/custom_drawer.dart';
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
  
  // Color scheme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  
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
                      likesCount: post['likesCount'] ?? 0,
                      isLiked: post['isLiked'] ?? false,
                      replies: (post['replies'] as List<dynamic>?)
                          ?.map((reply) => Reply.fromJson(reply))
                          .toList() ?? [],
                      onLike: _handleLike,
                      onReply: _handleReply,
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
                commentsCount: post['commentsCount'] ?? 0,
                likesCount: post['likesCount'] ?? 0,
                isLiked: post['isLiked'] ?? false,
                replies: (post['replies'] as List<dynamic>?)
                    ?.map((reply) => Reply.fromJson(reply))
                    .toList() ?? [],
                onLike: _handleLike,
                onReply: _handleReply,
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
              likesCount: post['likesCount'] ?? 0,
              isLiked: post['isLiked'] ?? false,
              replies: (post['replies'] as List<dynamic>?)
                  ?.map((reply) => Reply.fromJson(reply))
                  .toList() ?? [],
              onLike: _handleLike,
              onReply: _handleReply,
            ))
        .toList();
  }

  void _handleLike(PostItem post) {
    setState(() {
      final index = _posts.indexOf(post);
      if (index != -1) {
        _posts[index] = PostItem(
          username: post.username,
          date: post.date,
          title: post.title,
          content: post.content,
          commentsCount: post.commentsCount,
          likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
          isLiked: !post.isLiked,
          replies: post.replies,
          onLike: _handleLike,
          onReply: _handleReply,
        );
        _filteredPosts = _posts;
      }
    });
    _showSnackBar(post.isLiked ? 'Post unliked' : 'Post liked!');
  }

  void _handleReply(PostItem post) {
    _showReplyDialog(context, post);
  }

  void _showReplyDialog(BuildContext context, PostItem post) {
    final replyController = TextEditingController();
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.reply, color: primaryGreen),
              SizedBox(width: 8),
              Text('Reply to ${post.username}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: lightGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        post.content,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                _buildTextField(usernameController, 'Your Username'),
                SizedBox(height: 8),
                _buildTextField(replyController, 'Your Reply', maxLines: 3),
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
                    replyController.text.trim().isNotEmpty) {
                  _addReply(post, usernameController.text.trim(), replyController.text.trim());
                  Navigator.of(context).pop();
                } else {
                  _showSnackBar('Please fill in all fields');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text('Reply', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _addReply(PostItem post, String username, String content) {
    setState(() {
      final index = _posts.indexOf(post);
      if (index != -1) {
        final newReply = Reply(
          username: username,
          content: content,
          date: DateTime.now().toIso8601String(),
        );
        
        final updatedReplies = List<Reply>.from(post.replies)..add(newReply);
        
        _posts[index] = PostItem(
          username: post.username,
          date: post.date,
          title: post.title,
          content: post.content,
          commentsCount: post.commentsCount + 1,
          likesCount: post.likesCount,
          isLiked: post.isLiked,
          replies: updatedReplies,
          onLike: _handleLike,
          onReply: _handleReply,
        );
        _filteredPosts = _posts;
      }
    });
    _showSnackBar('Reply added successfully!');
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
          likesCount: 0,
          isLiked: false,
          replies: [],
          onLike: _handleLike,
          onReply: _handleReply,
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
          'likesCount': 0,
          'isLiked': false,
          'replies': [],
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
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: CustomDrawer(onItemTapped: _onItemTapped),
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: primaryGreen,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section (Original Style)
              Stack(
                children: [
                  Container(
                    height: 270,
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
                    height: 270,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome To The Community!',
                          style: TextStyle(
                            fontSize: 22,
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
                  // Active users indicator
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: lightGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${_posts.length} Active',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 15),
              
              // Enhanced Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search discussions...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: lightGreen),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
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
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: _searchPosts,
                  ),
                ),
              ),
              
              SizedBox(height: 10),
              
              // Content Section
              if (_isLoading && _posts.isEmpty)
                Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading community posts...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredPosts.isEmpty && _lastSearchQuery != null)
                _buildEmptySearchState()
              else if (_filteredPosts.isEmpty)
                _buildEmptyState()
              else
                ..._filteredPosts,
              
              SizedBox(height: 100), // Extra space for FAB
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

  Widget _buildEmptySearchState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 48,
                color: lightGreen,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Start the Conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to share your thoughts\nand connect with the community',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
          ],
        ),
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
                backgroundColor: primaryGreen,
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

class Reply {
  final String username;
  final String content;
  final String date;

  Reply({
    required this.username,
    required this.content,
    required this.date,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      username: json['username'] ?? '',
      content: json['content'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'content': content,
      'date': date,
    };
  }
}

class PostItem extends StatelessWidget {
  final String username;
  final String date;
  final String title;
  final String content;
  final int commentsCount;
  final int likesCount;
  final bool isLiked;
  final List<Reply> replies;
  final Function(PostItem) onLike;
  final Function(PostItem) onReply;

  // Color scheme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);

  PostItem({
    required this.username,
    required this.date,
    required this.title,
    required this.content,
    required this.commentsCount,
    required this.likesCount,
    required this.isLiked,
    required this.replies,
    required this.onLike,
    required this.onReply,
  });

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateStr;
    }
  }

  void _showRepliesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: primaryGreen),
              SizedBox(width: 8),
              Text('Replies (${replies.length})'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: replies.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No replies yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Be the first to reply!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: replies.length,
                    itemBuilder: (context, index) {
                      final reply = replies[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lightGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: lightGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors: [lightGreen, accentGreen],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      reply.username.isNotEmpty ? reply.username[0].toUpperCase() : 'U',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reply.username,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: primaryGreen,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(reply.date),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              reply.content,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onReply(this);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text('Add Reply', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: lightGreen.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Handle post tap
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [lightGreen, accentGreen],
                          ),
                          border: Border.all(
                            color: primaryGreen.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: primaryGreen,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _formatDate(date),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [lightGreen.withOpacity(0.1), accentGreen.withOpacity(0.1)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: lightGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: lightGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Post Title
                  Container(
                    padding: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: lightGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        height: 1.3,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Post Content
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: lightGreen.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Action Row
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: lightGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildActionButton(
                          icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          label: 'Like',
                          count: likesCount,
                          isActive: isLiked,
                          onTap: () => onLike(this),
                        ),
                        Spacer(),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'Reply',
                          count: commentsCount,
                          onTap: () => _showRepliesDialog(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    int? count,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? lightGreen.withOpacity(0.2) 
              : lightGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
                ? lightGreen.withOpacity(0.4) 
                : lightGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? primaryGreen : primaryGreen.withOpacity(0.8),
            ),
            SizedBox(width: 6),
            if (count != null && count > 0) ...[
              Text(
                '$count',
                style: TextStyle(
                  color: isActive ? primaryGreen : primaryGreen.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? primaryGreen : primaryGreen.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}