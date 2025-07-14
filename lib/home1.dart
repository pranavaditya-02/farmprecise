// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io';

// void main() {
//   runApp(ProjectKisanApp());
// }

// class ProjectKisanApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Project Kisan',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: HomeScreen(),
//     );
//   }
// }

// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('FarmPrecise'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.green[50]!, Colors.white],
//           ),
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               SizedBox(height: 40),
//               Text(
//                 '🌾 Welcome to FarmPrecise',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green[800],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Your Smart Agricultural Assistant',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 60),
//               _buildFeatureCard(
//                 context,
//                 '🤖 Talk to Kisan',
//                 'Your Smart Agri Assistant',
//                 Colors.blue,
//                 () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => KisanAssistantScreen()),
//                 ),
//               ),
//               SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildSmallFeatureCard(
//                       context,
//                       '📱 Quick Access',
//                       'Instant Help',
//                       Colors.orange,
//                       () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => KisanAssistantScreen()),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: _buildSmallFeatureCard(
//                       context,
//                       '🌱 Farm Tools',
//                       'All Services',
//                       Colors.purple,
//                       () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => KisanAssistantScreen()),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFeatureCard(BuildContext context, String title, String subtitle, Color color, VoidCallback onTap) {
//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           padding: EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: LinearGradient(
//               colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
//             ),
//           ),
//           child: Column(
//             children: [
//               Icon(Icons.smart_toy, size: 48, color: color),
//               SizedBox(height: 16),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSmallFeatureCard(BuildContext context, String title, String subtitle, Color color, VoidCallback onTap) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Icon(Icons.agriculture, size: 32, color: color),
//               SizedBox(height: 8),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 4),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class KisanAssistantScreen extends StatefulWidget {
//   @override
//   _KisanAssistantScreenState createState() => _KisanAssistantScreenState();
// }

