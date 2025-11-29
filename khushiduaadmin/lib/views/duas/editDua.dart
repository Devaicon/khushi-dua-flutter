import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'dart:html' as html;

import '../../constants/colors.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/duaController.dart';
import '../../models/duaModel.dart';
import '../../models/subCategoryModel.dart';
import '../../widgets/customDropDown.dart';
import '../../widgets/customLoading.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/topBar.dart';

class EditDua extends StatefulWidget {
  DuaModel duaModel;
  EditDua({super.key, required this.duaModel});

  @override
  State<EditDua> createState() => _EditDuaState();
}

class _EditDuaState extends State<EditDua> {
  var formKey = GlobalKey<FormState>();
  TextEditingController arabicTextEditingController = TextEditingController();
  TextEditingController bengaliTextEditingController = TextEditingController();
  TextEditingController transliterationTextEditingController =
      TextEditingController();
  TextEditingController englishTextEditingController = TextEditingController();
  TextEditingController frenchTextEditingController = TextEditingController();
  TextEditingController germanTextEditingController = TextEditingController();
  TextEditingController gujratiTextEditingController = TextEditingController();
  TextEditingController hindiTextEditingController = TextEditingController();
  TextEditingController indonesianTextEditingController =
      TextEditingController();
  TextEditingController japaneseTextEditingController = TextEditingController();
  TextEditingController malayTextEditingController = TextEditingController();
  TextEditingController mandrainTextEditingController = TextEditingController();
  TextEditingController marathiTextEditingController = TextEditingController();
  TextEditingController portugeseTextEditingController =
      TextEditingController();
  TextEditingController punjabiTextEditingController = TextEditingController();
  TextEditingController russianTextEditingController = TextEditingController();
  TextEditingController sindhiTextEditingController = TextEditingController();
  TextEditingController spanishTextEditingController = TextEditingController();
  TextEditingController tamilTextEditingController = TextEditingController();
  TextEditingController telguTextEditingController = TextEditingController();
  TextEditingController turkishTextEditingController = TextEditingController();
  TextEditingController urduTextEditingController = TextEditingController();
  TextEditingController descriptionTextEditingController =
      TextEditingController();
  bool isLittleKids = true;
  bool isOlderKids = true;
  bool isGrownUps = true;

  html.File? littleKidmp3File;
  html.File? olderKidmp3File;
  html.File? grownUpmp3File;
  html.File? englishmp3File;
  html.File? urdump3File;

  String littleKidsAudio = "";
  String olderKidsAudio = "";
  String grownUpsKidsAudio = "";
  String englishTranslationAudio = "";
  String urduTranslationAudio = "";

  List<SubCategoryModel> selectedSubCategories = [];
  TextEditingController benefitsTextAreaController = TextEditingController();

