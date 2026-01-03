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

// import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:khushidua/constants/firebaseRef.dart';
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/controllers/themeController.dart';
import 'package:path_provider/path_provider.dart';
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
                          activeColor: Colors.green,
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
                          activeColor: Colors.green,
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

  const DuaTile({
    required this.dua,
    required this.currentlyPlayingPath,
    required this.onToggle,
    super.key,
  });

  @override
  State<DuaTile> createState() => _DuaTileState();
}

class _DuaTileState extends State<DuaTile> {
  // final FlutterSoundRecord _recorder = FlutterSoundRecord();
  bool _isRecording = false;
  String? _recordedPath;

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

  getBaseUrl() async {
    await sysConfigRef.doc("MemoizationURL").get().then((value) {
      baseUrl = value.data()!["URL"];
    });
    debugPrint(baseUrl);
  }

  void _openRecordingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? apiResponse;
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> sendToApi() async {
              if (_recordedPath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please record audio first")),
                );
                return;
              }

              setState(() => isLoading = true);

              try {
                var uri = Uri.parse('$baseUrl${widget.dua.arabic}');
                debugPrint('$baseUrl${widget.dua.arabic}');
                debugPrint(widget.dua.arabic);
                debugPrint(_recordedPath);
                var request = http.MultipartRequest('POST', uri);
                request.files.add(
                  await http.MultipartFile.fromPath(
                    'audio_file',
                    _recordedPath!,
                    contentType: MediaType('audio', 'mp3'),
                  ),
                );

                request.headers.addAll({
                  'accept': 'text/html',
                  'Content-Type': 'multipart/form-data',
                });

                var response = await request.send();
                var responseBody = await response.stream.bytesToString();

                setState(() {
                  apiResponse = responseBody;
                  // debugPrint(apiResponse);
                });
              } catch (e) {
                setState(() {
                  apiResponse = "Error: $e";
                });
              } finally {
                setState(() => isLoading = false);
              }
            }

            Future<void> toggleRecording() async {
              // if (_isRecording) {
              //   final path = await _recorder.stop();
              //   setState(() => _isRecording = false);
              //   if (path != null) {
              //     _recordedPath = path;
              //     String? mp3Path = await convertAacToMp3(_recordedPath!);
              //     debugPrint("Recording complete: $mp3Path");
              //     _recordedPath = mp3Path;
              //     await sendToApi();
              //   }
              // } else {
              //   var status = await Permission.microphone.request();
              //   if (status.isGranted) {
              //     final hasPermission = await _recorder.hasPermission();
              //     if (hasPermission) {
              //       final dir = await getTemporaryDirectory();
              //       final filePath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.aac');
              //       await _recorder.start(path: filePath, encoder: AudioEncoder.AAC);
              //       setState(() {
              //         _isRecording = true;
              //         _recordedPath = filePath;
              //       });
              //     }
              //   } else {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(content: Text("Microphone permission is required.")),
              //     );
              //   }
              // }
            }

            return AlertDialog(
              title: const Text("Audio Recorder"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      widget.dua.arabic,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (isLoading) CircularProgressIndicator(),
                  if (apiResponse != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Response:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Html(data: "$apiResponse"),
                    ),
                    // Text(apiResponse!, textAlign: TextAlign.start),
                  ],
                  Text(_isRecording ? "Recording..." : "Ready to record"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: toggleRecording,
                  child: Text(
                    _isRecording ? "Finish Recording" : "Start Recording",
                  ),
                ),
                // TextButton(
                //   onPressed: () async {
                //     final result = await FilePicker.platform.pickFiles(
                //       type: FileType.custom,
                //       allowedExtensions: ['mp3'],
                //     );
                //     if (result != null && result.files.single.path != null) {
                //       setState(() {
                //         _recordedPath = result.files.single.path!;
                //       });
                //       await sendToApi();
                //     } else {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(content: Text("No file selected")),
                //       );
                //     }
                //   },
                //   child: const Text("Upload MP3"),
                // ),
                TextButton(
                  onPressed: () async {
                    if (_isRecording) {
                      // await _recorder.stop();
                      setState(() => _isRecording = false);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
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
      debugPrint("Error sharing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String audioPath = widget.dua.littleKidsAudio;
    bool isPlaying = widget.currentlyPlayingPath == audioPath;
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
                                isPlaying
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
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: rblack,
                          fontSize: themeController.textSize,
                        ),
                      ).marginAll(15),
                    Divider(height: 2, color: rwhite),
                    if (themeController.showTranslation)
                      Row(
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
                                  if (widget.dua.urduTranslation != null ||
                                      widget.dua.urduTranslation != "") {
                                    return widget.onToggle(
                                      widget.dua.urduTranslation!,
                                      widget.dua.id,
                                    );
                                  }
                                } else {
                                  if (widget.dua.englishTranslation != null ||
                                      widget.dua.englishTranslation != "") {
                                    return widget.onToggle(
                                      widget.dua.englishTranslation!,
                                      widget.dua.id,
                                    );
                                  }
                                }
                              },
                              child: Icon(
                                isPlaying
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
                      ).marginAll(15),
                    if (widget.dua.arabic.length < 200)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(),
                          InkWell(
                            onTap: () {
                              showShareDialog();
                            },
                            child: Icon(Icons.share, color: Color(0xff2A158F)),
                          ),
                        ],
                      ).marginSymmetric(horizontal: 20, vertical: 10),
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
