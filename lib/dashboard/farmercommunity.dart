import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:farmprecise/dashboard/dashboard.dart';
import 'package:farmprecise/pages/homepage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.green,
        hintColor: Colors.greenAccent,
        scaffoldBackgroundColor: Colors.lightGreen[300],
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
      ),
      home: Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    CommunityScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text(
          'Farm Precise',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: true,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green,
                ),
                accountName: Text(
                  'John Doe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  'john.doe@example.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    'JD',
                    style: TextStyle(
                      fontSize: 24.0,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home, color: Colors.green),
                title: Text('Home'),
                onTap: () {
                  _onItemTapped(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.people, color: Colors.green),
                title: Text('Community'),
                onTap: () {
                  _onItemTapped(2);
                  Navigator.pop(context);
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.green),
                title: Text('Logout'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Started()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        selectedFontSize: 14.0,
        unselectedFontSize: 14.0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          
          
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
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

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  void _fetchPosts() async {
    final response =
        await http.get(Uri.parse('http://10.11.255.10:3000/community'));

    if (response.statusCode == 200) {
      final List<dynamic> postsJson = json.decode(response.body);
      setState(() {
        _posts = postsJson
            .map((post) => PostItem(
                  username: post['USERNAME'],
                  date: post['DATE'],
                  title: post['TITLE'],
                  content: post['CONTENT'],
                  commentsCount: 0, // Assuming comments count is not available
                ))
            .toList();
        _filteredPosts = _posts;
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  void _searchPosts(String query) {
    final filtered = _posts.where((post) {
      final postContent = post.content.toLowerCase();
      final searchQuery = query.toLowerCase();
      return postContent.contains(searchQuery);
    }).toList();
    setState(() {
      _filteredPosts = filtered;
    });
  }

  void _addNewPost(String username, String title, String content) async {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final response = await http.post(
      Uri.parse('http://10.11.255.10:3000/community'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'USERNAME': username,
        'TITLE': title,
        'CONTENT': content,
        'DATE': date,
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        _posts.add(PostItem(
          username: username,
          date: date,
          title: title,
          content: content,
          commentsCount: 0,
        ));
        _filteredPosts = _posts;
      });
    } else {
      throw Exception('Failed to add post');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _searchPosts,
              ),
            ),
            SizedBox(height: 16),
            ..._filteredPosts,
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPostDialog(context),
        backgroundColor: Colors.green.withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(usernameController, 'Username'),
              SizedBox(height: 8),
              _buildTextField(titleController, 'Title'),
              SizedBox(height: 8),
              _buildTextField(contentController, 'Content', maxLines: 3),
            ],
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
                _addNewPost(
                  usernameController.text,
                  titleController.text,
                  contentController.text,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(date, style: TextStyle(color: Colors.grey)),
                    ],
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