// class _KisanAssistantScreenState extends State<KisanAssistantScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('🤖 Kisan Assistant'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.green[50]!, Colors.white],
//           ),
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               SizedBox(height: 20),
//               Text(
//                 'How can I help you today?',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green[800],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 40),
//               _buildServiceCard(
//                 context,
//                 '📷 Diagnose Plant Disease',
//                 'Upload or take a photo of your plant',
//                 Colors.red,
//                 Icons.camera_alt,
//                 () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => DiseaseDiagnosisScreen()),
//                 ),
//               ),
//               SizedBox(height: 16),
//               _buildServiceCard(
//                 context,
//                 '📊 Check Today\'s Prices',
//                 'Get current market prices for crops',
//                 Colors.orange,
//                 Icons.trending_up,
//                 () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => MarketPricesScreen()),
//                 ),
//               ),
//               SizedBox(height: 16),
//               _buildServiceCard(
//                 context,
//                 '🏛️ Get Scheme Info',
//                 'Find government schemes and subsidies',
//                 Colors.blue,
//                 Icons.account_balance,
//                 () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => GovernmentSchemesScreen()),
//                 ),
//               ),
//               SizedBox(height: 40),
//               FloatingActionButton.extended(
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => VoiceChatScreen()),
//                 ),
//                 icon: Icon(Icons.mic),
//                 label: Text('🎙️ Voice Chat'),
//                 backgroundColor: Colors.green[600],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceCard(BuildContext context, String title, String subtitle, Color color, IconData icon, VoidCallback onTap) {
//     return Card(
//       elevation: 6,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: LinearGradient(
//               colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(icon, size: 32, color: color),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: color,
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(Icons.arrow_forward_ios, color: color),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class VoiceChatScreen extends StatefulWidget {
//   @override
//   _VoiceChatScreenState createState() => _VoiceChatScreenState();
// }

// class _VoiceChatScreenState extends State<VoiceChatScreen> {
//   final SpeechToText _speechToText = SpeechToText();
//   final TextEditingController _textController = TextEditingController();
  
//   List<ChatMessage> _messages = [];
//   bool _isListening = false;
//   bool _isLoading = false;
//   bool _speechEnabled = false;

//   @override
//   void initState() {
//     super.initState();
//     _initSpeech();
//   }

//   void _initSpeech() async {
//     _speechEnabled = await _speechToText.initialize();
//     setState(() {});
//   }

//   void _startListening() async {
//     if (_speechEnabled) {
//       await _speechToText.listen(
//         onResult: _onSpeechResult,
//         localeId: 'en_US',
//       );
//       setState(() {
//         _isListening = true;
//       });
//     }
//   }

//   void _stopListening() async {
//     await _speechToText.stop();
//     setState(() {
//       _isListening = false;
//     });
//   }

//   void _onSpeechResult(result) {
//     setState(() {
//       _textController.text = result.recognizedWords;
//     });
//   }

//   void _sendMessage() async {
//     if (_textController.text.isEmpty) return;

//     String userMessage = _textController.text;
//     _textController.clear();

//     setState(() {
//       _messages.add(ChatMessage(text: userMessage, isUser: true));
//       _isLoading = true;
//     });

//     // Call Gemini API
//     String response = await _callGeminiAPI(userMessage);
    
//     setState(() {
//       _messages.add(ChatMessage(text: response, isUser: false));
//       _isLoading = false;
//     });
//   }

//   Future<String> _callGeminiAPI(String prompt) async {
//     try {
//       final response = await http.post(
//         Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'),
//         headers: {
//           'Content-Type': 'application/json',
//           'X-goog-api-key': 'AIzaSyCJJ1esglN4bxEtSGHN7a0tGCEHE4nG-cQ', // Replace with your actual API key
//         },
//         body: jsonEncode({
//           'contents': [
//             {
//               'parts': [
//                 {'text': 'You are Kisan, a helpful agricultural assistant. Answer in a friendly, simple manner suitable for farmers. Question: $prompt'}
//               ]
//             }
//           ]
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['candidates'][0]['content']['parts'][0]['text'];
//       } else {
//         return 'Sorry, I couldn\'t process your request right now. Please try again.';
//       }
//     } catch (e) {
//       return 'Network error. Please check your connection and try again.';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('🎙️ Voice Chat with Kisan'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.green[50]!, Colors.white],
//           ),
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 padding: EdgeInsets.all(16),
//                 itemCount: _messages.length,
//                 itemBuilder: (context, index) {
//                   return _buildMessageBubble(_messages[index]);
//                 },
//               ),
//             ),
//             if (_isLoading)
//               Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(width: 16),
//                     Text('Kisan is thinking...'),
//                   ],
//                 ),
//               ),
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.2),
//                     spreadRadius: 1,
//                     blurRadius: 5,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _textController,
//                       decoration: InputDecoration(
//                         hintText: 'Type your message or use voice...',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       ),
//                       onSubmitted: (_) => _sendMessage(),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   FloatingActionButton.small(
//                     onPressed: _isListening ? _stopListening : _startListening,
//                     backgroundColor: _isListening ? Colors.red : Colors.green,
//                     child: Icon(_isListening ? Icons.mic_off : Icons.mic),
//                   ),
//                   SizedBox(width: 8),
//                   FloatingActionButton.small(
//                     onPressed: _sendMessage,
//                     backgroundColor: Colors.blue,
//                     child: Icon(Icons.send),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageBubble(ChatMessage message) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       child: Row(
//         mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         children: [
//           if (!message.isUser)
//             CircleAvatar(
//               backgroundColor: Colors.green,
//               child: Text('K', style: TextStyle(color: Colors.white)),
//             ),
//           SizedBox(width: 8),
//           Flexible(
//             child: Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: message.isUser ? Colors.blue[100] : Colors.grey[200],
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Text(
//                 message.text,
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//           ),
//           SizedBox(width: 8),
//           if (message.isUser)
//             CircleAvatar(
//               backgroundColor: Colors.blue,
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class DiseaseDiagnosisScreen extends StatefulWidget {
//   @override
//   _DiseaseDiagnosisScreenState createState() => _DiseaseDiagnosisScreenState();
// }

// class _DiseaseDiagnosisScreenState extends State<DiseaseDiagnosisScreen> {
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();
//   final TextEditingController _noteController = TextEditingController();
//   bool _isAnalyzing = false;
//   DiagnosisResult? _result;

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final XFile? image = await _picker.pickImage(source: source);
//       if (image != null) {
//         setState(() {
//           _selectedImage = File(image.path);
//           _result = null;
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error picking image: $e')),
//       );
//     }
//   }

//   Future<void> _analyzeImage() async {
//     if (_selectedImage == null) return;

//     setState(() {
//       _isAnalyzing = true;
//     });

//     // Simulate analysis delay
//     await Future.delayed(Duration(seconds: 3));

//     // Mock result
//     setState(() {
//       _result = DiagnosisResult(
//         disease: 'Tomato Leaf Blight',
//         cause: 'Fungal infection caused by excess moisture',
//         treatment: 'Apply copper-based fungicide spray every 7 days',
//         confidence: 85,
//         remedyPrice: '₹120-150 per bottle',
//       );
//       _isAnalyzing = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('📷 Disease Diagnosis'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.green[50]!, Colors.white],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Container(
//                   height: 200,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(16),
//                     color: Colors.grey[100],
//                   ),
//                   child: _selectedImage != null
//                       ? ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: Image.file(_selectedImage!, fit: BoxFit.cover),
//                         )
//                       : Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.camera_alt, size: 48, color: Colors.grey[400]),
//                             SizedBox(height: 16),
//                             Text('Upload or take a photo of your plant'),
//                           ],
//                         ),
//                 ),
//               ),
//               SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => _pickImage(ImageSource.camera),
//                       icon: Icon(Icons.camera_alt),
//                       label: Text('Take Photo'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green[600],
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.symmetric(vertical: 12),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => _pickImage(ImageSource.gallery),
//                       icon: Icon(Icons.photo_library),
//                       label: Text('Gallery'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue[600],
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.symmetric(vertical: 12),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: _noteController,
//                 decoration: InputDecoration(
//                   labelText: 'Additional notes (optional)',
//                   hintText: 'e.g., leaves turning yellow, spots on fruit',
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 maxLines: 3,
//               ),
//               SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: _selectedImage != null && !_isAnalyzing ? _analyzeImage : null,
//                 child: _isAnalyzing
//                     ? Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CircularProgressIndicator(color: Colors.white),
//                           SizedBox(width: 16),
//                           Text('Analyzing...'),
//                         ],
//                       )
//                     : Text('Analyze Disease'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red[600],
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(vertical: 16),
//                 ),
//               ),
//               if (_result != null) ...[
//                 SizedBox(height: 24),
//                 Card(
//                   elevation: 6,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Diagnosis Result',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.red[600],
//                           ),
//                         ),
//                         SizedBox(height: 16),
//                         _buildResultItem('Disease', _result!.disease),
//                         _buildResultItem('Cause', _result!.cause),
//                         _buildResultItem('Treatment', _result!.treatment),
//                         _buildResultItem('Confidence', '${_result!.confidence}%'),
//                         _buildResultItem('Remedy Price', _result!.remedyPrice),
//                         SizedBox(height: 16),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: ElevatedButton.icon(
//                                 onPressed: () => setState(() {
//                                   _selectedImage = null;
//                                   _result = null;
//                                   _noteController.clear();
//                                 }),
//                                 icon: Icon(Icons.refresh),
//                                 label: Text('Analyze Another'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.green[600],
//                                   foregroundColor: Colors.white,
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 16),
//                             Expanded(
//                               child: ElevatedButton.icon(
//                                 onPressed: () {
//                                   // Share functionality
//                                 },
//                                 icon: Icon(Icons.share),
//                                 label: Text('Share'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue[600],
//                                   foregroundColor: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildResultItem(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 80,
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class MarketPricesScreen extends StatefulWidget {
//   @override
//   _MarketPricesScreenState createState() => _MarketPricesScreenState();
// }

// class _MarketPricesScreenState extends State<MarketPricesScreen> {
//   final TextEditingController _cropController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();
//   List<MarketPrice> _prices = [];
//   bool _isLoading = false;

//   Future<void> _fetchPrices() async {
//     if (_cropController.text.isEmpty || _locationController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please enter both crop and location')),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     // Simulate API call
//     await Future.delayed(Duration(seconds: 2));

//     setState(() {
//       _prices = [
//         MarketPrice(
//           crop: _cropController.text,
//           market: 'Mysuru Mandi',
//           price: '₹45/kg',
//           trend: 'up',
//           lastUpdated: 'Today 10:30 AM',
//         ),
//         MarketPrice(
//           crop: _cropController.text,
//           market: 'Bangalore APMC',
//           price: '₹42/kg',
//           trend: 'down',
//           lastUpdated: 'Today 9:15 AM',
//         ),
//         MarketPrice(
//           crop: _cropController.text,
//           market: 'Mandya Market',
//           price: '₹48/kg',
//           trend: 'up',
//           lastUpdated: 'Today 11:00 AM',
//         ),
//       ];
//       _isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('📊 Market Prices'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.green[50]!, Colors.white],
//           ),
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     children: [
//                       TextField(
//                         controller: _cropController,
//                         decoration: InputDecoration(
//                           labelText: 'Crop Name',
//                           hintText: 'e.g., Tomato, Rice, Wheat',
//                           prefixIcon: Icon(Icons.eco),
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       TextField(
//                         controller: _locationController,
//                         decoration: InputDecoration(
//                           labelText: 'Location',
//                           hintText: 'e.g., Mysuru, Bangalore',
//                           prefixIcon: Icon(Icons.location_on),
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       ElevatedButton(
//                         onPressed: _isLoading ? null : _fetchPrices,
//                         child: _isLoading
//                             ? Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   CircularProgressIndicator(color: Colors.white),
//                                   SizedBox(width: 16),
//                                   Text('Loading...'),
//                                 ],
//                               )
//                             : Text('Get Prices'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange[600],
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 16),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),
//               if (_prices.isNotEmpty)
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: _prices.length,
//                     itemBuilder: (context, index) {
//                       return _buildPriceCard(_prices[index]);
//                     },
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPriceCard(MarketPrice price) {
//     return Card(
//       elevation: 4,
//       margin: EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     price.market,
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey[800],
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     price.price,
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green[600],
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     price.lastUpdated,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: price.trend == 'up' ? Colors.green[100] : Colors.red[100],
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     price.trend == 'up' ? Icons.trending_up : Icons.trending_down,
//                     color: price.trend == 'up' ? Colors.green : Colors.red,
//                     size: 16,
//                   ),
//                   SizedBox(width: 4),
//                   Text(
//                     price.trend.toUpperCase(),
//                     style: TextStyle(
//                       color: price.trend == 'up' ? Colors.green : Colors.red,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class GovernmentSchemesScreen extends StatefulWidget {
//   @override
//   _GovernmentSchemesScreenState createState() => _GovernmentSchemesScreenState();
// }

// class _GovernmentSchemesScreenState extends State<GovernmentSchemesScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   List<GovernmentScheme> _schemes = [];
//   bool _isLoading = false;

//   Future<void> _searchSchemes() async {
//     if (_searchController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please enter a search term')),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     // Simulate API call
//     await Future.delayed(Duration(seconds: 2));

//     setState(() {
//       _schemes = [
//         GovernmentScheme(
//           name: 'Drip Irrigation Subsidy',
//           description: 'Get 50% subsidy on drip irrigation systems',
//           eligibility: 'Small & marginal farmers with land < 2 hectares',
//           subsidy: '₹50,000 maximum',
//           documents: ['Land records', 'Aadhaar card', 'Bank account'],
//           applicationLink: 'https://krishi.karnataka.gov.in',
//         ),
//         GovernmentScheme(
//           name: 'Pradhan Mantri Kisan Samman Nidhi',
//           description: 'Direct income support to farmers',
//           eligibility: 'All landholding farmers',
//           subsidy: '₹6,000 per year',
//           documents: ['Aadhaar card', 'Bank account', 'Land records'],
//           applicationLink: 'https://pmkisan.gov.in',
//         ),
//         GovernmentScheme(
//           name: 'Soil Health Card Scheme',
//           description: 'Free soil testing and nutrient management',
//           eligibility: 'All farmers',
//           subsidy: 'Free service',
//           documents: ['Land records', 'Aadhaar card'],
//           applicationLink: 'https://soilhealth.dac.gov.in',
//         ),
//       ];
//       _isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('🏛️ Government Schemes'),
//         backgroundColor: Colors.green[600],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.green[50]!, Colors.white],
//           ),
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     children: [
//                       TextField(
//                         controller: _searchController,
//                         decoration: InputDecoration(
//                           labelText: 'Search for schemes',
//                           hintText: 'e.g., subsidy, irrigation, loan',
//                           prefixIcon: Icon(Icons.search),
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       ElevatedButton(
//                         onPressed: _isLoading ? null : _searchSchemes,
//                         child: _isLoading
//                             ? Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   CircularProgressIndicator(color: Colors.white),
//                                   SizedBox(width: 16),
//                                   Text('Searching...'),
//                                 ],
//                               )
//                             : Text('Search Schemes'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue[600],
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 16),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),
//               if (_schemes.isNotEmpty)
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: _schemes.length,
//                     itemBuilder: (context, index) {
//                       return _buildSchemeCard(_schemes[index]);
//                     },
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSchemeCard(GovernmentScheme scheme) {
//     return Card(
//       elevation: 6,
//       margin: EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               scheme.name,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue[600],
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               scheme.description,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[700],
//               ),
//             ),
//             SizedBox(height: 12),
//             _buildSchemeDetail('Eligibility', scheme.eligibility),
//             _buildSchemeDetail('Subsidy', scheme.subsidy),
//             _buildSchemeDetail('Documents', scheme.documents.join(', ')),
//             SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       // Open application link
//                     },
//                     icon: Icon(Icons.open_in_new),
//                     label: Text('Apply Now'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green[600],
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       // Share scheme
//                     },
//                     icon: Icon(Icons.share),
//                     label: Text('Share'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue[600],
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSchemeDetail(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 80,
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[600],
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[800],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Data Models
// class ChatMessage {
//   final String text;
//   final bool isUser;

//   ChatMessage({required this.text, required this.isUser});
// }

// class DiagnosisResult {
//   final String disease;
//   final String cause;
//   final String treatment;
//   final int confidence;
//   final String remedyPrice;

//   DiagnosisResult({
//     required this.disease,
//     required this.cause,
//     required this.treatment,
//     required this.confidence,
//     required this.remedyPrice,
//   });
// }

// class MarketPrice {
//   final String crop;
//   final String market;
//   final String price;
//   final String trend;
//   final String lastUpdated;

//   MarketPrice({
//     required this.crop,
//     required this.market,
//     required this.price,
//     required this.trend,
//     required this.lastUpdated,
//   });
// }

// class GovernmentScheme {
//   final String name;
//   final String description;
//   final String eligibility;
//   final String subsidy;
//   final List<String> documents;
//   final String applicationLink;

//   GovernmentScheme({
//     required this.name,
//     required this.description,
//     required this.eligibility,
//     required this.subsidy,
//     required this.documents,
//     required this.applicationLink,
//   });
// }
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(MarketPricesApp());
}

class MarketPricesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market Prices',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MarketPricesScreen(),
    );
  }
}

class MarketPricesScreen extends StatefulWidget {
  @override
  _MarketPricesScreenState createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  final TextEditingController _cropController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<MarketPrice> _prices = [];
  List<MarketPrice> _recentPrices = [];
  bool _isLoading = false;
  String _selectedCrop = '';
  String _selectedLocation = '';

  // Sample crop suggestions
  final List<String> _cropSuggestions = [
    'Tomato', 'Rice', 'Wheat', 'Onion', 'Potato', 'Sugarcane',
    'Cotton', 'Maize', 'Soybean', 'Groundnut', 'Chilli', 'Turmeric'
  ];

  // Sample location suggestions
  final List<String> _locationSuggestions = [
    'Mysuru', 'Bangalore', 'Mandya', 'Hassan', 'Tumkur', 'Davangere',
    'Bellary', 'Hubli', 'Mangalore', 'Shimoga', 'Gulbarga', 'Bijapur'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentPrices();
  }

  Future<void> _loadRecentPrices() async {
    setState(() {
      _recentPrices = [
        MarketPrice(
          crop: 'Tomato',
          market: 'Mysuru Mandi',
          price: '₹45/kg',
          trend: 'up',
          lastUpdated: 'Today 10:30 AM',
          minPrice: '₹40/kg',
          maxPrice: '₹50/kg',
          quality: 'Grade A',
        ),
        MarketPrice(
          crop: 'Rice',
          market: 'Bangalore APMC',
          price: '₹42/kg',
          trend: 'down',
          lastUpdated: 'Today 9:15 AM',
          minPrice: '₹38/kg',
          maxPrice: '₹45/kg',
          quality: 'Grade B',
        ),
        MarketPrice(
          crop: 'Wheat',
          market: 'Mandya Market',
          price: '₹28/kg',
          trend: 'up',
          lastUpdated: 'Today 11:00 AM',
          minPrice: '₹25/kg',
          maxPrice: '₹30/kg',
          quality: 'Grade A',
        ),
      ];
    });
  }

  Future<void> _fetchPrices() async {
    if (_cropController.text.isEmpty || _locationController.text.isEmpty) {
      _showSnackBar('Please enter both crop and location');
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedCrop = _cropController.text;
      _selectedLocation = _locationController.text;
    });

    try {
      // Simulate API call with realistic data
      await Future.delayed(Duration(seconds: 2));

      // Generate realistic market prices
      List<MarketPrice> mockPrices = _generateMockPrices(_selectedCrop, _selectedLocation);
      
      setState(() {
        _prices = mockPrices;
        _isLoading = false;
      });

      _showSnackBar('Prices updated successfully!', isSuccess: true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error fetching prices: $e');
    }
  }

  List<MarketPrice> _generateMockPrices(String crop, String location) {
    final random = Random();
    final markets = [
      '$location Mandi',
      '$location APMC',
      '$location Market',
      'Wholesale Market $location',
      'Farmers Market $location',
    ];

    return List.generate(5, (index) {
      final basePrice = _getBasePriceForCrop(crop);
      final variance = basePrice * 0.15; // 15% variance
      final price = basePrice + (random.nextDouble() - 0.5) * variance;
      final minPrice = price * 0.9;
      final maxPrice = price * 1.1;

      return MarketPrice(
        crop: crop,
        market: markets[index],
        price: '₹${price.toInt()}/kg',
        trend: random.nextBool() ? 'up' : 'down',
        lastUpdated: _getRandomTime(),
        minPrice: '₹${minPrice.toInt()}/kg',
        maxPrice: '₹${maxPrice.toInt()}/kg',
        quality: ['Grade A', 'Grade B', 'Premium'][random.nextInt(3)],
      );
    });
  }

  double _getBasePriceForCrop(String crop) {
    final Map<String, double> basePrices = {
      'Tomato': 45.0,
      'Rice': 42.0,
      'Wheat': 28.0,
      'Onion': 35.0,
      'Potato': 25.0,
      'Sugarcane': 3.5,
      'Cotton': 85.0,
      'Maize': 22.0,
      'Soybean': 55.0,
      'Groundnut': 75.0,
      'Chilli': 120.0,
      'Turmeric': 95.0,
    };
    return basePrices[crop] ?? 40.0;
  }

  String _getRandomTime() {
    final random = Random();
    final hour = random.nextInt(12) + 1;
    final minute = random.nextInt(60);
    final ampm = random.nextBool() ? 'AM' : 'PM';
    return 'Today $hour:${minute.toString().padLeft(2, '0')} $ampm';
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _refreshPrices() async {
    if (_prices.isNotEmpty) {
      await _fetchPrices();
    } else {
      await _loadRecentPrices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📊 Market Prices'),
        backgroundColor: Colors.green[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshPrices,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshPrices,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchCard(),
                SizedBox(height: 16),
                if (_prices.isNotEmpty) ...[
                  _buildResultsHeader(),
                  SizedBox(height: 16),
                  ..._prices.map((price) => _buildPriceCard(price)).toList(),
                ] else if (_recentPrices.isNotEmpty) ...[
                  _buildRecentPricesHeader(),
                  SizedBox(height: 16),
                  ..._recentPrices.map((price) => _buildPriceCard(price)).toList(),
                ],
                SizedBox(height: 16),
                _buildMarketTipsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Search Market Prices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _cropSuggestions.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _cropController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                _cropController.text = controller.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    labelText: 'Crop Name',
                    hintText: 'e.g., Tomato, Rice, Wheat',
                    prefixIcon: Icon(Icons.eco, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _locationSuggestions.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _locationController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                _locationController.text = controller.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., Mysuru, Bangalore',
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchPrices,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Loading...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: 8),
                          Text('Get Prices'),
                        ],
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Colors.green[700]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Market Prices for $_selectedCrop in $_selectedLocation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPricesHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.blue[700]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Recent Market Prices',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(MarketPrice price) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store, color: Colors.green[600]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.market,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        price.crop,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price.price,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: price.trend == 'up' ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            price.trend == 'up' ? Icons.trending_up : Icons.trending_down,
                            color: price.trend == 'up' ? Colors.green[600] : Colors.red[600],
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            price.trend.toUpperCase(),
                            style: TextStyle(
                              color: price.trend == 'up' ? Colors.green[600] : Colors.red[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPriceDetail('Min Price', price.minPrice, Colors.red[600]!),
                      _buildPriceDetail('Max Price', price.maxPrice, Colors.green[600]!),
                      _buildPriceDetail('Quality', price.quality, Colors.blue[600]!),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        'Last updated: ${price.lastUpdated}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketTipsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[600]),
                SizedBox(width: 8),
                Text(
                  'Market Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Compare prices across different markets before selling\n'
              '• Check for quality requirements at each market\n'
              '• Consider transportation costs in your calculations\n'
              '• Monitor price trends over time for better timing',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Model
class MarketPrice {
  final String crop;
  final String market;
  final String price;
  final String trend;
  final String lastUpdated;
  final String minPrice;
  final String maxPrice;
  final String quality;

  MarketPrice({
    required this.crop,
    required this.market,
    required this.price,
    required this.trend,
    required this.lastUpdated,
    required this.minPrice,
    required this.maxPrice,
    required this.quality,
  });
}