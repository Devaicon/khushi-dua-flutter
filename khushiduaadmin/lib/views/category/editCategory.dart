import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/constants/firebaseRef.dart';
import 'package:khushiduaadmin/models/categoryModel.dart';

import '../../constants/colors.dart';
import '../../controllers/categoryController.dart';
import '../../widgets/customLoading.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/topBar.dart';
import 'allSubCategories.dart';

class EditCategory extends StatefulWidget {
  final CategoryModel model;

  const EditCategory({super.key, required this.model});

  @override
  State<EditCategory> createState() => _EditCategoryState();
}

class _EditCategoryState extends State<EditCategory> {
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

  @override
  void initState() {
    super.initState();
    arabicTextEditingController.text = widget.model.arabic;
    bengaliTextEditingController.text = widget.model.bengali;
    englishTextEditingController.text = widget.model.english;
    frenchTextEditingController.text = widget.model.french;
    germanTextEditingController.text = widget.model.german;
    gujratiTextEditingController.text = widget.model.gujrati;
    hindiTextEditingController.text = widget.model.hindi;
    indonesianTextEditingController.text = widget.model.indonesian;
    japaneseTextEditingController.text = widget.model.japanese;
    malayTextEditingController.text = widget.model.malay;
    mandrainTextEditingController.text = widget.model.mandrain;
    marathiTextEditingController.text = widget.model.marathi;
    portugeseTextEditingController.text = widget.model.portugese;
    punjabiTextEditingController.text = widget.model.punjabi;
    russianTextEditingController.text = widget.model.russian;
    sindhiTextEditingController.text = widget.model.sindhi;
    spanishTextEditingController.text = widget.model.spanish;
    tamilTextEditingController.text = widget.model.tamil;
    telguTextEditingController.text = widget.model.telgu;
    turkishTextEditingController.text = widget.model.turkish;
    urduTextEditingController.text = widget.model.urdu;
    setState(() {
      isLittleKids = widget.model.littleKids;
      isOlderKids = widget.model.olderKids;
      isGrownUps = widget.model.grownUps;
    });
  }

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
                      "Edit Category",
                      style: TextStyle(color: rWhite, fontSize: 20),
                    ).marginOnly(top: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => Get.back(),
                              child: const Text(
                                "category / ",
                                style: TextStyle(color: rGreen),
                              ),
                            ),
                            const Text(
                              "edit category",
                              style: TextStyle(color: rWhite),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                categoryRef.doc(widget.model.id).update(
                                    {"isEnabled": !widget.model.isEnabled});
                                setState(() {
                                  widget.model.isEnabled =
                                      !widget.model.isEnabled;
                                });
                                if (widget.model.isEnabled == false) {
                                  Get.back();
                                  CustomSnackbar.show("Success",
                                      "Category disabled successfully");
                                } else {
                                  CustomSnackbar.show(
                                      "Success", "Category enabled");
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: widget.model.isEnabled != true
                                      ? rGreen
                                      : rRed,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  widget.model.isEnabled == true
                                      ? 'Disable'
                                      : "Enable",
                                  style: const TextStyle(color: rWhite),
                                ).marginSymmetric(horizontal: 24, vertical: 8),
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            InkWell(
                              onTap: () {
                                Get.to(
                                    AllSubCategories(
                                      categoryModel: widget.model,
                                    ),
                                    transition: Transition.leftToRight);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: rHint,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Subcategories',
                                  style: TextStyle(color: rWhite),
                                ).marginSymmetric(horizontal: 24, vertical: 8),
                              ),
                            ),
                          ],
                        )
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
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.1,
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
                                                  child: catLogoUrl == null
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
                                                              widget.model.logo,
                                                              fit: BoxFit.fill,
                                                              width: 40,
                                                              height: 40,
                                                            ),
                                                          ),
                                                        ).marginOnly(top: 20)
                                                      : SizedBox(
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
                                                        ).marginOnly(top: 20),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.05,
                                            ),
                                            const Column(
                                              children: [],
                                            )
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
                                    CategoryModel categoryModel = CategoryModel(
                                        id: widget.model.id,
                                        createdAt: widget.model.createdAt,
                                        arabic:
                                            arabicTextEditingController.text,
                                        bengali:
                                            bengaliTextEditingController.text,
                                        english:
                                            englishTextEditingController.text,
                                        french:
                                            frenchTextEditingController.text,
                                        german:
                                            germanTextEditingController.text,
                                        gujrati:
                                            gujratiTextEditingController.text,
                                        hindi: hindiTextEditingController.text,
                                        indonesian:
                                            indonesianTextEditingController
                                                .text,
                                        isEnabled: widget.model.isEnabled,
                                        japanese:
                                            japaneseTextEditingController.text,
                                        logo: widget.model.logo,
                                        malay: malayTextEditingController.text,
                                        mandrain:
                                            mandrainTextEditingController.text,
                                        marathi:
                                            marathiTextEditingController.text,
                                        portugese:
                                            portugeseTextEditingController.text,
                                        punjabi:
                                            punjabiTextEditingController.text,
                                        russian:
                                            russianTextEditingController.text,
                                        sindhi:
                                            sindhiTextEditingController.text,
                                        spanish:
                                            spanishTextEditingController.text,
                                        tamil: tamilTextEditingController.text,
                                        telgu: telguTextEditingController.text,
                                        turkish:
                                            turkishTextEditingController.text,
                                        updatedAt: DateTime.now(),
                                        urdu: urduTextEditingController.text,
                                        order: widget.model.order,
                                        grownUps: isGrownUps,
                                        littleKids: isLittleKids,
                                        olderKids: isOlderKids);

                                    categoryController.updateCategory(
                                        categoryModel, catLogo);
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
                                    "Update",
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
