import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:khushidua/constants/firebaseRef.dart';
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/controllers/themeController.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/colors.dart';
import '../controllers/userController.dart';
import '../models/duaModel.dart';
import '../models/subCategoryModel.dart';

class OpenDuasScreen extends StatefulWidget {
  final SubCategoryModel _subCategoryModel;

  const OpenDuasScreen(this._subCategoryModel, {super.key});

  @override
  State<OpenDuasScreen> createState() => _OpenDuasScreenState();
}

class _OpenDuasScreenState extends State<OpenDuasScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingPath;
  String? _expandedBenefitsDuaId; // Track which dua has benefits expanded

  @override
  void initState() {
    super.initState();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<DuaController>().getFilteredDuas(widget._subCategoryModel);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> markDuaAsDone(String duaId) async {
    try {
      if (!Get.find<UserController>().userModel!.readDuas.contains(duaId)) {
        userRef.doc(Get.find<UserController>().userModel!.id).update({
          "readDuas": FieldValue.arrayUnion([duaId]),
          "points": Get.find<UserController>().userModel!.points + 50,
        });
      }
    } catch (e) {
      debugPrint("Error updating Dua status: $e");
    }
  }

  void _toggleAudio(String path, String duaId) async {
    if (_currentlyPlayingPath == path) {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingPath = null;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(path));

      setState(() {
        _currentlyPlayingPath = path;
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _currentlyPlayingPath = null;
        });
        if (Get.find<UserController>().userModel?.isLoggedIn ?? false) {
          markDuaAsDone(duaId);
        }
      });
    }
  }

  void showTextOptionsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              contentPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: GetBuilder<ThemeController>(
                builder: (themeController) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Preview Section
                        Text(
                          'اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ',
                          style: TextStyle(
                            fontSize: themeController.textSize,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (themeController.showTransliteration)
                          Text(
                            'Allahumma ajirni min an-naar',
                            style: TextStyle(
                              fontSize: themeController.textSize,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (themeController.showTranslation)
                          Text(
                            'O Allah, save me from the Hellfire.',
                            style: TextStyle(
                              fontSize: themeController.textSize,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const Divider(height: 30, color: Colors.grey),

                        // Font Size Slider
                        Row(
                          children: [
                            Text(
                              'Font Size',
                              style: TextStyle(color: Colors.white),
                            ),
                            Expanded(
                              child: Slider(
                                value: themeController.textSize,
                                min: 14,
                                max: 27,
                                divisions: 13,
                                label: themeController.textSize
                                    .round()
                                    .toString(),
                                onChanged: (value) =>
                                    themeController.setTextSize(value),
                              ),
                            ),
                          ],
                        ),

                        // English 1 Toggle
                        SwitchListTile(
                          title: Text(
                            "Show transliteration",
                            style: TextStyle(color: Colors.white),
                          ),
                          value: themeController.showTransliteration,
                          onChanged: (val) =>
                              themeController.setShowTransliteration(val),
                          activeThumbColor: Colors.green,
                        ),

                        // English 2 Toggle
                        SwitchListTile(
                          title: Text(
                            "Show translation",
                            style: TextStyle(color: Colors.white),
                          ),
                          value: themeController.showTranslation,
                          onChanged: (val) =>
                              themeController.setShowTranslation(val),
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          InkWell(
            onTap: () {
              showTextOptionsPopup();
            },
            child: Icon(
              Icons.text_fields_outlined,
              color: rblack,
            ).marginOnly(right: 20),
          ),
        ],
      ),
      body: GetBuilder<DuaController>(
        builder: (duaController) {
          return ListView.builder(
            itemCount: duaController.filteredDuas.length,
            itemBuilder: (context, index) {
              return DuaTile(
                dua: duaController.filteredDuas[index],
                currentlyPlayingPath: _currentlyPlayingPath,
                onToggle: _toggleAudio,
                expandedBenefitsDuaId: _expandedBenefitsDuaId,
                onToggleBenefits: (duaId) {
                  setState(() {
                    // If clicking the same dua, collapse it; otherwise expand the new one
                    _expandedBenefitsDuaId = _expandedBenefitsDuaId == duaId
                        ? null
                        : duaId;
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

class DuaTile extends StatefulWidget {
  final DuaModel dua;
  final String? currentlyPlayingPath;
  final Function(String, String) onToggle;
  final String? expandedBenefitsDuaId;
  final Function(String?) onToggleBenefits;

  const DuaTile({
    required this.dua,
    required this.currentlyPlayingPath,
    required this.onToggle,
    required this.expandedBenefitsDuaId,
    required this.onToggleBenefits,
    super.key,
  });

  @override
  State<DuaTile> createState() => _DuaTileState();
}

class _DuaTileState extends State<DuaTile> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String baseUrl = "";

  final List<String> imagePaths = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
    'assets/images/4.png',
    'assets/images/5.png',
  ];
  late String randomImage;
  final GlobalKey _popupKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    randomImage = imagePaths[Random().nextInt(imagePaths.length)];
    getBaseUrl();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  getBaseUrl() async {
    await sysConfigRef
        .doc("MemoizationURL")
        .get()
        .then((value) {
          baseUrl = value.data()!["URL"];
          print('\n🔗 BASE URL FETCHED FROM FIREBASE:');
          print('   URL: $baseUrl');
          print('   Expected: http://34.238.195.141:3400/transcribe/');
          if (baseUrl != 'http://34.238.195.141:3400/transcribe/') {
            print('   ⚠️  WARNING: URL does not match expected value!');
            print('   Please update Firebase config with the new URL.');
          } else {
            print('   ✅ URL matches expected value');
          }
          debugPrint('');
        })
        .catchError((error) {
          print('❌ ERROR fetching base URL from Firebase: $error');
          baseUrl = 'http://34.238.195.141:3400/transcribe/'; // Fallback
          print('   Using fallback URL: $baseUrl');
        });
  }

  void _openRecordingDialog() {
    bool dialogIsRecording = false;
    String? dialogApiResponse;
    bool dialogIsLoading = false;
    Duration dialogRecordingDuration = Duration.zero;
    AudioRecorder? dialogRecorder;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Initialize recorder for this dialog
            dialogRecorder ??= AudioRecorder();

            void updateRecordingDuration() {
              Future.delayed(const Duration(seconds: 1), () {
                if (dialogIsRecording) {
                  setDialogState(() {
                    dialogRecordingDuration = Duration(
                      seconds: dialogRecordingDuration.inSeconds + 1,
                    );
                  });
                  updateRecordingDuration();
                }
              });
            }

            Future<void> sendToApi(String audioPath) async {
              if (baseUrl.isEmpty) {
                await getBaseUrl();
              }

              setDialogState(() => dialogIsLoading = true);
              setDialogState(() => dialogApiResponse = null);

              // Declare apiUrl outside try block so it's accessible in catch block
              String apiUrl = '';

              try {
                // Get audio file details first
                final audioFile = File(audioPath);
                if (!await audioFile.exists()) {
                  throw Exception('Audio file does not exist: $audioPath');
                }

                final fileSize = await audioFile.length();
                final fileName = p.basename(audioPath);

                // Read the full file as bytes to ensure we send the complete file
                final fileBytes = await audioFile.readAsBytes();

                print('\n📂 FILE VERIFICATION:');
                print('   - File exists: ${await audioFile.exists()}');
                print(
                  '   - File size on disk: ${(fileSize / 1024).toStringAsFixed(2)} KB',
                );
                print(
                  '   - Bytes read: ${(fileBytes.length / 1024).toStringAsFixed(2)} KB',
                );
                print(
                  '   - Match: ${fileSize == fileBytes.length ? "✅" : "❌"}',
                );

                // Properly encode Arabic text as query parameter (same as HTML: encodeURIComponent)
                final encodedArabic = Uri.encodeComponent(widget.dua.arabic);

                // Build API URL exactly like HTML version:
                // apiUrl = baseUrl + '?ARABIC_AYAH=' + encodeURIComponent(arabicText)
                // Ensure baseUrl ends with /transcribe/ (like HTML: http://localhost:3400/transcribe/)
                String cleanBaseUrl = baseUrl.trim();

                // Remove trailing query parameters if present (like ?ARABIC_AYAH=)
                if (cleanBaseUrl.contains('?')) {
                  cleanBaseUrl = cleanBaseUrl.substring(
                    0,
                    cleanBaseUrl.indexOf('?'),
                  );
                }

                // Ensure it ends with /transcribe/ (add if missing)
                if (!cleanBaseUrl.endsWith('/transcribe/')) {
                  if (cleanBaseUrl.endsWith('/transcribe')) {
                    cleanBaseUrl = '$cleanBaseUrl/';
                  } else if (cleanBaseUrl.endsWith('/')) {
                    cleanBaseUrl = '${cleanBaseUrl}transcribe/';
                  } else {
                    cleanBaseUrl = '$cleanBaseUrl/transcribe/';
                  }
                }

                // Build final URL exactly like HTML: baseUrl + '?ARABIC_AYAH=' + encodedText
                apiUrl = '$cleanBaseUrl?ARABIC_AYAH=$encodedArabic';

                // Validate URL
                try {
                  final testUri = Uri.parse(apiUrl);
                  if (testUri.host.isEmpty) {
                    throw Exception('Invalid API URL: host is empty');
                  }
                } catch (e) {
                  throw Exception('Invalid API URL format: $apiUrl - $e');
                }

                // Determine content type based on file extension
                // Backend supports: WAV, MP3, MPEG, X-WAV, WEBM
                String contentType = 'audio/mpeg';
                String fileExtension = p.extension(audioPath).toLowerCase();
                if (fileExtension == '.wav') {
                  contentType = 'audio/wav';
                } else if (fileExtension == '.mpeg' ||
                    fileExtension == '.mp3') {
                  contentType = 'audio/mpeg';
                } else if (fileExtension == '.m4a' || fileExtension == '.aac') {
                  // M4A/AAC not in spec but try audio/mp4 or audio/mpeg
                  contentType = 'audio/mpeg'; // Try mpeg as fallback
                } else if (fileExtension == '.webm') {
                  contentType = 'audio/webm';
                }

                // ========== API CALL LOGGING ==========
                print('\n========== API CALL START ==========');
                print('📡 BASE URL (from Firebase): $baseUrl');
                print('🔗 FULL API URL: $apiUrl');
                print('📝 METHOD: POST');
                print('📋 ARABIC TEXT (Original): ${widget.dua.arabic}');
                print('📋 ARABIC TEXT (Encoded): $encodedArabic');
                print('🎵 AUDIO FILE PATH: $audioPath');
                print('📁 AUDIO FILE NAME: $fileName');
                print(
                  '📦 AUDIO FILE SIZE: ${(fileSize / 1024).toStringAsFixed(2)} KB',
                );
                print('🎚️ CONTENT TYPE: $contentType');
                print('📤 PAYLOAD: multipart/form-data');
                print('   - Field: audio_file');
                print('   - File: $fileName');
                print('   - Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
                print('   - Bytes: ${fileBytes.length} bytes');
                print('   - Type: $contentType');
                print('📨 HEADERS:');
                print(
                  '   - Content-Type: multipart/form-data (auto-set by MultipartRequest)',
                );
                print('   - No custom headers (matching HTML version)');
                print('=====================================\n');

                var uri = Uri.parse(apiUrl);
                var request = http.MultipartRequest('POST', uri);

                // Send the full file using bytes to ensure complete file is sent
                // Backend expects: audio_file field with binary file data
                request.files.add(
                  http.MultipartFile.fromBytes(
                    'audio_file', // Field name as per backend spec
                    fileBytes, // Full file bytes
                    filename: fileName,
                    contentType: MediaType.parse(contentType),
                  ),
                );

                // Headers - Match HTML version exactly
                // HTML doesn't set any special headers - browser handles Content-Type automatically
                // Flutter's MultipartRequest also sets Content-Type automatically
                // Don't set 'accept' header - let server decide response format

                print(
                  '⏳ Sending request to API with ${fileBytes.length} bytes...\n',
                );
                print('🌐 Network Request Details:');
                final parsedUri = Uri.parse(apiUrl);
                print('   - Host: ${parsedUri.host}');
                print('   - Port: ${parsedUri.port}');
                print('   - Scheme: ${parsedUri.scheme}');
                print('   - Path: ${parsedUri.path}');
                print('   - Query: ${parsedUri.query}');
                print('   - Full URL: $apiUrl');
                print('');

                // Test connection first (optional - can help diagnose issues)
                print('🔍 Testing server connectivity...');
                try {
                  final testClient = http.Client();
                  final testResponse = await testClient
                      .get(
                        Uri.parse(
                          '${parsedUri.scheme}://${parsedUri.host}:${parsedUri.port}',
                        ),
                      )
                      .timeout(const Duration(seconds: 10));
                  print(
                    '   ✅ Server is reachable (HTTP ${testResponse.statusCode})',
                  );
                  testClient.close();
                } catch (e) {
                  print('   ⚠️  Server connectivity test failed: $e');
                  print(
                    '   ℹ️  This might be normal if server only accepts POST requests',
                  );
                }
                print('');

                final stopwatch = Stopwatch()..start();

                // Send request with timeout (2 minutes for audio processing)
                print('📤 Sending POST request to API...');
                var response = await request.send().timeout(
                  const Duration(seconds: 120), // 2 minutes timeout
                  onTimeout: () {
                    throw TimeoutException(
                      'Request timeout after 2 minutes',
                      const Duration(seconds: 120),
                    );
                  },
                );
                stopwatch.stop();

                print(
                  '✅ Response received in ${stopwatch.elapsedMilliseconds}ms',
                );
                print('📊 STATUS CODE: ${response.statusCode}');
                print('📋 RESPONSE HEADERS:');
                response.headers.forEach((key, value) {
                  print('   - $key: $value');
                });

                var responseBody = await response.stream.bytesToString();
                final responseLength = responseBody.length;

                print(
                  '📦 RESPONSE BODY LENGTH: ${(responseLength / 1024).toStringAsFixed(2)} KB',
                );
                print(
                  '📄 RESPONSE BODY (first 500 chars): ${responseBody.length > 500 ? "${responseBody.substring(0, 500)}..." : responseBody}',
                );

                if (response.statusCode == 200) {
                  print('✅ SUCCESS: API call completed successfully');
                  print('========== API CALL END ==========\n');
                  setDialogState(() {
                    dialogApiResponse = responseBody;
                  });
                } else {
                  print(
                    '❌ ERROR: Server returned status ${response.statusCode}',
                  );
                  print('📄 ERROR RESPONSE BODY: $responseBody');
                  print('========== API CALL END ==========\n');
                  setDialogState(() {
                    dialogApiResponse =
                        "Error: Server returned status ${response.statusCode}";
                  });
                }
              } on TimeoutException catch (e) {
                print('⏱️ TIMEOUT ERROR: Request timed out after 2 minutes');
                print('   - Message: ${e.message}');
                print('   - Duration: ${e.duration}');
                print('========== API CALL END ==========\n');
                setDialogState(() {
                  dialogApiResponse =
                      "Error: Request timed out after 2 minutes. The audio processing is taking longer than expected. Please try again or check your internet connection.";
                });
              } on SocketException catch (e) {
                print('🌐 NETWORK ERROR: Connection failed');
                print('   - Message: ${e.message}');
                print('   - Address: ${e.address}');
                print('   - Port: ${e.port}');
                print('   - OS Error: ${e.osError}');
                print('   - OS Error Code: ${e.osError?.errorCode}');
                print('   - OS Error Message: ${e.osError?.message}');
                print('\n🔍 TROUBLESHOOTING:');
                print('   1. Is the server running at $apiUrl?');
                print(
                  '   2. If using localhost in HTML, iOS Simulator cannot access it.',
                );
                print(
                  '      → Use your Mac\'s IP address instead (e.g., http://192.168.x.x:3400/transcribe/)',
                );
                print('   3. Check if server is accessible: curl $apiUrl');
                print('   4. Verify firewall settings allow port 3400');
                print(
                  '   5. For remote server, ensure it\'s running and accessible',
                );
                print('========== API CALL END ==========\n');

                String errorMessage;
                if (e.osError?.errorCode == 61) {
                  // Connection refused
                  if (apiUrl.contains('localhost') ||
                      apiUrl.contains('127.0.0.1')) {
                    errorMessage =
                        "Error: Cannot connect to localhost from iOS Simulator.\n\n"
                        "Solution: Use your Mac's IP address instead of localhost.\n"
                        "Example: http://192.168.1.100:3400/transcribe/\n\n"
                        "Find your Mac IP: System Preferences > Network";
                  } else {
                    errorMessage =
                        "Error: Connection refused.\n\n"
                        "The server at $apiUrl is not responding.\n\n"
                        "Possible causes:\n"
                        "• Server is not running\n"
                        "• Firewall blocking connection\n"
                        "• Wrong IP address or port\n"
                        "• Network connectivity issues";
                  }
                } else {
                  errorMessage =
                      "Error: Cannot connect to server.\n\n"
                      "Details: ${e.message}\n"
                      "Server: $apiUrl\n\n"
                      "Please check:\n"
                      "• Internet connection\n"
                      "• Server is running\n"
                      "• Correct server address";
                }

                setDialogState(() {
                  dialogApiResponse = errorMessage;
                });
              } on HttpException catch (e) {
                print('📡 HTTP ERROR: ${e.message}');
                print('========== API CALL END ==========\n');
                setDialogState(() {
                  dialogApiResponse = "Error: HTTP error - ${e.message}";
                });
              } catch (e, stackTrace) {
                print('❌ EXCEPTION: ${e.toString()}');
                print('   - Type: ${e.runtimeType}');
                print('📚 STACK TRACE:');
                print(stackTrace);
                print('========== API CALL END ==========\n');
                setDialogState(() {
                  dialogApiResponse = "Error: ${e.toString()}";
                });
              } finally {
                setDialogState(() => dialogIsLoading = false);
              }
            }

            Future<void> startRecording() async {
              // Check current permission status first
              PermissionStatus status = await Permission.microphone.status;

              // If permission is not granted, request it
              if (!status.isGranted) {
                status = await Permission.microphone.request();
              }

              // Handle different permission states
              if (status.isPermanentlyDenied) {
                // Permission is permanently denied, show dialog to open settings
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Microphone Permission Required"),
                      content: const Text(
                        "Microphone permission is permanently denied. Please enable it in app settings to record audio.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await openAppSettings();
                          },
                          child: const Text("Open Settings"),
                        ),
                      ],
                    ),
                  );
                }
                return;
              }

              if (!status.isGranted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Microphone permission is required to record audio. Please grant permission when prompted.",
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
                return;
              }

              // Double-check with the recorder itself
              if (!await dialogRecorder!.hasPermission()) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Microphone permission not available. Please check your device settings.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              // Start recording in WAV format (supported by API)
              // Note: record package doesn't support MP3 encoding directly
              // WAV is a lossless format and is supported by the API
              try {
                final dir = await getTemporaryDirectory();
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final filePath = p.join(dir.path, 'recording_$timestamp.wav');

                await dialogRecorder!.start(
                  const RecordConfig(
                    encoder: AudioEncoder.wav,
                    bitRate: 128000,
                    sampleRate: 44100,
                  ),
                  path: filePath,
                );

                setDialogState(() {
                  dialogIsRecording = true;
                  dialogRecordingDuration = Duration.zero;
                  dialogApiResponse = null;
                });

                // Update recording duration
                updateRecordingDuration();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to start recording: $e"),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            }

            Future<void> stopRecording() async {
              if (dialogRecorder != null && dialogIsRecording) {
                final path = await dialogRecorder!.stop();
                setDialogState(() {
                  dialogIsRecording = false;
                });

                if (path != null) {
                  // Automatically send to API after recording stops
                  await sendToApi(path);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to save recording."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            }

            String formatDuration(Duration duration) {
              String twoDigits(int n) => n.toString().padLeft(2, "0");
              final minutes = twoDigits(duration.inMinutes.remainder(60));
              final seconds = twoDigits(duration.inSeconds.remainder(60));
              return "$minutes:$seconds";
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.mic, color: Color(0xff2A158F)),
                  const SizedBox(width: 8),
                  const Text(
                    "Check Recitation",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Arabic text display - This is what will be sent to API
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Color(0xff2A158F),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Recording this Arabic text:",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xff2A158F).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xff2A158F).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              widget.dua.arabic,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Color(0xff2A158F),
                                fontFamily: 'arabic',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recording indicator
                    if (dialogIsRecording) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsing animation
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.2),
                              duration: const Duration(milliseconds: 1000),
                              onEnd: () {
                                setDialogState(() {});
                              },
                              builder: (context, value, child) {
                                return Container(
                                  width: 60 * value,
                                  height: 60 * value,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                            const Icon(Icons.mic, color: Colors.red, size: 40),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Recording...",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatDuration(dialogRecordingDuration),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],

                    // Loading indicator
                    if (dialogIsLoading) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xff2A158F),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Processing your recitation...",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],

                    // API Response
                    if (dialogApiResponse != null && !dialogIsLoading) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Result:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 300,
                                ),
                                child: SingleChildScrollView(
                                  child: Html(
                                    data: dialogApiResponse!,
                                    style: {
                                      "body": Style(
                                        margin: Margins.zero,
                                        padding: HtmlPaddings.zero,
                                      ),
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Ready state
                    if (!dialogIsRecording &&
                        !dialogIsLoading &&
                        dialogApiResponse == null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xff2A158F).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_none,
                          color: Color(0xff2A158F),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Ready to record",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                // Start/Stop Recording Button
                ElevatedButton.icon(
                  onPressed: dialogIsLoading
                      ? null
                      : dialogIsRecording
                      ? stopRecording
                      : startRecording,
                  icon: Icon(
                    dialogIsRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                  ),
                  label: Text(
                    dialogIsRecording ? "Stop Recording" : "Start Recording",
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogIsRecording
                        ? Colors.red
                        : Color(0xff2A158F),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Close Button
                TextButton(
                  onPressed: () async {
                    if (dialogIsRecording) {
                      await stopRecording();
                    }
                    dialogRecorder?.dispose();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _captureAndShare() async {
    try {
      RenderRepaintBoundary boundary =
          _popupKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save image to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/shared_dua.png').create();
      await file.writeAsBytes(pngBytes);

      // Share using share_plus
      await Share.shareXFiles([
        XFile(file.path),
      ], text: "Check out this beautiful Dua");
    } catch (e) {
      print("Error sharing: $e");
    }
  }

  Widget _buildBenefitContainer(
    String text,
    bool isRtl,
    ThemeController themeController,
    String userLanguage, {
    int? index,
  }) {
    final isLastItem =
        index != null &&
        widget.dua.benefits != null &&
        index == widget.dua.benefits!.length - 1;

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(
        top: index == null || index == 0 ? 12 : 10,
        left: 15,
        right: 15,
        bottom: isLastItem ? 12 : 8,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xffF8F6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xff2A158F).withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xff2A158F).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 1,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative icon in top-right
            Positioned(
              top: 12,
              right: isRtl ? null : 16,
              left: isRtl ? 16 : null,
              child: Icon(
                Icons.auto_awesome,
                color: Color(0xff2A158F).withValues(alpha: 0.2),
                size: 20,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Benefits icon
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xff2A158F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: Color(0xff2A158F),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        color: Color(0xff1A0E5C),
                        fontSize: userLanguage == 'Urdu'
                            ? themeController.textSize - 2
                            : themeController.textSize,
                        fontFamily: userLanguage == 'Urdu' ? 'arabic' : null,
                        height: userLanguage == 'Urdu'
                            ? ((themeController.textSize * 2) - 8) /
                                  themeController.textSize
                            : 1.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
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

  Future<String?> convertAacToMp3(String inputPath) async {
    final outputPath = inputPath.replaceAll('.aac', '.mp3');

    // final session = await FFmpegKit.execute(
    //   '-i "$inputPath" -codec:a libmp3lame -qscale:a 2 "$outputPath"',
    // );

    final file = File(outputPath);
    if (await file.exists()) {
      return outputPath;
    } else {
      return null;
    }
  }

  void showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            RepaintBoundary(
              key: _popupKey, // This is what we'll capture as image
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      randomImage,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Arabic and English Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.dua.arabic,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Divider(
                        height: 2,
                        color: rwhite,
                      ).marginSymmetric(vertical: 12),
                      Text(
                        widget.dua.english,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ).marginSymmetric(horizontal: 12),
                ],
              ),
            ),
            // Share button - not inside RepaintBoundary
            Positioned(
              bottom: 20,
              child: GestureDetector(
                onTap: _captureAndShare, // sharing function
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(0xff2A158F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "📤 Share",
                    style: TextStyle(color: rwhite),
                  ).marginSymmetric(horizontal: 20, vertical: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsList() {
    final userLanguage = Get.find<UserController>().selectedLanguage;
    final themeController = Get.find<ThemeController>();
    final isRtl = userLanguage == 'Urdu' || userLanguage == 'Arabic';

    // Handle String benefits format
    // Check both benefitsString and also check if we should show even if not parsed yet
    bool hasStringBenefits =
        widget.dua.benefitsString != null &&
        widget.dua.benefitsString!.isNotEmpty;

    // For debugging: if this is the specific dua ID and no benefitsString yet, show placeholder
    if (!widget.dua.hasBenefits() &&
        widget.dua.id == "8Sbwp6FmZK7wZUuYk4Ay" &&
        !hasStringBenefits) {
      return _buildBenefitContainer(
        "this is the best dua",
        isRtl,
        themeController,
        userLanguage,
      );
    }

    if (!widget.dua.hasBenefits() && !hasStringBenefits) {
      return SizedBox.shrink();
    }

    if (hasStringBenefits) {
      return _buildBenefitContainer(
        widget.dua.benefitsString!,
        isRtl,
        themeController,
        userLanguage,
      );
    }

    // Handle List benefits format
    if (widget.dua.benefits == null || widget.dua.benefits!.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        ...widget.dua.benefits!.asMap().entries.map((entry) {
          final index = entry.key;
          final benefitText = widget.dua.getBenefitText(index, userLanguage);

          if (benefitText == null || benefitText.isEmpty) {
            return SizedBox.shrink();
          }

          return _buildBenefitContainer(
            benefitText,
            isRtl,
            themeController,
            userLanguage,
            index: index,
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String audioPath = widget.dua.littleKidsAudio;
    // Separate isPlaying check for the first button (littleKidsAudio)
    bool isPlayingAudio = widget.currentlyPlayingPath == audioPath;

    return GetBuilder<UserController>(
      builder: (userController) {
        var userModel = userController.userModel;
        return GetBuilder<ThemeController>(
          builder: (themeController) {
            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: rpink,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () =>
                                  widget.onToggle(audioPath, widget.dua.id),
                              child: Icon(
                                isPlayingAudio
                                    ? Icons.stop_circle
                                    : Icons.play_circle,
                                color:
                                    (userModel != null &&
                                        userModel.readDuas.contains(
                                          widget.dua.id,
                                        ))
                                    ? Colors.grey
                                    : Color(0xff2A158F),
                              ),
                            ),
                            SizedBox(height: 20),
                            InkWell(
                              onTap: _openRecordingDialog,
                              child: Icon(Icons.mic, color: Color(0xff2A158F)),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Text(
                            widget.dua.arabic,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: rblack,
                              fontSize: themeController.textSize,
                              fontFamily: 'arabic',
                            ),
                          ),
                        ),
                      ],
                    ).marginAll(15),
                    Divider(height: 2, color: rwhite),
                    if (themeController.showTransliteration)
                      Text(
                        widget.dua.transliteration,
                        widget.dua.transliteration,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: rblack,
                          fontSize: themeController.textSize,
                        ),
                      ).marginAll(15),
                    Divider(height: 2, color: rwhite),
                    if (themeController.showTranslation)
                      Builder(
                        builder: (context) {
                          // Calculate translation audio path and playing state
                          String? translationAudioPath;
                          if (Get.find<UserController>().selectedLanguage ==
                              "Urdu") {
                            translationAudioPath = widget.dua.urduTranslation;
                          } else {
                            translationAudioPath =
                                widget.dua.englishTranslation;
                          }

                          // Separate isPlaying check for translation audio
                          bool isPlayingTranslation =
                              translationAudioPath != null &&
                              translationAudioPath.isNotEmpty &&
                              widget.currentlyPlayingPath ==
                                  translationAudioPath;

                          return Row(
                            children: [
                              if (Get.find<UserController>().selectedLanguage ==
                                      "English" ||
                                  Get.find<UserController>().selectedLanguage ==
                                      "Urdu")
                                InkWell(
                                  onTap: () {
                                    if (Get.find<UserController>()
                                            .selectedLanguage ==
                                        "Urdu") {
                                      if (widget.dua.urduTranslation != null &&
                                          widget.dua.urduTranslation != "") {
                                        return widget.onToggle(
                                          widget.dua.urduTranslation!,
                                          widget.dua.id,
                                        );
                                      }
                                    } else {
                                      if (widget.dua.englishTranslation !=
                                              null &&
                                          widget.dua.englishTranslation != "") {
                                        return widget.onToggle(
                                          widget.dua.englishTranslation!,
                                          widget.dua.id,
                                        );
                                      }
                                    }
                                  },
                                  child: Icon(
                                    isPlayingTranslation
                                        ? Icons.stop_circle
                                        : Icons.play_circle,
                                    color:
                                        Get.find<UserController>()
                                                .selectedLanguage ==
                                            "Urdu"
                                        ? widget.dua.urduTranslation != null
                                              ? Color(0xff2A158F)
                                              : rpink
                                        : widget.dua.englishTranslation != null
                                        ? Color(0xff2A158F)
                                        : rpink,
                                  ),
                                ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Text(
                                  widget.dua.getName(
                                    Get.find<UserController>().selectedLanguage,
                                  ),
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    color: rblack,
                                    fontSize: themeController.textSize,
                                  ),
                                ),
                              ),
                            ],
                          ).marginAll(15);
                        },
                      ),
                    // Divider before buttons section
                    if (themeController.showTranslation)
                      Divider(height: 2, color: rwhite),
                    // Debug: Print all benefits data
                    Builder(
                      builder: (context) {
                        print('=== DUA BENEFITS DEBUG ===');
                        print('Dua ID: ${widget.dua.id}');
                        print('benefitsString: ${widget.dua.benefitsString}');
                        print(
                          'benefitsString is null: ${widget.dua.benefitsString == null}',
                        );
                        print(
                          'benefitsString isEmpty: ${widget.dua.benefitsString?.isEmpty ?? "N/A"}',
                        );
                        print('benefits: ${widget.dua.benefits}');
                        print(
                          'benefits is null: ${widget.dua.benefits == null}',
                        );
                        print(
                          'benefits isEmpty: ${widget.dua.benefits?.isEmpty ?? "N/A"}',
                        );
                        print('hasBenefits(): ${widget.dua.hasBenefits()}');
                        print('==========================');
                        return SizedBox.shrink();
                      },
                    ),
                    // Benefits Toggle, Check Recitation, and Share Button Row
                    Builder(
                      builder: (context) {
                        final hasBenefits =
                            widget.dua.hasBenefits() ||
                            widget.dua.id == "8Sbwp6FmZK7wZUuYk4Ay";
                        final hasShare = widget.dua.arabic.length < 200;
                        final buttonCount =
                            (hasBenefits ? 1 : 0) +
                            1 +
                            (hasShare
                                ? 1
                                : 0); // Benefits + Check Recitation + Share

                        return Row(
                          children: [
                            // Benefits Toggle Button (only show if benefits exist)
                            if (hasBenefits)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: buttonCount > 1 ? 4 : 0,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        final isExpanded =
                                            widget.expandedBenefitsDuaId ==
                                            widget.dua.id;
                                        widget.onToggleBenefits(
                                          isExpanded ? null : widget.dua.id,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors:
                                                widget.expandedBenefitsDuaId ==
                                                    widget.dua.id
                                                ? [
                                                    Color(
                                                      0xff2A158F,
                                                    ).withOpacity(0.2),
                                                    Color(
                                                      0xff2A158F,
                                                    ).withOpacity(0.1),
                                                  ]
                                                : [
                                                    Color(
                                                      0xff2A158F,
                                                    ).withOpacity(0.15),
                                                    Color(
                                                      0xff5C3FB0,
                                                    ).withOpacity(0.1),
                                                  ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color:
                                                widget.expandedBenefitsDuaId ==
                                                    widget.dua.id
                                                ? Color(0xff2A158F)
                                                : Color(
                                                    0xff2A158F,
                                                  ).withOpacity(0.7),
                                            width:
                                                widget.expandedBenefitsDuaId ==
                                                    widget.dua.id
                                                ? 2
                                                : 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(
                                                0xff2A158F,
                                              ).withOpacity(0.15),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AnimatedSwitcher(
                                              duration: Duration(
                                                milliseconds: 300,
                                              ),
                                              child: Icon(
                                                widget.expandedBenefitsDuaId ==
                                                        widget.dua.id
                                                    ? Icons.expand_less
                                                    : Icons.expand_more,
                                                key: ValueKey(
                                                  widget.expandedBenefitsDuaId ==
                                                      widget.dua.id,
                                                ),
                                                color: Color(0xff2A158F),
                                                size: 18,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                widget.expandedBenefitsDuaId ==
                                                        widget.dua.id
                                                    ? "Hide Benefits"
                                                    : "Show Benefits",
                                                style: TextStyle(
                                                  color: Color(0xff2A158F),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.favorite_border,
                                              color: Color(
                                                0xff2A158F,
                                              ).withOpacity(0.7),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Check Recitation Button (Always shown)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: buttonCount > 1 ? 4 : 0,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      _openRecordingDialog();
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xff2A158F).withOpacity(0.15),
                                            Color(0xff5C3FB0).withOpacity(0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Color(
                                            0xff2A158F,
                                          ).withOpacity(0.7),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(
                                              0xff2A158F,
                                            ).withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.mic,
                                            color: Color(0xff2A158F),
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              "Check Recitation",
                                              style: TextStyle(
                                                color: Color(0xff2A158F),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Share Button (only show for short duas)
                            if (hasShare)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: buttonCount > 1 ? 4 : 0,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        showShareDialog();
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(
                                                0xff2A158F,
                                              ).withOpacity(0.15),
                                              Color(
                                                0xff5C3FB0,
                                              ).withOpacity(0.1),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Color(
                                              0xff2A158F,
                                            ).withOpacity(0.7),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(
                                                0xff2A158F,
                                              ).withOpacity(0.15),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.share,
                                              color: Color(0xff2A158F),
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                "Share",
                                                style: TextStyle(
                                                  color: Color(0xff2A158F),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ).marginSymmetric(horizontal: 15, vertical: 12);
                      },
                    ),

                    // Expanded Benefits List with smooth animation
                    AnimatedSize(
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child:
                          widget.expandedBenefitsDuaId == widget.dua.id &&
                              (widget.dua.hasBenefits() ||
                                  widget.dua.id == "8Sbwp6FmZK7wZUuYk4Ay")
                          ? _buildBenefitsList()
                          : SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ).marginSymmetric(horizontal: 12, vertical: 8);
          },
        );
      },
    );
  }
}
