import 'dart:convert';
import 'package:farmprecise/Ip.dart';
import 'package:farmprecise/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:farmprecise/pages/language_page.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  Future<void> _signup() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog('All fields are required');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showErrorDialog('Invalid email format');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://$ipaddress:3000/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'USERNAME': _usernameController.text,
          'EMAIL': _emailController.text,
          'PASSWORD': _passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        // Signup successful
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LanguageSelectionScreen()),
        );
      } else {
        // Signup failed
        _showErrorDialog('Signup failed');
      }
    } catch (error) {
      print('Error signing up: $error');
      _showErrorDialog('Error signing up');
    }

    setState(() {
      _isLoading = false;
    });
  }

  bool _isValidEmail(String email) {
    // Simple email validation regex
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(email);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Signup Failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fieldHeight = 48.0; // Reduced height
    final double fieldWidth = MediaQuery.of(context).size.width - 48.0;
    final double buttonHeight = 40.0; // Reduced height
    final double buttonWidth = fieldWidth - 16.0;
    final double signUpButtonHeight = 48.0; // Reduced height
    final double signUpButtonWidth = fieldWidth;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 24.0),
              Text(
                'SIGN UP',
                style: TextStyle(
                  fontSize: 28.0, // Reduced font size
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'Create your Account',
                style: TextStyle(
                  fontSize: 14.0, // Reduced font size
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 16.0),
              SizedBox(
                height: fieldHeight,
                width: fieldWidth,
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 12.0), // Reduced gap between fields
              SizedBox(
                height: fieldHeight,
                width: fieldWidth,
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(height: 12.0), // Reduced gap between fields
              SizedBox(
                height: fieldHeight,
                width: fieldWidth,
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.0), // Reduced gap between fields
              SizedBox(
                height: fieldHeight,
                width: fieldWidth,
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmText,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmText
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmText = !_obscureConfirmText;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.0),
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      height: signUpButtonHeight,
                      width: signUpButtonWidth,
                      child: ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0, // Reduced font size
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: 16.0),
              Text('or', style: TextStyle(fontSize: 14.0, color: Colors.grey)),
              SizedBox(height: 16.0),
              // Rest of your widgets...
// Continuing from the previous code snippet...

              SizedBox(
                height: buttonHeight,
                width: buttonWidth,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Image.network(
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS78fWMyZTFLKJ9OlVW-1sKiiZWP2A8BHfUnw&s',
                    height: 18.0,
                  ),
                  label: Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              SizedBox(
                height: buttonHeight,
                width: buttonWidth,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.apple, size: 18, color: Colors.black),
                  label: Text('Continue with Apple'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              SizedBox(
                height: buttonHeight,
                width: buttonWidth,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.business, size: 18, color: Colors.black),
                  label: Text('Continue with SSO'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              SizedBox(
                height: buttonHeight,
                width: buttonWidth,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.facebook, size: 18, color: Colors.black),
                  label: Text('Continue with Facebook'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),
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
