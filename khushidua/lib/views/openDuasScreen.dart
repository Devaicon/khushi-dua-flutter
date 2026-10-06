import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:khushidua/constants/firebaseRef.dart';
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/controllers/themeController.dart';
import 'package:khushidua/controllers/audioController.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../constants/colors.dart';
import '../constants/theme.dart';
import '../controllers/userController.dart';
import '../models/duaModel.dart';
import '../models/subCategoryModel.dart';
import '../widgets/listenedHelp.dart';
import '../widgets/skeleton.dart';
import 'imageScreen.dart';

/// "1 dua" / "5 duas", translated.
String duaCountLabel(int count) =>
    count == 1 ? "1 dua".tr : "@count duas".trParams({'count': '$count'});

/// The recording dialog's purple, as text and icons: deep on the light theme,
/// lightened on the dark one where the deep shade would disappear.
Color get _recordInk =>
    AppPalette.isDark ? const Color(0xFFB39DDB) : const Color(0xff2A158F);

class OpenDuasScreen extends StatefulWidget {
  final SubCategoryModel _subCategoryModel;

  /// The category's colour, carried through so the section reads as part of
  /// the category it was opened from.
  final Color color;

  /// Opens scrolled to this dua (its number in the section, from 1), as
  /// when a search for "morning 3" is tapped.
  final int? scrollToNumber;

  const OpenDuasScreen(
    this._subCategoryModel, {
    super.key,
    this.color = rpurple,
    this.scrollToNumber,
  });

  @override
  State<OpenDuasScreen> createState() => _OpenDuasScreenState();
}

class _OpenDuasScreenState extends State<OpenDuasScreen> {
  String? _expandedBenefitsDuaId; // Track which dua has benefits expanded

