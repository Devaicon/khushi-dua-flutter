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
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../constants/colors.dart';
import '../controllers/userController.dart';
import '../models/duaModel.dart';
import '../models/subCategoryModel.dart';
import '../services/audioDownloadService.dart';

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

      // Check if local file exists
      final downloadService = Get.find<AudioDownloadService>();
      final themeController = Get.find<ThemeController>();
      final localPath = await downloadService.getLocalPath(
        duaId,
        themeController.selectedAgeGroup,
      );

      if (localPath != null) {
        debugPrint("Playing local audio: $localPath");
        await _audioPlayer.play(DeviceFileSource(localPath));
      } else {
        debugPrint("Playing remote audio: $path");
        await _audioPlayer.play(UrlSource(path));
      }

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
      backgroundColor: const Color(0xffF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Duas".tr,
          style: const TextStyle(
            color: rblack,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: rblack,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: showTextOptionsPopup,
            icon: const Icon(Icons.text_fields_rounded, color: rblack),
          ).marginOnly(right: 8),
        ],
      ),
      body: GetBuilder<DuaController>(
        builder: (duaController) {
          if (duaController.filteredDuas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Duas found".tr,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: duaController.filteredDuas.length,
            itemBuilder: (context, index) {
              return DuaTile(
                dua: duaController.filteredDuas[index],
                currentlyPlayingPath: _currentlyPlayingPath,
                onToggle: _toggleAudio,
                expandedBenefitsDuaId: _expandedBenefitsDuaId,
                onToggleBenefits: (duaId) {
                  setState(() {
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
    
    debugPrint("OpenDuasScreen: Share feature initialized with random image: $randomImage");
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
        })
        .catchError((error) {
          debugPrint('Error fetching base URL from Firebase: $error');
          baseUrl = 'http://34.238.195.141:3400/transcribe/'; // Fallback
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

                debugPrint('\n📂 FILE VERIFICATION:');
                debugPrint('   - File exists: ${await audioFile.exists()}');
                debugPrint(
                  '   - File size on disk: ${(fileSize / 1024).toStringAsFixed(2)} KB',
                );
                debugPrint(
                  '   - Bytes read: ${(fileBytes.length / 1024).toStringAsFixed(2)} KB',
                );
                debugPrint(
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
                debugPrint('\n========== API CALL START ==========');
                debugPrint('📡 BASE URL (from Firebase): $baseUrl');
                debugPrint('🔗 FULL API URL: $apiUrl');
                debugPrint('📝 METHOD: POST');
                debugPrint('📋 ARABIC TEXT (Original): ${widget.dua.arabic}');
                debugPrint('📋 ARABIC TEXT (Encoded): $encodedArabic');
                debugPrint('🎵 AUDIO FILE PATH: $audioPath');
                debugPrint('📁 AUDIO FILE NAME: $fileName');
                debugPrint(
                  '📦 AUDIO FILE SIZE: ${(fileSize / 1024).toStringAsFixed(2)} KB',
                );
                debugPrint('🎚️ CONTENT TYPE: $contentType');
                debugPrint('📤 PAYLOAD: multipart/form-data');
                debugPrint('   - Field: audio_file');
                debugPrint('   - File: $fileName');
                debugPrint(
                  '   - Size: ${(fileSize / 1024).toStringAsFixed(2)} KB',
                );
                debugPrint('   - Bytes: ${fileBytes.length} bytes');
                debugPrint('   - Type: $contentType');
                debugPrint('📨 HEADERS:');
                debugPrint(
                  '   - Content-Type: multipart/form-data (auto-set by MultipartRequest)',
                );
                debugPrint('   - No custom headers (matching HTML version)');
                debugPrint('=====================================\n');

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

                debugPrint(
                  '⏳ Sending request to API with ${fileBytes.length} bytes...\n',
                );
                debugPrint('🌐 Network Request Details:');
                final parsedUri = Uri.parse(apiUrl);
                debugPrint('   - Host: ${parsedUri.host}');
                debugPrint('   - Port: ${parsedUri.port}');
                debugPrint('   - Scheme: ${parsedUri.scheme}');
                debugPrint('   - Path: ${parsedUri.path}');
                debugPrint('   - Query: ${parsedUri.query}');
                debugPrint('   - Full URL: $apiUrl');
                debugPrint('');

                // Test connection first (optional - can help diagnose issues)
                debugPrint('🔍 Testing server connectivity...');
                try {
                  final testClient = http.Client();
                  final testResponse = await testClient
                      .get(
                        Uri.parse(
                          '${parsedUri.scheme}://${parsedUri.host}:${parsedUri.port}',
                        ),
                      )
                      .timeout(const Duration(seconds: 10));
                  debugPrint(
                    '   ✅ Server is reachable (HTTP ${testResponse.statusCode})',
                  );
                  testClient.close();
                } catch (e) {
                  debugPrint('   ⚠️  Server connectivity test failed: $e');
                  debugPrint(
                    '   ℹ️  This might be normal if server only accepts POST requests',
                  );
                }
                debugPrint('');

                // Send request with timeout (2 minutes for audio processing)
                var response = await request.send().timeout(
                  const Duration(seconds: 120), // 2 minutes timeout
                  onTimeout: () {
                    throw TimeoutException(
                      'Request timeout after 2 minutes',
                      const Duration(seconds: 120),
                    );
                  },
                );

                var responseBody = await response.stream.bytesToString();

                if (response.statusCode == 200) {
                  debugPrint('Transcription API Success');
                  debugPrint('Transcription API Call End');
                  setDialogState(() {
                    dialogApiResponse = responseBody;
                  });
                } else {
                  debugPrint(
                    'Transcription API Error: Status ${response.statusCode}',
                  );
                  debugPrint('Transcription API Error Body: $responseBody');
                  debugPrint('Transcription API Call End');
                  setDialogState(() {
                    dialogApiResponse =
                        "Error: Server returned status ${response.statusCode}";
                  });
                }
              } on TimeoutException catch (e) {
                debugPrint('Transcription Timeout: ${e.message}');
                debugPrint('Transcription API Call End');
                setDialogState(() {
                  dialogApiResponse =
                      "Error: Request timed out. The audio processing is taking longer than expected. Please try again.";
                });
              } on SocketException catch (e) {
                debugPrint('Transcription Network Error: ${e.message}');
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
                debugPrint('📡 HTTP ERROR: ${e.message}');
                debugPrint('========== API CALL END ==========\n');
                setDialogState(() {
                  dialogApiResponse = "Error: HTTP error - ${e.message}";
                });
              } catch (e, stackTrace) {
                debugPrint('❌ EXCEPTION: ${e.toString()}');
                debugPrint('   - Type: ${e.runtimeType}');
                debugPrint('📚 STACK TRACE:');
                debugPrint(stackTrace.toString());
                debugPrint('========== API CALL END ==========\n');
                setDialogState(() {
                  dialogApiResponse = "Error: ${e.toString()}";
                });
              } finally {
                setDialogState(() => dialogIsLoading = false);
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

            void updateRecordingDuration() {
              Future.delayed(const Duration(seconds: 1), () async {
                if (dialogIsRecording) {
                  if (dialogRecordingDuration.inSeconds >= 29) {
                    await stopRecording();
                    Get.snackbar(
                      "Recording Limit",
                      "Recording cannot be more than 29 seconds",
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  setDialogState(() {
                    dialogRecordingDuration = Duration(
                      seconds: dialogRecordingDuration.inSeconds + 1,
                    );
                  });
                  updateRecordingDuration();
                }
              });
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

                    // Recording Limit Info
                    if (!dialogIsLoading && dialogApiResponse == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          "Max recording length: 29 seconds",
                          style: TextStyle(
                            fontSize: 12,
                            color: dialogIsRecording
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

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
      debugPrint("📸 Starting capture and share process...");
      
      // Ensure all fonts are loaded before capturing
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if the context is still valid
      if (_popupKey.currentContext == null) {
        debugPrint("❌ Error: Context is null, cannot capture image");
        if (mounted && Get.context != null) {
          Get.snackbar(
            'Error',
            'Failed to prepare image. Please try again.',
            backgroundColor: Colors.red.withOpacity(0.7),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return;
      }

      debugPrint("✅ Context is valid, finding boundary...");
      RenderRepaintBoundary? boundary =
          _popupKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint("❌ Error: Boundary is null");
        return;
      }

      debugPrint("✅ Boundary found, capturing image...");
      // Use higher pixel ratio for better quality on iOS
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      
      if (byteData == null) {
        debugPrint("❌ Error: Failed to convert image to bytes");
        return;
      }
      
      Uint8List pngBytes = byteData.buffer.asUint8List();
      debugPrint("✅ Image captured successfully (${pngBytes.length} bytes)");

      // Save image to temporary file with timestamp
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = await File(
        '${tempDir.path}/shared_dua_$timestamp.png',
      ).create();
      await file.writeAsBytes(pngBytes);

      debugPrint("✅ Image saved to: ${file.path}");

      // Close the dialog first, then share
      if (mounted) {
        Navigator.of(context).pop();
        debugPrint("✅ Dialog closed");
      }

      // Small delay to ensure dialog is closed
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint("📤 Opening share sheet...");
      // Share using share_plus with proper iOS handling
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: "Check out this beautiful Dua from Khushi Dua App",
        subject: "Khushi Dua",
      );

      debugPrint("✅ Share result: ${result.status}");
      
      // Clean up the temporary file after sharing
      try {
        await file.delete();
        debugPrint("✅ Temporary file cleaned up");
      } catch (e) {
        debugPrint("⚠️ Error deleting temp file: $e");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error sharing: $e");
      debugPrint("Stack trace: $stackTrace");
      if (mounted && Get.context != null) {
        Get.snackbar(
          'Error',
          'Failed to share: ${e.toString()}',
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
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

    bool hasStringBenefits =
        widget.dua.benefitsString != null &&
        widget.dua.benefitsString!.isNotEmpty;

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
      return const SizedBox.shrink();
    }

    if (hasStringBenefits) {
      return _buildBenefitContainer(
        widget.dua.benefitsString!,
        isRtl,
        themeController,
        userLanguage,
      );
    }

    if (widget.dua.benefits == null || widget.dua.benefits!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.dua.benefits!.asMap().entries.map((entry) {
          final benefitText = widget.dua.getBenefitText(
            entry.key,
            userLanguage,
          );
          if (benefitText == null || benefitText.isEmpty) {
            return const SizedBox.shrink();
          }
          return _buildBenefitContainer(
            benefitText,
            isRtl,
            themeController,
            userLanguage,
            index: entry.key,
          );
        }),
      ],
    );
  }

  Widget _buildBenefitContainer(
    String text,
    bool isRtl,
    ThemeController themeController,
    String userLanguage, {
    int? index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff2A158F).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff2A158F).withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xff2A158F),
              shape: BoxShape.circle,
            ),
            child: Text(
              "${(index ?? 0) + 1}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              textAlign: isRtl ? TextAlign.end : TextAlign.start,
              style: TextStyle(
                color: rtext.withOpacity(0.9),
                fontSize: themeController.textSize * 0.85,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String audioPath = widget.dua.littleKidsAudio;
    bool isPlayingAudio = widget.currentlyPlayingPath == audioPath;

    return GetBuilder<UserController>(
      builder: (userController) {
        return GetBuilder<ThemeController>(
          builder: (themeController) {
            Color accentColor = themeController.selectedAgeGroup == 0
                ? rpink
                : themeController.selectedAgeGroup == 1
                ? rblue
                : rgreen;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: accentColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  children: [
                    // Focused Header with Metadata & Core Actions
                    _buildHeader(accentColor, isPlayingAudio, audioPath),

                    // The Sacred Arabic Text
                    GestureDetector(
                      onLongPress: () {
                        // Copy to clipboard or other context action
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width < 360
                              ? 16
                              : 24,
                          vertical: MediaQuery.of(context).size.width < 360
                              ? 20
                              : 32,
                        ),
                        width: double.infinity,
                        color: accentColor.withOpacity(0.02),
                        child: Text(
                          widget.dua.arabic,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: MediaQuery.of(context).size.width < 360
                                ? themeController.textSize
                                : themeController.textSize * 1.15,
                            height: 2.0,
                            fontFamily: 'arabic',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),

                    // Transliteration & Translation with selective visibility
                    _buildContentSections(themeController, accentColor),

                    // Expandable Benefits
                    _buildBenefitsSection(themeController, accentColor),

                    // Minimal Footer Actions
                    _buildFooter(accentColor),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(Color accentColor, bool isPlaying, String audioPath) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _CircleAction(
            icon: isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: accentColor,
            onTap: () => widget.onToggle(audioPath, widget.dua.id),
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: Icons.mic_none_rounded,
            color: const Color(0xff2A158F),
            onTap: _openRecordingDialog,
          ),
          const Spacer(),
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: ClipOval(child: Image.asset(randomImage, fit: BoxFit.cover)),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSections(
    ThemeController themeController,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (themeController.showTransliteration) ...[
            _SectionLabel(label: "TRANSLITERATION", color: accentColor),
            const SizedBox(height: 8),
            Text(
              widget.dua.transliteration,
              style: TextStyle(
                color: rtext.withOpacity(0.7),
                fontSize: themeController.textSize * 0.9,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (themeController.showTranslation) ...[
            Row(
              children: [
                _SectionLabel(label: "TRANSLATION", color: accentColor),
                const Spacer(),
                _buildTranslationAudio(accentColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.dua.getName(Get.find<UserController>().selectedLanguage),
              style: TextStyle(
                color: rtext,
                fontSize: themeController.textSize * 0.9,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTranslationAudio(Color accentColor) {
    String? path = Get.find<UserController>().selectedLanguage == "Urdu"
        ? widget.dua.urduTranslation
        : widget.dua.englishTranslation;

    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }

    bool isPlaying = widget.currentlyPlayingPath == path;

    return InkWell(
      onTap: () => widget.onToggle(path, widget.dua.id),
      child: Icon(
        isPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        size: 18,
        color: accentColor,
      ),
    );
  }

  Widget _buildBenefitsSection(
    ThemeController themeController,
    Color accentColor,
  ) {
    bool isExpanded = widget.expandedBenefitsDuaId == widget.dua.id;
    bool hasBenefits =
        widget.dua.hasBenefits() || widget.dua.id == "8Sbwp6FmZK7wZUuYk4Ay";

    if (!hasBenefits) return const SizedBox.shrink();

    return Column(
      children: [
        InkWell(
          onTap: () =>
              widget.onToggleBenefits(isExpanded ? null : widget.dua.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black.withOpacity(0.03)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  "Benefits & Virtues".tr,
                  style: TextStyle(
                    color: rtext,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildBenefitsList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFooter(Color accentColor) {
    bool hasShare = widget.dua.arabic.length < 500;
    if (!hasShare) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: showShareDialog,
          icon: const Icon(Icons.share_rounded, size: 16),
          label: Text(
            "SHARE DUA".tr,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.tr,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 10,
        letterSpacing: 1.5,
      ),
    );
  }
}
