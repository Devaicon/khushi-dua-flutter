import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/models/subCategoryModel.dart';

import '../constants/colors.dart';
import 'openDuasScreen.dart';

class ImageScreen extends StatefulWidget {
  final SubCategoryModel subCategoryModel;
  const ImageScreen({super.key, required this.subCategoryModel});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Image.network(
              widget.subCategoryModel.image,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            bottom: 10,
            right: 12,
            left: 12,
            child: InkWell(
              onTap: () {
                Get.to(OpenDuasScreen(widget.subCategoryModel));
              },
              child: Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: rpink,
                ),
                child: Text(
                  "Go to Dua",
                  style: TextStyle(color: rwhite),
                ).marginSymmetric(vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