  /// On the dua to scroll to, when there is one.
  final GlobalKey _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToNumber != null) {
      // After the first layout, when the tile exists to scroll to.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _targetKey.currentContext;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(
            target,
            duration: AppMotion.slow,
            curve: AppMotion.curve,
            alignment: 0.1,
          );
        }
      });
    }
  }

  SubCategoryModel get _section => widget._subCategoryModel;

  /// Kids' sections carry an illustration. It used to be a screen of its own
  /// the reader had to tap through; now it heads the dua list instead.
  bool get _showIllustration =>
      _section.image.isNotEmpty &&
      Get.find<ThemeController>().selectedAgeGroup != 2;

  void showTextOptionsPopup() {
    Get.bottomSheet(const _ReadingOptionsSheet(), isScrollControlled: true);
  }

  @override
  Widget build(BuildContext context) {
    final language = Get.find<UserController>().selectedLanguage;
    return Scaffold(
      backgroundColor: AppSurface.page,
      body: GetBuilder<DuaController>(
        builder: (duaController) {
          final duas = duaController.duasFor(_section.id);
          return GetBuilder<UserController>(
            builder: (userController) {
              final readDuas = userController.userModel?.readDuas;
              final listened = readDuas == null
                  ? null
                  : duas.where((d) => readDuas.contains(d.id)).length;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                // Builds the whole section when scrolling to a dua in it, so
                // the target exists to scroll to; sections hold few duas.
                cacheExtent: widget.scrollToNumber != null ? 100000 : null,
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: AppSurface.page,
                    surfaceTintColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: rbluedark,
                        size: 20,
                      ),
                      onPressed: () => Get.back(),
                    ),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _section.getName(language),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: rbluedark,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          listened == null || duas.isEmpty
                              ? duaCountLabel(duas.length)
                              : "@done of @total listened".trParams({
                                  'done': '$listened',
                                  'total': '${duas.length}',
                                }),
                          style: TextStyle(
                            color: AppText.onPageMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        tooltip: "Reading options".tr,
                        onPressed: showTextOptionsPopup,
                        icon: Icon(Icons.text_fields_rounded, color: rbluedark),
                      ),
                      const SizedBox(width: AppSpace.xs),
                    ],
                  ),
                  if (_showIllustration)
                    SliverToBoxAdapter(child: _buildIllustration()),
                  SliverToBoxAdapter(child: _buildListenedTip(userController)),
                  if (duas.isEmpty)
                    SliverToBoxAdapter(child: _buildEmpty())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: AppSpace.xxl),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => DuaTile(
                            key: index + 1 == widget.scrollToNumber
                                ? _targetKey
                                : ValueKey(duas[index].id),
                            dua: duas[index],
                            number: index + 1,
                            total: duas.length,
                            color: widget.color,
                            expandedBenefitsDuaId: _expandedBenefitsDuaId,
                            onToggleBenefits: (duaId) {
                              setState(() {
                                _expandedBenefitsDuaId =
                                    _expandedBenefitsDuaId == duaId
                                    ? null
                                    : duaId;
                              });
                            },
                          ),
                          childCount: duas.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIllustration() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: GestureDetector(
        onTap: () => Get.to(
          () => ImageScreen(subCategoryModel: _section),
          transition: Transition.fadeIn,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardAll,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: widget.color.withValues(alpha: 0.2)),
                // Only the picture flies to the full-screen viewer; the tint
                // and the expand badge stay behind on the card.
                Hero(
                  tag: 'section_image_${_section.id}',
                  child: Image.network(
                    _section.image,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Skeleton(child: const SkeletonBox(radius: 0)),
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported_rounded,
                      color: widget.color.ink.withValues(alpha: 0.5),
                      size: 40,
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpace.sm,
                  bottom: AppSpace.sm,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.open_in_full_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The one-time tip explaining "listened".
  Widget _buildListenedTip(UserController userController) {
    final loggedIn = userController.userModel != null;
    return FirstTimeTip(
      key: ValueKey(loggedIn),
      prefsKey: loggedIn ? kListenedTipSeenKey : '$kListenedTipSeenKey.guest',
      color: widget.color,
      message: loggedIn
          ? "Play a dua's audio all the way to the end to mark it as listened. Listening to duas unlocks more sections."
                .tr
          : "Log in to keep track of the duas you have listened to.".tr,
    ).paddingSymmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm);
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppText.onPageMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            "No Duas found".tr,
            style: TextStyle(color: AppText.onPageMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Font size and which lines to show, applied live to the list behind it.
class _ReadingOptionsSheet extends StatelessWidget {
  const _ReadingOptionsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xl,
          AppSpace.md,
          AppSpace.xl,
          AppSpace.lg,
        ),
        decoration: BoxDecoration(
          color: AppSurface.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: GetBuilder<ThemeController>(
          builder: (theme) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: AppRadius.pillAll,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                "Reading options".tr,
                style: TextStyle(
                  color: rbluedark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                "Font Size".tr,
                style: TextStyle(color: rtext, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  const Icon(Icons.text_decrease_rounded, color: rhint),
                  Expanded(
                    child: Slider(
                      value: theme.textSize,
                      min: 14,
                      max: 27,
                      divisions: 13,
                      label: theme.textSize.round().toString(),
                      onChanged: theme.setTextSize,
                    ),
                  ),
                  const Icon(Icons.text_increase_rounded, color: rhint),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Show transliteration".tr,
                  style: TextStyle(color: rtext),
                ),
                value: theme.showTransliteration,
                onChanged: theme.setShowTransliteration,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Show translation".tr,
                  style: TextStyle(color: rtext),
                ),
                value: theme.showTranslation,
                onChanged: theme.setShowTranslation,
              ),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Get.back(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.smAll,
                    ),
                  ),
                  child: Text("Done".tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DuaTile extends StatefulWidget {
  final DuaModel dua;
  final String? expandedBenefitsDuaId;
  final Function(String?) onToggleBenefits;

  /// Position in the section, shown as "Dua 2 of 5".
  final int number;
  final int total;
  final Color color;

  const DuaTile({
    required this.dua,
    required this.expandedBenefitsDuaId,
    required this.onToggleBenefits,
    required this.number,
    required this.total,
    required this.color,
    super.key,
  });

  @override
  State<DuaTile> createState() => _DuaTileState();
}

class _DuaTileState extends State<DuaTile> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String baseUrl = "";
  bool _isSharing = false;

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

    debugPrint(
      "OpenDuasScreen: Share feature initialized with random image: $randomImage",
    );
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
                    if (Get.context != null) {
                      Get.snackbar(
                        "Recording Limit",
                        "Recording cannot be more than 29 seconds",
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
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
                  Icon(Icons.mic, color: _recordInk),
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
                              color: _recordInk,
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
                            color: _recordInk.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              widget.dua.arabic,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: _recordInk,
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
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_recordInk),
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
                          color: _recordInk.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_none,
                          color: _recordInk,
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
                // Enhanced Close Button
                OutlinedButton(
                  onPressed: () async {
                    if (dialogIsRecording) {
                      await stopRecording();
                    }
                    dialogRecorder?.dispose();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _recordInk.withOpacity(0.3),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      color: _recordInk.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
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

      // Ensure all fonts and images are rendered before capturing
      await Future.delayed(const Duration(milliseconds: 300));

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
          _popupKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary?;

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

      // Get screen size for iPad share sheet positioning
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.fromLTWH(0, 0, 100, 100);

      debugPrint("📤 Opening share sheet (keeping dialog for context)...");

      // Share using share_plus with proper iOS handling
      // We do NOT pop the dialog until AFTER the share sheet is requested
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: "Check out this beautiful Dua from Khushi Dua App".tr,
        subject: "Khushi Dua".tr,
        sharePositionOrigin: sharePositionOrigin,
      );

      debugPrint("✅ Share sheet requested. Result: ${result.status}");

      // Now close the dialog
      if (mounted) {
        Navigator.of(context).pop();
        debugPrint("✅ Dialog closed");
      }

      // Clean up the temporary file
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
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: AppSurface.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scrollable content area
                    Flexible(
                      child: SingleChildScrollView(
                        child: RepaintBoundary(
                          key: _popupKey,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background Image
                              Image.asset(
                                randomImage,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              // Overlay
                              Container(
                                color: Colors.black.withOpacity(0.3),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 20),
                                    Text(
                                      widget.dua.arabic,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'arabic',
                                        height: 1.8,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Divider(
                                        color: Colors.white54,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      widget.dua.english,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    // App Branding in the shared image
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Khushi Dua App".tr,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            letterSpacing: 1,
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
                      ),
                    ),
                    // Action Footer
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppSurface.card,
                        border: Border(top: BorderSide(color: AppSurface.line)),
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          debugPrint("🖱️ Share button tapped in dialog");
                          if (_isSharing) {
                            debugPrint("⚠️ Already sharing, ignoring tap");
                            return;
                          }

                          // Update both states to be safe
                          setState(() => _isSharing = true);
                          setDialogState(() => _isSharing = true);

                          try {
                            debugPrint("🏃 Calling _captureAndShare...");
                            await _captureAndShare();
                          } catch (e) {
                            debugPrint("❌ Exception in onTap sharing: $e");
                          } finally {
                            if (mounted) {
                              setState(() => _isSharing = false);
                              try {
                                setDialogState(() => _isSharing = false);
                              } catch (_) {}
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isSharing
                                  ? [Colors.grey, Colors.grey.shade400]
                                  : [
                                      const Color(0xff4A3AFF),
                                      const Color(0xff2A158F),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (!_isSharing)
                                BoxShadow(
                                  color: const Color(
                                    0xff2A158F,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                            ],
                          ),
                          child: _isSharing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "PREPARING SHARE...".tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.share_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Share This Dua".tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
        color: _recordInk.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
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
    return GetBuilder<AudioController>(
      builder: (audioController) {
        return GetBuilder<UserController>(
          builder: (userController) {
            return GetBuilder<ThemeController>(
              builder: (themeController) {
                final accent = widget.color.ink;
                final ageGroup = themeController.selectedAgeGroup;

                String audioPath = ageGroup == 0
                    ? widget.dua.littleKidsAudio
                    : ageGroup == 1
                    ? widget.dua.olderKidsAudio
                    : widget.dua.grownUpsAudio;

                bool isPlayingAudio =
                    audioController.currentlyPlayingPath == audioPath &&
                    audioController.currentlyPlayingDuaId == widget.dua.id;

                final isNarrow = MediaQuery.of(context).size.width < 360;

                return Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.sm,
                    AppSpace.lg,
                    AppSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppSurface.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isPlayingAudio
                          ? widget.color.withValues(alpha: 0.7)
                          : widget.color.withValues(alpha: 0.3),
                      width: isPlayingAudio ? 1.8 : 1.2,
                    ),
                    boxShadow: AppElevation.card,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(userController),

                        // The Arabic text, the heart of the card.
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            isNarrow ? 16 : 24,
                            isNarrow ? 12 : 16,
                            isNarrow ? 16 : 24,
                            isNarrow ? 16 : 20,
                          ),
                          color: widget.color.withValues(alpha: 0.06),
                          child: Text(
                            widget.dua.arabic,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: rtext,
                              fontSize: isNarrow
                                  ? themeController.textSize
                                  : themeController.textSize * 1.15,
                              height: 2.0,
                              fontFamily: 'arabic',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        _buildContentSections(themeController, accent),

                        _buildActions(accent, isPlayingAudio, audioPath),

                        _buildTranslationAudio(accent),

                        _buildBenefitsSection(themeController, accent),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// "Dua 2 of 5", and a Listened mark once its audio has played through.
  Widget _buildHeader(UserController userController) {
    final isListened =
        userController.userModel?.readDuas.contains(widget.dua.id) ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.18),
              borderRadius: AppRadius.pillAll,
            ),
            child: Text(
              "Dua @index of @total".trParams({
                'index': '${widget.number}',
                'total': '${widget.total}',
              }),
              style: TextStyle(
                color: widget.color.ink,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          if (isListened) ListenedBadge(color: widget.color),
        ],
      ),
    );
  }

  /// Listen, practise and share, in one row under the text.
  Widget _buildActions(Color accent, bool isPlaying, String audioPath) {
    final hasAudio = audioPath.isNotEmpty;
    final canShare = widget.dua.arabic.length < 2500;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _ActionButton(
              icon: isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              label: (isPlaying ? "Stop" : "Listen").tr,
              color: hasAudio ? accent : Colors.grey,
              filled: true,
              onTap: hasAudio
                  ? () => Get.find<AudioController>().toggleAudio(
                      audioPath,
                      widget.dua.id,
                    )
                  : () {
                      Get.snackbar(
                        'No Audio',
                        'No audio available for this age group',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.black54,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            flex: 3,
            child: _ActionButton(
              icon: Icons.mic_none_rounded,
              label: "Practice".tr,
              color: accent,
              onTap: _openRecordingDialog,
            ),
          ),
          if (canShare) ...[
            const SizedBox(width: AppSpace.sm),
            _ActionButton(
              icon: Icons.share_rounded,
              color: accent,
              onTap: _isSharing ? null : showShareDialog,
            ),
          ],
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
            _SectionLabel(label: "TRANSLATION", color: accentColor),
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

  /// English and Urdu translation audio, each with its own button and shown
  /// whenever the dua has it, whatever the app language and whether or not
  /// the translation text is visible.
  Widget _buildTranslationAudio(Color accent) {
    final tracks = [
      ("English".tr, widget.dua.englishTranslation),
      ("Urdu".tr, widget.dua.urduTranslation),
    ].where((t) => t.$2 != null && t.$2!.isNotEmpty).toList();
    if (tracks.isEmpty) return const SizedBox.shrink();

    final audio = Get.find<AudioController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: "TRANSLATION AUDIO", color: accent),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              for (int i = 0; i < tracks.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final (label, path) = tracks[i];
                      final isPlaying =
                          audio.currentlyPlayingPath == path &&
                          audio.currentlyPlayingDuaId == widget.dua.id;
                      return _ActionButton(
                        icon: isPlaying
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                        label: label,
                        color: accent,
                        onTap: () => audio.toggleAudio(path!, widget.dua.id),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(
    ThemeController themeController,
    Color accentColor,
  ) {
    bool isExpanded = widget.expandedBenefitsDuaId == widget.dua.id;
    bool hasBenefits = widget.dua.hasBenefits();

    // The row is always rendered. With a benefit it is live and expandable;
    // without one it stays greyed out and inert, so the reader can see at a
    // glance whether this dua has a benefit recorded.
    final Color labelColor = hasBenefits ? rtext : Colors.grey;
    final Color iconColor = hasBenefits ? accentColor : Colors.grey;

    return Column(
      children: [
        InkWell(
          onTap: hasBenefits
              ? () => widget.onToggleBenefits(isExpanded ? null : widget.dua.id)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black.withOpacity(0.03)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  "Benefits & Virtues".tr,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (hasBenefits)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                    size: 20,
                  )
                else
                  Text(
                    "None".tr,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded && hasBenefits
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildBenefitsList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// A dua card action. Filled for the primary one (Listen), tinted for the
/// rest; with no [label] it is a square icon button.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : color;
    return Material(
      color: filled ? color : color.withValues(alpha: 0.1),
      borderRadius: AppRadius.smAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: SizedBox(
          height: 44,
          width: label == null ? 44 : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 20),
              if (label != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
