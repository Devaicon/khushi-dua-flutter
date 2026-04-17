import 'dart:html' as html;

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/constants/colors.dart';
import 'package:khushiduaadmin/controllers/categoryController.dart';
import 'package:khushiduaadmin/models/categoryModel.dart';
import 'package:khushiduaadmin/widgets/topBar.dart';

import '../../widgets/customLoading.dart';
import '../../widgets/customSnackbar.dart';

class CreateNewCategory extends StatefulWidget {
  const CreateNewCategory({super.key});

  @override
  State<CreateNewCategory> createState() => _CreateNewCategoryState();
}

class _CreateNewCategoryState extends State<CreateNewCategory> {
  html.File? catLogo;
  String? catLogoUrl;

  // html.File? catImage;
  // String? catImageUrl;

  var formKey = GlobalKey<FormState>();
  TextEditingController arabicTextEditingController = TextEditingController();
  TextEditingController bengaliTextEditingController = TextEditingController();
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
  bool isLittleKids = true;
  bool isOlderKids = true;
  bool isGrownUps = true;

  void pickImage(String type) {
    final html.FileUploadInputElement input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      if (input.files!.isNotEmpty) {
        final file = input.files!.first;
        final objectUrl = html.Url.createObjectUrl(file);

        setState(() {
          if (type == "logo") {
            catLogo = file;
            catLogoUrl = objectUrl;
          } else {
            // catImage = file;
            // catImageUrl = objectUrl;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: GetBuilder<CategoryController>(
        builder: (categoryController) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TopBar(title: "Category"),
                    const Text(
                      "Add New Category",
                      style: TextStyle(color: rWhite, fontSize: 20),
                    ).marginOnly(top: 20),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Get.back(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_ios,
                                  color: rGreen, size: 14),
                              Text(
                                "category / ",
                                style: TextStyle(color: rGreen),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          "add new category",
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Row(
                                          children: [
                                            Column(
                                              children: [
                                                const Text(
                                                  "Logo",
                                                  style:
                                                      TextStyle(color: rHint),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    pickImage("logo");
                                                  },
                                                  child: catLogo != null
                                                      ? SizedBox(
                                                          width: 60,
                                                          height: 60,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            child:
                                                                Image.network(
                                                              catLogoUrl!,
                                                              fit: BoxFit.fill,
                                                              width: 40,
                                                              height: 40,
                                                            ),
                                                          ),
                                                        ).marginOnly(top: 20)
                                                      : DottedBorder(
                                                          color: rHint,
                                                          radius: const Radius
                                                              .circular(8),
                                                          borderType:
                                                              BorderType.Circle,
                                                          dashPattern: const [
                                                            8,
                                                            4
                                                          ],
                                                          child: Container(
                                                            width: 60,
                                                            height: 60,
                                                            alignment: Alignment
                                                                .center,
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                SvgPicture.asset(
                                                                    "assets/svgs/upload.svg"),
                                                              ],
                                                            ),
                                                          )).marginOnly(top: 20),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.05,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (English)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller:
                                            englishTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "English name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in English',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (Arabic)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller: arabicTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "Arabic name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in Arabic',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (Bengali)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller:
                                            bengaliTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "Bengali name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in Bengali',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (French)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller: frenchTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "French name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in French',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (German)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller: germanTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "German name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in German',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (Gujrati)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller:
                                            gujratiTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "Gujrati name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in Gujrati',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (Hindi)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller: hindiTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "Hindi name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in Hindi',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (Indonesian)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller:
                                            indonesianTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "Indonesian name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in Indonesian',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (Japanese)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller:
                                            japaneseTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "Japanese name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in Japanese',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (Malay)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller: malayTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "Malay name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in Malay',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        "Category Name (Mandrain)",
                                        style: TextStyle(color: rHint),
                                      ).marginOnly(top: 20),
                                      TextFormField(
                                        cursorColor: rGreen,
                                        controller:
                                            mandrainTextEditingController,
                                        validator: (diameter) {
                                          if (diameter == null ||
                                              diameter.isEmpty) {
                                            return "Mandrain name is required";
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hintText: 'Name in Mandrain',
                                          hintStyle: TextStyle(
                                            color: rHint.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: rHint,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                              const Text(
                                                "Little Kids",
                                                style: TextStyle(color: rWhite),
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
                                              const Text(
                                                "Older Kids",
                                                style: TextStyle(color: rWhite),
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
                                              const Text(
                                                "Grown Ups",
                                                style: TextStyle(color: rWhite),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ).marginOnly(top: 20)
                                    ],
                                  ).marginSymmetric(horizontal: 12),
                                ),

                                //right side
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Category Name (Marathi)",
                                      style: TextStyle(color: rHint),
                                    ).marginOnly(top: 20),
                                    TextFormField(
                                      cursorColor: rGreen,
                                      controller: marathiTextEditingController,
                                      validator: (diameter) {
                                        if (diameter == null ||
                                            diameter.isEmpty) {
                                          return "Marathi name is required";
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
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Category Name (Portugese)",
                                      style: TextStyle(color: rHint),
                                    ).marginOnly(top: 20),
                                    TextFormField(
                                      cursorColor: rGreen,
                                      controller:
                                          portugeseTextEditingController,
                                      validator: (diameter) {
                                        if (diameter == null ||
                                            diameter.isEmpty) {
                                          return "Portugese name is required";
                                        } else {
                                          return null;
                                        }
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        hintText: 'Name in Portugese',
                                        hintStyle: TextStyle(
                                          color: rHint.withOpacity(0.5),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Category Name (Punjabi)",
                                      style: TextStyle(color: rHint),
                                    ).marginOnly(top: 20),
                                    TextFormField(
                                      cursorColor: rGreen,
                                      controller: punjabiTextEditingController,
                                      validator: (diameter) {
                                        if (diameter == null ||
                                            diameter.isEmpty) {
                                          return "Punjabi name is required";
                                        } else {
                                          return null;
                                        }
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        hintText: 'Name in Punjabi',
                                        hintStyle: TextStyle(
                                          color: rHint.withOpacity(0.5),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Category Name (Russian)",
                                      style: TextStyle(color: rHint),
                                    ).marginOnly(top: 20),
                                    TextFormField(
                                      cursorColor: rGreen,
                                      controller: russianTextEditingController,
                                      validator: (diameter) {
                                        if (diameter == null ||
                                            diameter.isEmpty) {
                                          return "Russian name is required";
                                        } else {
                                          return null;
                                        }
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        hintText: 'Name in Russian',
                                        hintStyle: TextStyle(
                                          color: rHint.withOpacity(0.5),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Category Name (Sindhi)",
                                      style: TextStyle(color: rHint),
                                    ).marginOnly(top: 20),
                                    TextFormField(
                                      cursorColor: rGreen,
                                      controller: sindhiTextEditingController,
                                      validator: (diameter) {
                                        if (diameter == null ||
                                            diameter.isEmpty) {
                                          return "Sindhi name is required";
                                        } else {
                                          return null;
                                        }
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        hintText: 'Name in Sindhi',
                                        hintStyle: TextStyle(
                                          color: rHint.withOpacity(0.5),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Category Name (Spanish)",
                                      style: TextStyle(color: rHint),
                                    ).marginOnly(top: 20),
                                    TextFormField(
                                      cursorColor: rGreen,
                                      controller: spanishTextEditingController,
                                      validator: (diameter) {
                                        if (diameter == null ||
                                            diameter.isEmpty) {
                                          return "Spanish name is required";
                                        } else {
                                          return null;
                                        }
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        hintText: 'Name in Spanish',
                                        hintStyle: TextStyle(
                                          color: rHint.withOpacity(0.5),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Category Name (Tamil)",
                                      style: TextStyle(color: rHint),
                                    ).marginOnly(top: 20),
                                    TextFormField(
                                      cursorColor: rGreen,
                                      controller: tamilTextEditingController,
                                      validator: (diameter) {
                                        if (diameter == null ||
                                            diameter.isEmpty) {
                                          return "Tamil name is required";
                                        } else {
                                          return null;
                                        }
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        hintText: 'Name in Tamil',
                                        hintStyle: TextStyle(
                                          color: rHint.withOpacity(0.5),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Category Name (Telgu)",
                                      style: TextStyle(color: rHint),
                                    ).marginOnly(top: 20),
                                    TextFormField(
                                      cursorColor: rGreen,
                                      controller: telguTextEditingController,
                                      validator: (diameter) {
                                        if (diameter == null ||
                                            diameter.isEmpty) {
                                          return "Telgu name is required";
                                        } else {
                                          return null;
                                        }
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        hintText: 'Name in Telgu',
                                        hintStyle: TextStyle(
                                          color: rHint.withOpacity(0.5),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Category Name (Turkish)",
                                      style: TextStyle(color: rHint),
                                    ).marginOnly(top: 20),
                                    TextFormField(
                                      cursorColor: rGreen,
                                      controller: turkishTextEditingController,
                                      validator: (diameter) {
                                        if (diameter == null ||
                                            diameter.isEmpty) {
                                          return "Turkish name is required";
                                        } else {
                                          return null;
                                        }
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        hintText: 'Name in Turkish',
                                        hintStyle: TextStyle(
                                          color: rHint.withOpacity(0.5),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Category Name (Urdu)",
                                      style: TextStyle(color: rHint),
                                    ).marginOnly(top: 20),
                                    TextFormField(
                                      cursorColor: rGreen,
                                      controller: urduTextEditingController,
                                      validator: (diameter) {
                                        if (diameter == null ||
                                            diameter.isEmpty) {
                                          return "Urdu name is required";
                                        } else {
                                          return null;
                                        }
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        hintText: 'Name in Urdu',
                                        hintStyle: TextStyle(
                                          color: rHint.withOpacity(0.5),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: rHint,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      style: const TextStyle(
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
                                    if (catLogo == null) {
                                      CustomSnackbar.show(
                                          "Error", "Category logo is required",
                                          isSuccess: false);
                                    }
                                    // else if (catImage == null) {
                                    //   CustomSnackbar.show("Error", "Category image is required", isSuccess: false);
                                    // }
                                    else {
                                      CategoryModel categoryModel =
                                          CategoryModel(
                                              id: "",
                                              createdAt: DateTime.now(),
                                              // image: "",
                                              arabic: arabicTextEditingController
                                                  .text,
                                              bengali: bengaliTextEditingController
                                                  .text,
                                              english: englishTextEditingController
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
                                              logo: "",
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
                                                  russianTextEditingController
                                                      .text,
                                              sindhi: sindhiTextEditingController
                                                  .text,
                                              spanish:
                                                  spanishTextEditingController
                                                      .text,
                                              tamil: tamilTextEditingController
                                                  .text,
                                              telgu: telguTextEditingController
                                                  .text,
                                              turkish:
                                                  turkishTextEditingController
                                                      .text,
                                              updatedAt: DateTime.now(),
                                              urdu: urduTextEditingController
                                                  .text,
                                              order: categoryController
                                                      .allCategories.length +
                                                  1,
                                              grownUps: isGrownUps,
                                              littleKids: isLittleKids,
                                              olderKids: isOlderKids);

                                      categoryController.createCategory(
                                          categoryModel, catLogo!);
                                    }
                                  } else {
                                    return;
                                  }
                                },
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.1,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: rGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
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
                  visible: categoryController.isLoading,
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      color: rWhite.withOpacity(0.2),
                      child: const CustomLoading()))
            ],
          );
        },
      ),
    );
  }
}
