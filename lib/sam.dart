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

class FarmingChatbot extends StatefulWidget {
  const FarmingChatbot({Key? key}) : super(key: key);

  @override
  State<FarmingChatbot> createState() => _FarmingChatbotState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final MessageType type;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
    this.type = MessageType.text,
  });
}

enum MessageType { text, image, voice }

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

  List<XFile> _selectedImages = [];
  List<PlatformFile> _selectedDocs = [];

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

  Future<void> _processImageWithGemini(XFile image) async {
    setState(() {
      _messages.add(ChatMessage(
        text: "🖼️ Image uploaded for agricultural analysis",
        isUser: true,
        timestamp: DateTime.now(),
        imageUrl: image.path,
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

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      await _processImageWithGemini(image);
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

  Future<void> _pickImages() async {
    final List<XFile>? images = await _imagePicker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages = images.take(3).toList(); // Limit to 3 images
      });
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        _selectedDocs = result.files.take(3).toList(); // Limit to 3 docs
      });
    }
  }

  Future<void> _sendFiles() async {
    for (var image in _selectedImages) {
      await _processImageWithGemini(image);
    }
    for (var doc in _selectedDocs) {
      await _processDocumentWithGemini(doc);
    }
    setState(() {
      _selectedImages.clear();
      _selectedDocs.clear();
    });
  }

  Future<void> _processDocumentWithGemini(PlatformFile doc) async {
    setState(() {
      _messages.add(ChatMessage(
        text: "📄 Document uploaded for analysis: ${doc.name}",
        isUser: true,
        timestamp: DateTime.now(),
        type: MessageType.text,
      ));
      _isProcessing = true;
    });

    _scrollToBottom();
    _typingController.repeat(reverse: true);

    try {
      final bytes = doc.bytes ?? await File(doc.path!).readAsBytes();
      final base64Doc = base64Encode(bytes);

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
As AgriSense AI, analyze this agricultural test document. Provide insights, recommendations, and highlight any critical findings for the farmer.
'''
                },
                {
                  'inline_data': {
                    'mime_type': doc.extension == 'pdf' ? 'application/pdf' : 'application/msword',
                    'data': base64Doc
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
        throw Exception('Failed to analyze document');
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
      _showSnackBar('Document analysis error: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _typingController.stop();
      _scrollToBottom();
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF2E7D32),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.agriculture, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AgriSense AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.language, color: Colors.white),
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Status bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2E7D32),
                        const Color(0xFF388E3C),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Language: ${_languages[_selectedLanguage]?.split(' ')[0] ?? 'English'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message, constraints.maxWidth);
                    },
                  ),
                ),
                // Processing indicator
                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _typingAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(0xFF2E7D32),
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'AI is analyzing...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                // Input area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    children: [
                      // Image upload
                      IconButton(
                        icon: const Icon(Icons.image, color: Colors.white),
                        onPressed: _pickImages,
                        tooltip: 'Upload Images',
                      ),
                      // Document upload
                      IconButton(
                        icon: const Icon(Icons.insert_drive_file, color: Colors.white),
                        onPressed: _pickDocuments,
                        tooltip: 'Upload Documents',
                      ),
                      // Show selected images
                      ..._selectedImages.map((img) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(img.path),
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )),
                      // Show selected docs
                      ..._selectedDocs.map((doc) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.description, color: Colors.amber, size: 28),
                      )),
                      // Text input
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ask anything',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onSubmitted: (text) => _sendMessage(text, MessageType.text),
                          minLines: 1,
                          maxLines: 3,
                        ),
                      ),
                      // Mic button
                      IconButton(
                        icon: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
                        onPressed: _isListening ? _stopListening : _startListening,
                        tooltip: 'Voice Input',
                      ),
                      // Send button
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          _sendMessage(_textController.text, MessageType.text);
                          if (_selectedImages.isNotEmpty || _selectedDocs.isNotEmpty) {
                            _sendFiles();
                          }
                        },
                        tooltip: 'Send',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, double maxWidth) {
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
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E7D32),
                    const Color(0xFF4CAF50),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? const Color(0xFF2E7D32)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(message.imageUrl!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.type == MessageType.voice)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: message.isUser 
                                ? Colors.white.withOpacity(0.2)
                                : const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.mic,
                            size: 16,
                            color: message.isUser ? Colors.white70 : const Color(0xFF2E7D32),
                          ),
                        ),
                      if (message.type == MessageType.voice) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isUser ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (!message.isUser)
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _speakResponse(message.text),
                              icon: Icon(
                                (_isSpeaking && _ttsRequested)
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              tooltip: (_isSpeaking && _ttsRequested)
                                  ? 'Stop speaking'
                                  : 'Read aloud',
                            ),
                          ],
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Colors.grey, size: 24),
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


