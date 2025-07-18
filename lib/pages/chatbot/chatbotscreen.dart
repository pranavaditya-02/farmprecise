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
import 'package:farmprecise/pages/homepage.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
        text:
            "🌱 Welcome to AgriSense AI - Your Smart Farming Companion!\n\nI provide expert assistance with:\n\n🌾 Crop Management & Disease Detection\n📊 Market Analytics & Price Trends\n💧 Smart Irrigation Solutions\n🌿 Fertilizer & Nutrient Guidance\n🦗 Integrated Pest Management\n🌤️ Weather-Based Recommendations\n\nHow may I assist you today?",
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
    String cleanText = text
        .replaceAll(
            RegExp(r'[#*_`~\[\](){}]'), '') // Remove markdown characters
        .replaceAll(RegExp(r'[🌱🦠📊🧪🌍📈💡📸🖼️📄]'), '') // Remove emojis
        .replaceAll(
            RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim();

    if (cleanText.isEmpty) {
      _showSnackBar('No text to speak');
      return;
    }

    setState(() {
      _ttsRequested = true;
    });

    try {
      await _flutterTts.setLanguage(_selectedLanguage);
      await _flutterTts.speak(cleanText);
    } catch (e) {
      print('TTS Error: $e');
      setState(() {
        _isSpeaking = false;
        _ttsRequested = false;
      });
      _showSnackBar('Text-to-speech error occurred');
    }
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
  // Replace your _processMultipleImagesWithGemini method with this fixed version
  Future<void> _processMultipleImagesWithGemini(List<String> imagePaths) async {
    setState(() {
      _messages.add(ChatMessage(
        text:
            "📸 ${imagePaths.length} images uploaded for agricultural analysis",
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
          'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}
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
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {'parts': parts}
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
          final geminiResponse =
              data['candidates'][0]['content']['parts'][0]['text'];

          // Create the chat message with the response
          final chatMessage = ChatMessage(
            text: geminiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          );

          setState(() {
            _messages.add(chatMessage);
          });

          // FIXED: Auto-play TTS for multiple image analysis
          // Check if TTS should be played (either explicitly requested or user was using voice)
          if (_ttsRequested || _isListening) {
            // Use the _speakResponse method directly with the response text
            await _speakResponse(geminiResponse);
          }
        } else {
          // Handle case where no candidates are returned
          final errorMessage = ChatMessage(
            text:
                'Unable to analyze the images at this time. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          );
          setState(() {
            _messages.add(errorMessage);
          });
        }
      } else {
        // Handle HTTP error
        final errorMessage = ChatMessage(
          text: 'Unable to analyze the images at this time. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.text,
        );
        setState(() {
          _messages.add(errorMessage);
        });
      }
    } catch (e) {
      // Handle general error
      final errorMessage = ChatMessage(
        text: 'Unable to analyze the images at this time. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      );
      setState(() {
        _messages.add(errorMessage);
      });
      print(
          'Error in _processMultipleImagesWithGemini: $e'); // Add this for debugging
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _typingController.stop();
      _scrollToBottom();
    }
  }

// Process document

// part-2
Future<void> _processDocumentWithGemini(
      String filePath, String fileName) async {
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

      print(
          'Processing file: $fileName with extension: $fileExtension'); // Debug log

      switch (fileExtension) {
        case 'txt':
          try {
            documentContent = await File(filePath).readAsString();
            print('TXT content length: ${documentContent.length}'); // Debug log
          } catch (e) {
            print('Error reading TXT file: $e'); // Debug log
            documentContent = "Error reading text file: ${e.toString()}";
          }
          break;

        case 'pdf':
          try {
            final bytes = await File(filePath).readAsBytes();
            print('PDF file size: ${bytes.length} bytes'); // Debug log

            final PdfDocument document = PdfDocument(inputBytes: bytes);
            PdfTextExtractor extractor = PdfTextExtractor(document);
            documentContent = extractor.extractText();
            document.dispose();

            print('PDF content length: ${documentContent.length}'); // Debug log

            if (documentContent.trim().isEmpty) {
              documentContent =
                  "The PDF appears to be empty or contains only images/scanned content that cannot be extracted as text.";
            }
          } catch (e) {
            print('Error reading PDF file: $e'); // Debug log
            documentContent =
                "PDF content extraction failed: ${e.toString()}. Please ensure the PDF is not password protected or corrupted.";
          }
          break;

        case 'doc':
        case 'docx':
          // Note: Full DOC/DOCX support requires additional packages
          documentContent =
              "DOC/DOCX files require additional processing. Please convert to PDF or TXT format for best results.";
          break;

        default:
          documentContent =
              "Unsupported file format: $fileExtension. Please upload PDF or TXT files.";
      }

      print(
          'Final document content length: ${documentContent.length}'); // Debug log

      // Check if document content is too long (Gemini has token limits)
      if (documentContent.length > 30000) {
        documentContent = documentContent.substring(0, 30000) +
            "\n\n[Document truncated due to length...]";
      }

      // Prepare the request
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '''
You are AgriSense AI, an agricultural expert assistant. A user has uploaded a document titled "$fileName".

Document Content:
$documentContent

Please analyze this agricultural document and provide detailed insights on:

1. 🧪 **Test Results Interpretation** (if applicable)
2. 📊 **Data Analysis & Key Insights**
3. 📈 **Recommendations based on findings**
4. 🌱 **Agricultural Action Plan**
5. 💡 **Best Practices Suggestions**

Focus on practical, actionable advice for farmers based on the document content. If the document doesn't contain agricultural information, please explain what type of content it contains and how it might relate to farming practices.

Please format your response using proper markdown with headers and bullet points for clarity.
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
      };

      print('Sending request to Gemini API...'); // Debug log

      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode(requestBody),
      );

      print('Response status code: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final geminiResponse =
              data['candidates'][0]['content']['parts'][0]['text'];

          setState(() {
            _messages.add(ChatMessage(
              text: geminiResponse,
              isUser: false,
              timestamp: DateTime.now(),
              type: MessageType.text,
            ));
          });

          // Add TTS functionality - THIS IS THE CRITICAL PART THAT WAS MISSING
          if (_ttsRequested || _isListening) {
            // Use the _speakResponse method directly with the response text
            await _speakResponse(geminiResponse);
          }

          print('Successfully processed document'); // Debug log
        } else {
          print('Invalid response structure: $data'); // Debug log
          setState(() {
            _messages.add(ChatMessage(
              text:
                  'The document was uploaded but the AI response was incomplete. Please try uploading the document again.',
              isUser: false,
              timestamp: DateTime.now(),
              type: MessageType.text,
            ));
          });
        }
      } else {
        print('HTTP Error: ${response.statusCode}'); // Debug log
        print('Error body: ${response.body}'); // Debug log

        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['error']['message'] ?? 'Unknown API error';

          setState(() {
            _messages.add(ChatMessage(
              text:
                  'Unable to analyze the document due to API error: $errorMessage. Please try again.',
              isUser: false,
              timestamp: DateTime.now(),
              type: MessageType.text,
            ));
          });
        } catch (e) {
          setState(() {
            _messages.add(ChatMessage(
              text:
                  'Unable to analyze the document at this time. Server returned error ${response.statusCode}. Please try again.',
              isUser: false,
              timestamp: DateTime.now(),
              type: MessageType.text,
            ));
          });
        }
      }
    } catch (e) {
      print('Exception in _processDocumentWithGemini: $e'); // Debug log
      setState(() {
        _messages.add(ChatMessage(
          text:
              'Unable to analyze the document due to an error: ${e.toString()}. Please try again.',
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
      _showSnackBar(
          'Gemini API key not configured. Please set GEMINI_API_KEY in your .env file.');
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
8. Format your response using proper markdown:
   - Use ## for main headings
   - Use ### for subheadings
   - Use **bold** for emphasis
   - Use * for bullet points
   - Use numbered lists where appropriate

If location-specific information is requested (like Sathyamangalam), acknowledge the locality and provide relevant regional farming insights.
''';

      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': enhancedPrompt}
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
          final geminiResponse =
              data['candidates'][0]['content']['parts'][0]['text'];

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
        throw Exception(
            'API Error: ${errorData['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text:
              'I apologize, but I encountered an issue processing your request. Please try again or check your connection.',
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
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'),
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
          final geminiResponse =
              data['candidates'][0]['content']['parts'][0]['text'];

          // Create the chat message with the response
          final chatMessage = ChatMessage(
            text: geminiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          );

          setState(() {
            _messages.add(chatMessage);
          });

          // ADDED: Auto-play TTS for single image analysis
          // Check if TTS should be played (either explicitly requested or user was using voice)
          if (_ttsRequested || _isListening) {
            // Use the _speakResponse method directly with the response text
            await _speakResponse(geminiResponse);
          }
        } else {
          // Handle case where no candidates are returned
          final errorMessage = ChatMessage(
            text:
                'Unable to analyze the image at this time. Please ensure the image is clear and try again.',
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          );
          setState(() {
            _messages.add(errorMessage);
          });
        }
      } else {
        // Handle HTTP error
        final errorMessage = ChatMessage(
          text:
              'Unable to analyze the image at this time. Please ensure the image is clear and try again.',
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.text,
        );
        setState(() {
          _messages.add(errorMessage);
        });
      }
    } catch (e) {
      // Handle general error
      final errorMessage = ChatMessage(
        text:
            'Unable to analyze the image at this time. Please ensure the image is clear and try again.',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      );
      setState(() {
        _messages.add(errorMessage);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'AgriSense AI',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
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
      body: Column(
        children: [
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
                            color: Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Chat with AgriSense AI...',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ask about crops, diseases, or upload images',
                          style: TextStyle(
                            color: Colors.grey,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4CAF50)),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'AI is thinking...',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // New Input Section Design
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Conditional Text Input or Listening Indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isListening
                      ? Container(
                          key: const ValueKey('listening'),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade300),
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
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (_recognizedText.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.red.shade200),
                                        ),
                                        child: Text(
                                          _recognizedText,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          key: const ValueKey('textInput'),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: Colors.black87),
                            maxLines: 3,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                            onSubmitted: (text) =>
                                _sendMessage(text, MessageType.text),
                          ),
                        ),
                ),

                const SizedBox(height: 10),

                // Action Buttons Row at Bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Attachment Button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: _isListening ? null : _showAttachmentMenu,
                          icon: const Icon(Icons.attach_file, size: 20),
                          label: const Text('Attach'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening
                                ? Colors.grey.shade200
                                : Colors.grey.shade100,
                            foregroundColor: _isListening
                                ? Colors.grey.shade400
                                : Color(0xFF4CAF50),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _isListening
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Voice Button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton.icon(
                          onPressed:
                              _isListening ? _stopListening : _startListening,
                          icon: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            size: 20,
                          ),
                          label: Text(_isListening ? 'Stop' : 'Voice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening
                                ? Colors.red.shade50
                                : Colors.grey.shade100,
                            foregroundColor:
                                _isListening ? Colors.red : Color(0xFF4CAF50),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _isListening
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Send Button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: ElevatedButton.icon(
                          onPressed: _isListening
                              ? null
                              : () => _sendMessage(
                                  _textController.text, MessageType.text),
                          icon: const Icon(Icons.send, size: 20),
                          label: const Text('Send'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening
                                ? Colors.grey.shade300
                                : Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Upload Content',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Grid of options
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              crossAxisSpacing: 8,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
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
                  Color(0xFF4CAF50),
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
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display images if present
                  if (message.imageUrls != null &&
                      message.imageUrls!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: message.imageUrls!.map((imageUrl) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(imageUrl),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Display document info if present
                  if (message.documentName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description,
                              color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.documentName!,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Message text with markdown support
                  message.isUser
                      ? Text(
                          message.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        )
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            // Body text styling
                            p: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              height: 1.4,
                            ),
                            // Header styles with green color
                            h1: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            h2: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            h3: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            h4: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            h5: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            h6: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            // Strong/bold text styling
                            strong: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            // Emphasis/italic text styling
                            em: const TextStyle(
                              color: Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                            // Code styling
                            code: TextStyle(
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.black87,
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                            // Code block styling
                            codeblockDecoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            // List styling
                            listBullet: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 16,
                            ),
                            // Link styling
                            a: const TextStyle(
                              color: Color(0xFF4CAF50),
                              decoration: TextDecoration.underline,
                            ),
                            // Blockquote styling
                            blockquote: const TextStyle(
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: Colors.grey.shade100,
                            ),
                            // Table styling
                            tableHead: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                            tableBody: const TextStyle(
                              color: Colors.black87,
                            ),
                            tableBorder: TableBorder.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            // Horizontal rule
                            horizontalRuleDecoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          // Enable selectable text
                          selectable: true,
                          // Handle link taps
                          onTapLink: (text, href, title) {
                            // Handle link taps if needed
                            print('Link tapped: $href');
                          },
                        ),

                  const SizedBox(height: 8),

                  // Timestamp and actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isUser ? Colors.white70 : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (!message.isUser)
                        IconButton(
                          onPressed: () => _speakResponse(message.text),
                          icon: Icon(
                            (_isSpeaking && _ttsRequested)
                                ? Icons.volume_off
                                : Icons.volume_up,
                            size: 18,
                            color: Color(0xFF4CAF50),
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
                color: Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  const Icon(Icons.person, color: Color(0xFF4CAF50), size: 20),
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
