import 'package:flutter/material.dart';
import 'package:farmprecise/pages/farmsetup.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LanguageSelectionScreen(),
    );
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  @override
  _LanguageSelectionScreenState createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),
            Text(
              'Please select your language',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold), // Increased font size
            ),
            SizedBox(height: 8),
            Text(
              'Select your preferred language to continue', // New message
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: Colors.grey), // Increased font size
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2, // Adjusted for larger boxes
                mainAxisSpacing: 16, // Gap between rows
                crossAxisSpacing: 16, // Gap between columns
                children: [
                  _buildLanguageButton('Hindi', 'हिन्दी'),
                  _buildLanguageButton('English', 'English'),
                  _buildLanguageButton('Marathi', 'मराठी'),
                  _buildLanguageButton('Tamil', 'தமிழ்'),
                  _buildLanguageButton('Telugu', 'తెలుగు'),
                  _buildLanguageButton('Kannada', 'ಕನ್ನಡ'),
                  _buildLanguageButton('Bengali', 'বাংলা'),
                  _buildLanguageButton('Punjabi', 'ਪੰਜਾਬੀ'),
                ],
              ),
            ),
            SizedBox(height: 10), // Adjusted spacing
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FarmSetupForm()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16), // Adjusted padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                    fontSize: 18, color: Colors.white), // Increased font size
              ),
            ),
            SizedBox(height: 10), // Adjusted spacing
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String language, String script) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLanguage = language;
        });
      },
      child: Container(
        margin:
            EdgeInsets.symmetric(horizontal: 8.0), // Horizontal padding for gap
        decoration: BoxDecoration(
          color:
              selectedLanguage == language ? Colors.green : Colors.transparent,
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(8),
        ),
        padding:
            EdgeInsets.symmetric(vertical: 1), // Increased padding for height
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              language,
              style: TextStyle(
                fontSize: 20, // Increased font size
                color:
                    selectedLanguage == language ? Colors.white : Colors.black,
              ),
            ),
            Text(
              script,
              style: TextStyle(
                fontSize: 20, // Increased font size
                color:
                    selectedLanguage == language ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
