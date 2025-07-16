import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';


class FarmingChatbot extends StatefulWidget {
  const FarmingChatbot({Key? key}) : super(key: key);

  @override
  State<FarmingChatbot> createState() => _FarmingChatbotState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? imageUrls; // Changed from single imageUrl to list
  
  final String? documentUrl;
  final String? documentName;
  final MessageType type;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageUrls,
    this.documentUrl,
    this.documentName,
    this.type = MessageType.text,
    
  });
}

enum MessageType { text, image, voice, document, multiImage }

class _FarmingChatbotState extends State<FarmingChatbot>
    with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<ChatMessage> _messages = [];
  String _recognizedText = '';
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _selectedLanguage = 'en-IN';
  late final String _geminiApiKey;
  
  late AnimationController _pulseController;
  late AnimationController _typingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _typingAnimation;

  final Map<String, String> _languages = {
    'en-IN': 'English (India)',
    'hi-IN': 'हिंदी (Hindi)',
    'ta-IN': 'தமிழ் (Tamil)',
    'kn-IN': 'ಕನ್ನಡ (Kannada)',
    'te-IN': 'తెలుగు (Telugu)',
    'ml-IN': 'മലയാളം (Malayalam)',
    'bn-IN': 'বাংলা (Bengali)',
    'gu-IN': 'ગુજરાતી (Gujarati)',
    'mr-IN': 'मराठी (Marathi)',
    'pa-IN': 'ਪੰਜਾਬੀ (Punjabi)',
  };

  bool _ttsRequested = false; // Track if user requested TTS

  // Add these fields to your _FarmingChatbotState class:
  String? _ttsText;
  int _ttsCharIndex = 0;

  @override
  void initState() {
    super.initState();
    _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _initializeAnimations();
    _initializeSpeech();
    _initializeTts();
    _addWelcomeMessage();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "🌱 Welcome to AgriSense AI - Your Smart Farming Companion!\n\nI provide expert assistance with:\n\n🌾 Crop Management & Disease Detection\n📊 Market Analytics & Price Trends\n💧 Smart Irrigation Solutions\n🌿 Fertilizer & Nutrient Guidance\n🦗 Integrated Pest Management\n🌤️ Weather-Based Recommendations\n\nHow may I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      ));
    });
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        setState(() {
          _isListening = status == 'listening';
        });
        if (status == 'listening') {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        _pulseController.stop();
        _showSnackBar('Speech recognition error: ${error.errorMsg}');
      },
    );
    if (!available) {
      _showSnackBar('Speech recognition not available on this device');
    }
  }

  Future<void> _startListening() async {
    if (!_speechToText.isAvailable) {
      _showSnackBar('Speech recognition not available');
      return;
    }
    if (!_isListening) {
      setState(() {
        _recognizedText = '';
      });
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
          // Auto-submit when speech is finalized
          if (result.finalResult && _recognizedText.trim().isNotEmpty) {
            _stopListening(); // This will call _sendMessage
          }
        },
        localeId: _selectedLanguage,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
      );
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (_recognizedText.trim().isNotEmpty) {
      _sendMessage(_recognizedText, MessageType.voice);
      setState(() {
        _recognizedText = '';
      });
    }
  }

  Future<void> _speakResponse(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
        _ttsRequested = false;
      });
      return;
    }
    setState(() {
      _ttsRequested = true;
    });
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.speak(text);
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _ttsRequested = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
        _ttsRequested = false;
      });
    });
  }
  Future<void> _pickMultipleImages() async {
  final List<XFile> images = await _imagePicker.pickMultiImage(
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  
  if (images.isNotEmpty && images.length <= 3) {
    List<String> imagePaths = images.map((img) => img.path).toList();
    await _processMultipleImagesWithGemini(imagePaths);
  } else if (images.length > 3) {
    _showSnackBar('Please select maximum 3 images');
  }
}

// Document picker
Future<void> _pickDocument() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
  );

  if (result != null) {
    String filePath = result.files.single.path!;
    String fileName = result.files.single.name;
    await _processDocumentWithGemini(filePath, fileName);
  }
}

