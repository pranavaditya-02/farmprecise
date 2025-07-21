import 'package:farmprecise/pages/chatbot/chatbotscreen.dart';
import 'package:farmprecise/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:farmprecise/pages/onboarding/login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from assets/.env
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    print("Error loading .env file: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class Started extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[700],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 80),
              Image.asset(
                'assets/logomain.png',
                height: 250,
              ),
              SizedBox(height: 10),
              Text(
                'Sproutelligence Farming Reimagined',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                'Empowering Farmers with Data-driven Solutions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15), // Adjust horizontal padding here
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            LoginScreen(), 
                      ),
                    );
                  },
                  icon: Image.network(
                    'https://cdn2.iconfinder.com/data/icons/apple-inspire-white/100/Apple-92-512.png',
                    height: 24,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Connect Your Farm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(
                          width: 8), 
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}