  // Helper function to get category name from categoryId
  String getCategoryName(
      String categoryId, CategoryController categoryController) {
    try {
      final category = categoryController.allCategories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => categoryController.allCategories.first,
      );
      return category.english.isNotEmpty ? category.english : category.arabic;
    } catch (e) {
      return "Unknown Category";
    }
  }

  @override
  void initState() {
    arabicTextEditingController.text = widget.duaModel.arabic;
    bengaliTextEditingController.text = widget.duaModel.bengali;
    transliterationTextEditingController.text = widget.duaModel.transliteration;
    englishTextEditingController.text = widget.duaModel.english;
    frenchTextEditingController.text = widget.duaModel.french;
    germanTextEditingController.text = widget.duaModel.german;
    gujratiTextEditingController.text = widget.duaModel.gujrati;
    hindiTextEditingController.text = widget.duaModel.hindi;
    indonesianTextEditingController.text = widget.duaModel.indonesian;
    japaneseTextEditingController.text = widget.duaModel.japanese;
    malayTextEditingController.text = widget.duaModel.malay;
    mandrainTextEditingController.text = widget.duaModel.mandrain;
    marathiTextEditingController.text = widget.duaModel.marathi;
    portugeseTextEditingController.text = widget.duaModel.portugese;
    punjabiTextEditingController.text = widget.duaModel.punjabi;
    russianTextEditingController.text = widget.duaModel.russian;
    sindhiTextEditingController.text = widget.duaModel.sindhi;
    spanishTextEditingController.text = widget.duaModel.spanish;
    tamilTextEditingController.text = widget.duaModel.tamil;
    telguTextEditingController.text = widget.duaModel.telgu;
    turkishTextEditingController.text = widget.duaModel.turkish;
    urduTextEditingController.text = widget.duaModel.urdu;
    descriptionTextEditingController.text = widget.duaModel.description ?? '';
    littleKidsAudio = widget.duaModel.littleKidsAudio;
    olderKidsAudio = widget.duaModel.olderKidsAudio;
    grownUpsKidsAudio = widget.duaModel.grownUpsAudio;

    isLittleKids = widget.duaModel.littleKids;
    isOlderKids = widget.duaModel.olderKids;
    isGrownUps = widget.duaModel.grownUps;

    selectedSubCategories = Get.find<CategoryController>()
        .allSubCategories
        .where((subCat) => widget.duaModel.subCategoryIds.contains(subCat.id))
        .toList();

    // Initialize benefits text area with saved data
    benefitsTextAreaController.text = widget.duaModel.benefits ?? '';

    setState(() {});
  }

  void pickMp3File(String type) {
    final html.FileUploadInputElement input = html.FileUploadInputElement();
    input.accept = 'audio/mp3';
    input.click();

    input.onChange.listen((event) {
      if (input.files!.isNotEmpty) {
        if (type == "littleKid") {
          littleKidmp3File = input.files!.first;
          setState(() {
            littleKidmp3File;
          });
        } else if (type == "olderKid") {
          olderKidmp3File = input.files!.first;
          setState(() {
            olderKidmp3File;
          });
        } else if (type == "englishTranslation") {
          englishmp3File = input.files!.first;
          setState(() {
            englishmp3File;
          });
        } else if (type == "urduTranslation") {
          urdump3File = input.files!.first;
          setState(() {
            urdump3File;
          });
        } else {
          grownUpmp3File = input.files!.first;
          setState(() {
            grownUpmp3File;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: GetBuilder<CategoryController>(
        builder: (categoryController) {
          return GetBuilder<DuaController>(
            builder: (duaController) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TopBar(title: "Dua"),
                        Text(
                          "Edit Dua",
                          style: TextStyle(color: rWhite, fontSize: 20),
                        ).marginOnly(top: 20),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Get.back(),
                              child: Text(
                                "dua / ",
                                style: TextStyle(color: rGreen),
                              ),
                            ),
                            Text(
                              "edit dua",
                              style: TextStyle(color: rWhite),
                            ),
                          ],
                        ),
                        Form(
                          key: formKey,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: rBg,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    //left side
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Dua (English)",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  englishTextEditingController,
                                              validator: (diameter) {
                                                if (diameter == null ||
                                                    diameter.isEmpty) {
                                                  return "English dua is required";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText: 'Dua in English',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),

                                            Text(
                                              "Dua (Transliteration)(English)",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  transliterationTextEditingController,
                                              validator: (diameter) {
                                                if (diameter == null ||
                                                    diameter.isEmpty) {
                                                  return "Transliteration is required";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText:
                                                    'Transliteration in English',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),

                                            Text(
                                              "Description",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  descriptionTextEditingController,
                                              maxLines: 4,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText:
                                                    'Enter description (optional)',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),

                                            Text(
                                              "Benefits",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  benefitsTextAreaController,
                                              maxLines: 4,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText:
                                                    'Enter benefits (optional)',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),

                                            Text(
                                              "Dua (Arabic)",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  arabicTextEditingController,
                                              validator: (diameter) {
                                                if (diameter == null ||
                                                    diameter.isEmpty) {
                                                  return "Arabic dua is required";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText: 'Dua in Arabic',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "Dua (Bengali)",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  bengaliTextEditingController,
                                              validator: (diameter) {
                                                if (diameter == null ||
                                                    diameter.isEmpty) {
                                                  return "Bengali dua is required";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText: 'Dua in Bengali',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "Dua (French)",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  frenchTextEditingController,
                                              validator: (diameter) {
                                                if (diameter == null ||
                                                    diameter.isEmpty) {
                                                  return "French dua is required";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText: 'Dua in French',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "Dua (German)",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  germanTextEditingController,
                                              validator: (diameter) {
                                                if (diameter == null ||
                                                    diameter.isEmpty) {
                                                  return "German dua is required";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText: 'Dua in German',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "Dua (Gujrati)",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  gujratiTextEditingController,
                                              validator: (diameter) {
                                                if (diameter == null ||
                                                    diameter.isEmpty) {
                                                  return "Gujrati dua is required";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText: 'Dua in Gujrati',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "Dua (Hindi)",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  hindiTextEditingController,
                                              validator: (diameter) {
                                                if (diameter == null ||
                                                    diameter.isEmpty) {
                                                  return "Hindi dua is required";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText: 'Dua in Hindi',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "Dua (Indonesian)",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),
                                            TextFormField(
                                              cursorColor: rGreen,
                                              controller:
                                                  indonesianTextEditingController,
                                              validator: (diameter) {
                                                if (diameter == null ||
                                                    diameter.isEmpty) {
                                                  return "Indonesian dua is required";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                hintText: 'Dua in Indonesian',
                                                hintStyle: TextStyle(
                                                  color: rHint.withOpacity(0.5),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: rHint,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 16.0,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),

                                            Text(
                                              "Sub Categories",
                                              style: TextStyle(color: rHint),
                                            ).marginOnly(top: 20),

                                            // Display selected subcategories with their main categories
                                            if (selectedSubCategories
                                                .isNotEmpty)
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: rBg,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: rGreen
                                                          .withOpacity(0.3)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Selected Subcategories:",
                                                      style: TextStyle(
                                                        color: rGreen,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    ...selectedSubCategories
                                                        .map((subCat) {
                                                      final categoryName =
                                                          getCategoryName(
                                                              subCat.categoryId,
                                                              categoryController);
                                                      return Container(
                                                        margin: EdgeInsets.only(
                                                            bottom: 8),
                                                        padding:
                                                            EdgeInsets.all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: rBlack,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                              color: rHint
                                                                  .withOpacity(
                                                                      0.3)),
                                                        ),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Icon(
                                                              Icons.category,
                                                              color: rGreen,
                                                              size: 16,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    "Main Category: $categoryName",
                                                                    style:
                                                                        TextStyle(
                                                                      color:
                                                                          rGreen,
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      height:
                                                                          4),
                                                                  Text(
                                                                    "Subcategory: ${subCat.english.isNotEmpty ? subCat.english : subCat.arabic}",
                                                                    style:
                                                                        TextStyle(
                                                                      color:
                                                                          rWhite,
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ],
                                                ),
                                              ).marginOnly(bottom: 12),

                                            SearchableMultiSelectDropdown(
                                              items: categoryController
                                                  .allSubCategories,
                                              initiallySelected:
                                                  selectedSubCategories,
                                              onChanged: (list) => setState(
                                                  () => selectedSubCategories =
                                                      list),
                                            ),

                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Little kid audio",
                                                  style:
                                                      TextStyle(color: rHint),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    pickMp3File("littleKid");
                                                  },
                                                  child: DottedBorder(
                                                      color: rHint,
                                                      radius:
                                                          Radius.circular(8),
                                                      borderType:
                                                          BorderType.RRect,
                                                      dashPattern: [8, 4],
                                                      child: Container(
                                                        // width: 60,
                                                        height: 100,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            littleKidmp3File ==
                                                                    null
                                                                ? SvgPicture.asset(
                                                                    "assets/svgs/upload.svg")
                                                                : Icon(
                                                                    Icons
                                                                        .file_copy_outlined,
                                                                    color:
                                                                        rHint,
                                                                  ),
                                                            Text(
                                                              littleKidmp3File ==
                                                                      null
                                                                  ? "Upload Audio Sound"
                                                                  : "${littleKidmp3File!.name}",
                                                              style: TextStyle(
                                                                  color: rHint,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 14),
                                                            ),
                                                          ],
                                                        ),
                                                      )),
                                                ),
                                              ],
                                            ).marginOnly(top: 20),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Older kid audio",
                                                  style:
                                                      TextStyle(color: rHint),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    pickMp3File("olderKid");
                                                  },
                                                  child: DottedBorder(
                                                      color: rHint,
                                                      radius:
                                                          Radius.circular(8),
                                                      borderType:
                                                          BorderType.RRect,
                                                      dashPattern: [8, 4],
                                                      child: Container(
                                                        // width: 60,
                                                        height: 100,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            olderKidmp3File ==
                                                                    null
                                                                ? SvgPicture.asset(
                                                                    "assets/svgs/upload.svg")
                                                                : Icon(
                                                                    Icons
                                                                        .file_copy_outlined,
                                                                    color:
                                                                        rHint,
                                                                  ),
                                                            Text(
                                                              olderKidmp3File ==
                                                                      null
                                                                  ? "Upload Audio Sound"
                                                                  : "${olderKidmp3File!.name}",
                                                              style: TextStyle(
                                                                  color: rHint,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 14),
                                                            ),
                                                          ],
                                                        ),
                                                      )),
                                                ),
                                              ],
                                            ).marginOnly(top: 20),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Grown up audio",
                                                  style:
                                                      TextStyle(color: rHint),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    pickMp3File("grownUp");
                                                  },
                                                  child: DottedBorder(
                                                      color: rHint,
                                                      radius:
                                                          Radius.circular(8),
                                                      borderType:
                                                          BorderType.RRect,
                                                      dashPattern: [8, 4],
                                                      child: Container(
                                                        // width: 60,
                                                        height: 100,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            grownUpmp3File ==
                                                                    null
                                                                ? SvgPicture.asset(
                                                                    "assets/svgs/upload.svg")
                                                                : Icon(
                                                                    Icons
                                                                        .file_copy_outlined,
                                                                    color:
                                                                        rHint,
                                                                  ),
                                                            Text(
                                                              grownUpmp3File ==
                                                                      null
                                                                  ? "Upload Audio Sound"
                                                                  : "${grownUpmp3File!.name}",
                                                              style: TextStyle(
                                                                  color: rHint,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 14),
                                                            ),
                                                          ],
                                                        ),
                                                      )),
                                                ),
                                              ],
                                            ).marginOnly(top: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Checkbox(
                                                      value: isLittleKids,
                                                      activeColor: rGreen,
                                                      checkColor: Colors.white,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          isLittleKids = val!;
                                                        });
                                                      },
                                                    ),
                                                    Text(
                                                      "Little Kids",
                                                      style: TextStyle(
                                                          color: rWhite),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Checkbox(
                                                      value: isOlderKids,
                                                      activeColor: rGreen,
                                                      checkColor: Colors.white,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          isOlderKids = val!;
                                                        });
                                                      },
                                                    ),
                                                    Text(
                                                      "Older Kids",
                                                      style: TextStyle(
                                                          color: rWhite),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Checkbox(
                                                      value: isGrownUps,
                                                      activeColor: rGreen,
                                                      checkColor: Colors.white,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          isGrownUps = val!;
                                                        });
                                                      },
                                                    ),
                                                    Text(
                                                      "Grown Ups",
                                                      style: TextStyle(
                                                          color: rWhite),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ).marginOnly(top: 20),
                                          ],
                                        ).marginSymmetric(horizontal: 12),
                                      ),
                                    ),

                                    //right side
                                    Expanded(
                                        child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "English Translation",
                                              style: TextStyle(color: rHint),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                pickMp3File(
                                                    "englishTranslation");
                                              },
                                              child: DottedBorder(
                                                  color: rHint,
                                                  radius: Radius.circular(8),
                                                  borderType: BorderType.RRect,
                                                  dashPattern: [8, 4],
                                                  child: Container(
                                                    // width: 60,
                                                    height: 100,
                                                    alignment: Alignment.center,
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        englishmp3File == null
                                                            ? SvgPicture.asset(
                                                                "assets/svgs/upload.svg")
                                                            : Icon(
                                                                Icons
                                                                    .file_copy_outlined,
                                                                color: rHint,
                                                              ),
                                                        Text(
                                                          englishmp3File == null
                                                              ? "Upload Audio Sound"
                                                              : "${englishmp3File!.name}",
                                                          style: TextStyle(
                                                              color: rHint,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14),
                                                        ),
                                                      ],
                                                    ),
                                                  )),
                                            ),
                                          ],
                                        ).marginOnly(top: 20),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Urdu Translation",
                                              style: TextStyle(color: rHint),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                pickMp3File("urduTranslation");
                                              },
                                              child: DottedBorder(
                                                  color: rHint,
                                                  radius: Radius.circular(8),
                                                  borderType: BorderType.RRect,
                                                  dashPattern: [8, 4],
                                                  child: Container(
                                                    // width: 60,
                                                    height: 100,
                                                    alignment: Alignment.center,
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        urdump3File == null
                                                            ? SvgPicture.asset(
                                                                "assets/svgs/upload.svg")
                                                            : Icon(
                                                                Icons
                                                                    .file_copy_outlined,
                                                                color: rHint,
                                                              ),
                                                        Text(
                                                          urdump3File == null
                                                              ? "Upload Audio Sound"
                                                              : "${urdump3File!.name}",
                                                          style: TextStyle(
                                                              color: rHint,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14),
                                                        ),
                                                      ],
                                                    ),
                                                  )),
                                            ),
                                          ],
                                        ).marginOnly(top: 20),
                                        Text(
                                          "Dua (Japanese)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              japaneseTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Japanese dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Japanese',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Malay)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              malayTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Malay dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Malay',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Mandrain)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              mandrainTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Mandrain dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Mandrain',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Marathi)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              marathiTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Marathi dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Name in Marathi',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Portugese)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              portugeseTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Portugese dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Portugese',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Punjabi)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              punjabiTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Punjabi dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Punjabi',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Russian)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              russianTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Russian dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Russian',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Sindhi)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              sindhiTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Sindhi dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Sindhi',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Spanish)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              spanishTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Spanish dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Spanish',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Tamil)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              tamilTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Tamil dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Tamil',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Telgu)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              telguTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Telgu dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Telgu',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Turkish)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller:
                                              turkishTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Turkish dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Turkish',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Dua (Urdu)",
                                          style: TextStyle(color: rHint),
                                        ).marginOnly(top: 20),
                                        TextFormField(
                                          cursorColor: rGreen,
                                          controller: urduTextEditingController,
                                          validator: (diameter) {
                                            if (diameter == null ||
                                                diameter.isEmpty) {
                                              return "Urdu dua is required";
                                            } else {
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            hintText: 'Dua in Urdu',
                                            hintStyle: TextStyle(
                                              color: rHint.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: rHint,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 16.0,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ).marginSymmetric(horizontal: 12)),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: () async {
                                      if (formKey.currentState!.validate()) {
                                        if (selectedSubCategories.isEmpty) {
                                          CustomSnackbar.show("Error",
                                              "Select atleast one sub category",
                                              isSuccess: false);
                                        } else {
                                          List<String> subIds = [];
                                          for (var item
                                              in selectedSubCategories) {
                                            subIds.add(item.id);
                                          }
                                          DuaModel duaModel = DuaModel(
                                              id: widget.duaModel.id,
                                              createdAt:
                                                  widget.duaModel.createdAt,
                                              arabic: arabicTextEditingController
                                                  .text,
                                              bengali:
                                                  bengaliTextEditingController
                                                      .text,
                                              transliteration:
                                                  transliterationTextEditingController
                                                      .text,
                                              english:
                                                  englishTextEditingController
                                                      .text,
                                              french: frenchTextEditingController
                                                  .text,
                                              german: germanTextEditingController
                                                  .text,
                                              gujrati:
                                                  gujratiTextEditingController
                                                      .text,
                                              hindi: hindiTextEditingController
                                                  .text,
                                              indonesian:
                                                  indonesianTextEditingController
                                                      .text,
                                              isEnabled: true,
                                              japanese:
                                                  japaneseTextEditingController
                                                      .text,
                                              malay: malayTextEditingController
                                                  .text,
                                              mandrain:
                                                  mandrainTextEditingController
                                                      .text,
                                              marathi:
                                                  marathiTextEditingController
                                                      .text,
                                              portugese:
                                                  portugeseTextEditingController
                                                      .text,
                                              punjabi:
                                                  punjabiTextEditingController
                                                      .text,
                                              russian:
                                                  russianTextEditingController.text,
                                              sindhi: sindhiTextEditingController.text,
                                              spanish: spanishTextEditingController.text,
                                              tamil: tamilTextEditingController.text,
                                              telgu: telguTextEditingController.text,
                                              turkish: turkishTextEditingController.text,
                                              updatedAt: DateTime.now(),
                                              urdu: urduTextEditingController.text,
                                              order: duaController.allDuas.length + 1,
                                              grownUps: isGrownUps,
                                              littleKids: isLittleKids,
                                              olderKids: isOlderKids,
                                              subCategoryIds: subIds,
                                              grownUpsAudio: widget.duaModel.grownUpsAudio,
                                              littleKidsAudio: widget.duaModel.littleKidsAudio,
                                              olderKidsAudio: widget.duaModel.olderKidsAudio,
                                              englishTranslation: widget.duaModel.englishTranslation,
                                              urduTranslation: widget.duaModel.urduTranslation,
                                              benefits: benefitsTextAreaController.text.trim().isEmpty ? null : benefitsTextAreaController.text.trim(),
                                              description: descriptionTextEditingController.text.isEmpty ? null : descriptionTextEditingController.text);

                                          duaController.updateDua(
                                              duaModel,
                                              grownUpmp3File,
                                              littleKidmp3File,
                                              olderKidmp3File,
                                              englishmp3File,
                                              urdump3File);
                                        }
                                      } else {
                                        return;
                                      }
                                    },
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.1,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: rGreen,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Add",
                                        style: TextStyle(color: rWhite),
                                      ).marginSymmetric(vertical: 12),
                                    ).marginOnly(top: 12),
                                  ),
                                )
                              ],
                            ).marginSymmetric(horizontal: 15, vertical: 15),
                          ).marginOnly(top: 12),
                        ),
                      ],
                    ).marginSymmetric(horizontal: 12, vertical: 12),
                  ),
                  Visibility(
                      visible: duaController.isLoading,
                      child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          color: rWhite.withOpacity(0.2),
                          child: CustomLoading()))
                ],
              );
            },
          );
        },
      ),
    );
  }
}