// Process multiple images
Future<void> _processMultipleImagesWithGemini(List<String> imagePaths) async {
  setState(() {
    _messages.add(ChatMessage(
      text: "📸 ${imagePaths.length} images uploaded for agricultural analysis",
      isUser: true,
      timestamp: DateTime.now(),
      imageUrls: imagePaths,
      type: MessageType.multiImage,
    ));
    _isProcessing = true;
  });

  _scrollToBottom();
  _typingController.repeat(reverse: true);

  try {
    List<Map<String, dynamic>> imageParts = [];
    
    for (String imagePath in imagePaths) {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);
      
      imageParts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': base64Image
        }
      });
    }

    List<Map<String, dynamic>> parts = [
      {
        'text': '''
As AgriSense AI, analyze these ${imagePaths.length} agricultural images comprehensively. Provide detailed insights on:

1. 🌱 Crop/Plant Identification across all images
2. 🦠 Disease or Pest Detection comparison
3. 📊 Growth Stage Assessment variations
4. 🧪 Nutritional Status Analysis
5. 🌍 Environmental Conditions differences
6. 📈 Comparative Analysis between images
7. 💡 Comprehensive Recommendations

Focus on practical, science-based advice for optimal crop management based on all provided images.
'''
      },
      ...imageParts
    ];

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'),
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': _geminiApiKey,
      },
      body: jsonEncode({
        'contents': [{'parts': parts}],
        'generationConfig': {
          'temperature': 0.3,
          'topK': 32,
          'topP': 0.9,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final geminiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        setState(() {
          _messages.add(ChatMessage(
            text: geminiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          ));
        });
      }
    }
  } catch (e) {
    setState(() {
      _messages.add(ChatMessage(
        text: 'Unable to analyze the images at this time. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      ));
    });
  } finally {
    setState(() {
      _isProcessing = false;
    });
    _typingController.stop();
    _scrollToBottom();
  }
}

// Process document
Future<void> _processDocumentWithGemini(String filePath, String fileName) async {
  setState(() {
    _messages.add(ChatMessage(
      text: "📄 Document uploaded: $fileName",
      isUser: true,
      timestamp: DateTime.now(),
      documentUrl: filePath,
      documentName: fileName,
      type: MessageType.document,
    ));
    _isProcessing = true;
  });

  _scrollToBottom();
  _typingController.repeat(reverse: true);

  try {
    String documentContent = '';
    String fileExtension = fileName.toLowerCase().split('.').last;
    
    switch (fileExtension) {
      case 'txt':
        documentContent = await File(filePath).readAsString();
        break;
      case 'pdf':
        try {
          // Read PDF using Syncfusion
          final bytes = await File(filePath).readAsBytes();
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          PdfTextExtractor extractor = PdfTextExtractor(document);
          documentContent = extractor.extractText();
          document.dispose();
        } catch (e) {
          documentContent = "PDF content extraction failed. Please ensure the PDF is not password protected or corrupted.";
        }
        break;
      default:
        documentContent = "For best results, please upload PDF or TXT files. Other formats may not be fully supported.";
    }

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent'),
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': _geminiApiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': '''
As AgriSense AI, analyze this agricultural document: "$fileName"

Document Content: $documentContent

Provide detailed analysis on:
1. 🧪 Test Results Interpretation
2. 📊 Data Analysis & Insights
3. 📈 Recommendations based on findings
4. 🌱 Agricultural Action Plan
5. 💡 Best Practices Suggestions

Focus on practical, actionable advice for farmers based on the document content.
'''
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topK': 32,
          'topP': 0.9,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final geminiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        setState(() {
          _messages.add(ChatMessage(
            text: geminiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          ));
        });
      }
    } else {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Unable to analyze the document at this time. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.text,
        ));
      });
    }
  } catch (e) {
    setState(() {
      _messages.add(ChatMessage(
        text: 'Unable to analyze the document at this time. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      ));
    });
  } finally {
    setState(() {
      _isProcessing = false;
    });
    _typingController.stop();
    _scrollToBottom();
  }
}

  Future<void> _sendMessage(String message, MessageType type) async {
    if (message.trim().isEmpty) return;

    if (_geminiApiKey.isEmpty) {
      _showSnackBar('Gemini API key not configured. Please set GEMINI_API_KEY in your .env file.');
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
        type: type,
      ));
      _isProcessing = true;
    });

    _textController.clear();
    _scrollToBottom();
    _typingController.repeat(reverse: true);

    await _processWithGemini(message);
  }

  Future<void> _processWithGemini(String text) async {
    try {
      String enhancedPrompt = '''
You are AgriSense AI, a professional agricultural assistant specializing in modern farming solutions. Provide accurate, practical, and science-based advice for farmers.

Context: You're integrated into a comprehensive farming platform that offers:
- IoT-enabled precision agriculture
- Real-time environmental monitoring
- AI-driven crop analytics
- Market intelligence systems
- Sustainable farming practices

User Query: $text

Response Guidelines:
1. Provide clear, actionable advice
2. Use professional agricultural terminology
3. Include specific recommendations when applicable
4. For market price queries, acknowledge the request and suggest checking local agricultural market boards or real-time market data
5. Focus on sustainable and efficient farming practices
6. Respond in the same language as the query
7. Keep responses concise but comprehensive

If location-specific information is requested (like Sathyamangalam), acknowledge the locality and provide relevant regional farming insights.
''';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': enhancedPrompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final geminiResponse = data['candidates'][0]['content']['parts'][0]['text'];
          
          setState(() {
            _messages.add(ChatMessage(
              text: geminiResponse,
              isUser: false,
              timestamp: DateTime.now(),
              type: MessageType.text,
            ));
          });
        } else {
          throw Exception('No response from AI service');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('API Error: ${errorData['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'I apologize, but I encountered an issue processing your request. Please try again or check your connection.',
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.text,
        ));
      });
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _typingController.stop();
      _scrollToBottom();
    }
  }

 Future _processImageWithGemini(XFile image) async {
  setState(() {
    _messages.add(ChatMessage(
      text: "🖼️ Image uploaded for agricultural analysis",
      isUser: true,
      timestamp: DateTime.now(),
      imageUrls: [image.path], // Use imageUrls as a list
      type: MessageType.image,
    ));
    _isProcessing = true;
  });

  _scrollToBottom();
  _typingController.repeat(reverse: true);

  try {
    final bytes = await File(image.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'),
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': _geminiApiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': '''
As AgriSense AI, analyze this agricultural image with professional expertise. Provide detailed insights on:

1. 🌱 Crop/Plant Identification
2. 🦠 Disease or Pest Detection
3. 📊 Growth Stage Assessment
4. 🧪 Nutritional Status Analysis
5. 🌍 Environmental Conditions
6. 💡 Actionable Recommendations

Focus on practical, science-based advice for optimal crop management.
'''
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topK': 32,
          'topP': 0.9,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final geminiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        setState(() {
          _messages.add(ChatMessage(
            text: geminiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          ));
        });
      } else {
        throw Exception('No response from AI service');
      }
    } else {
      throw Exception('Failed to analyze image');
    }
  } catch (e) {
    setState(() {
      _messages.add(ChatMessage(
        text: 'Unable to analyze the image at this time. Please ensure the image is clear and try again.',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      ));
    });
    _showSnackBar('Image analysis error: ${e.toString()}');
  } finally {
    setState(() {
      _isProcessing = false;
    });
    _typingController.stop();
    _scrollToBottom();
  }
}


  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      await _processImageWithGemini(image);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF1a1a1a), // Dark theme
    body: SafeArea(
      child: Column(
        children: [
          // Modern Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'AgriSense AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.language, color: Colors.white70),
                  onSelected: (String value) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                    _initializeTts();
                  },
                  itemBuilder: (BuildContext context) {
                    return _languages.entries.map((entry) {
                      return PopupMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
          ),
          
          // Chat Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.white30,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Chat with AgriSense AI...',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ask about crops, diseases, or upload images',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildModernMessageBubble(message);
                    },
                  ),
          ),
          
          // Processing Indicator
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'AI is thinking...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Voice Input Indicator
          if (_isListening)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Listening...',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_recognizedText.isNotEmpty)
                          Text(
                            _recognizedText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Modern Input Area
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Add Button with Menu
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _showAttachmentMenu,
                    icon: const Icon(Icons.add, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Text Input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (text) => _sendMessage(text, MessageType.text),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Voice Button
                Container(
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: _isListening ? Colors.red : Colors.white70,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Send Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _sendMessage(_textController.text, MessageType.text),
                    icon: const Icon(Icons.send, color: Colors.white),
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
void _showAttachmentMenu() {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2a2a2a),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Upload Content',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Grid of options
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildAttachmentOption(
                Icons.camera_alt,
                'Camera',
                'Take photo',
                Colors.blue,
                () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              _buildAttachmentOption(
                Icons.photo_library,
                'Gallery',
                'Up to 3 images',
                Colors.green,
                () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
              _buildAttachmentOption(
                Icons.description,
                'Document',
                'PDF, DOC, TXT',
                Colors.purple,
                () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildAttachmentOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}



  Widget _buildModernMessageBubble(ChatMessage message) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: Row(
      mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!message.isUser) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
        ],
        
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: message.isUser 
                  ? const Color(0xFF4CAF50)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(4),
                bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Multiple images display
                if (message.imageUrls != null && message.imageUrls!.isNotEmpty) ...[
                  if (message.imageUrls!.length == 1)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(message.imageUrls![0]),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: message.imageUrls!.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(message.imageUrls![index]),
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                
                // Document display
                if (message.documentUrl != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.documentName ?? 'Document',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Message text
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isUser ? Colors.white : Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Timestamp and actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: message.isUser ? Colors.white70 : Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    if (!message.isUser)
                      IconButton(
                        onPressed: () => _speakResponse(message.text),
                        icon: Icon(
                          (_isSpeaking && _ttsRequested) ? Icons.volume_off : Icons.volume_up,
                          size: 18,
                          color: Colors.white60,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        if (message.isUser) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, color: Colors.white70, size: 20),
          ),
        ],
      ],
    ),
  );
}


  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _typingController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }
}


