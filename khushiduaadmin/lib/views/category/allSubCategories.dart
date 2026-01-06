import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/models/categoryModel.dart';
import 'package:khushiduaadmin/models/subCategoryModel.dart';

import '../../constants/colors.dart';
import '../../constants/firebaseRef.dart';
import '../../controllers/categoryController.dart';
import '../../widgets/topBar.dart';
import '../subCategory/editSubCategory.dart';
import 'createSubCategory.dart';

class AllSubCategories extends StatefulWidget {
  final CategoryModel categoryModel;
  const AllSubCategories({super.key, required this.categoryModel});

  @override
  State<AllSubCategories> createState() => _AllSubCategoriesState();
}

class _AllSubCategoriesState extends State<AllSubCategories> {
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  List<SubCategoryModel> allSubCategories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getSubCategories();
    });
  }

  void getSubCategories() async {
    try {
      final fetchedList = await Get.find<CategoryController>()
          .getSubCategories(widget.categoryModel);
      setState(() {
        allSubCategories = fetchedList;
      });
      debugPrint("Fetched ${allSubCategories.length} subcategories");
    } catch (e, stacktrace) {
      debugPrint("Failed to fetch subcategories: $e");
      debugPrint("Failed to fetch subcategories: $stacktrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: GetBuilder<CategoryController>(
        builder: (categoryController) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TopBar(title: widget.categoryModel.english),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Container(
                        height: 125,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: rBg),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                  color: Color(0xff955C00),
                                  shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: SvgPicture.asset("assets/svgs/coins.svg"),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(
                                      begin: 0, end: allSubCategories.length),
                                  duration: const Duration(seconds: 2),
                                  builder: (context, value, child) {
                                    return Text(
                                      _formatNumber(value),
                                      style: const TextStyle(
                                          color: rWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 30),
                                    );
                                  },
                                ),
                                const Text(
                                  "Total Sub Categories",
                                  style: TextStyle(
                                      color: rWhite,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16),
                                ),
                              ],
                            ).marginOnly(left: 12)
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Container(
                        height: 125,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: rBg),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                  color: Color(0xff883232),
                                  shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: SvgPicture.asset("assets/svgs/coins.svg"),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text("${coinController.allCoins.length??0}",style: TextStyle(color: rWhite,fontWeight: FontWeight.bold,fontSize: 30),),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(
                                      begin: 0,
                                      end: allSubCategories
                                          .where((element) =>
                                              element.isEnabled == false)
                                          .toList()
                                          .length),
                                  duration: const Duration(seconds: 1),
                                  builder: (context, value, child) {
                                    return Text(
                                      _formatNumber(value),
                                      style: const TextStyle(
                                          color: rWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 30),
                                    );
                                  },
                                ),
                                const Text(
                                  "Disabled Sub Categories",
                                  style: TextStyle(
                                      color: rWhite,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16),
                                ),
                              ],
                            ).marginOnly(left: 12)
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Container(
                        height: 125,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: rBg),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                  color: Color(0xff008A3F),
                                  shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: SvgPicture.asset("assets/svgs/coins.svg"),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text("3,450",style: TextStyle(color: rWhite,fontWeight: FontWeight.bold,fontSize: 30),),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(
                                      begin: 0,
                                      end: allSubCategories
                                          .where((element) =>
                                              element.isEnabled == true)
                                          .toList()
                                          .length),
                                  duration: const Duration(seconds: 1),
                                  builder: (context, value, child) {
                                    return Text(
                                      _formatNumber(value),
                                      style: const TextStyle(
                                          color: rWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 30),
                                    );
                                  },
                                ),
                                const Text(
                                  "Enabled Sub Categories",
                                  style: TextStyle(
                                      color: rWhite,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16),
                                ),
                              ],
                            ).marginOnly(left: 12)
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(child: Container())
                  ],
                ).marginOnly(top: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "All Sub Categories",
                      style: TextStyle(
                          color: rWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 20),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        Get.to(
                            CreateSubCategory(
                                widget.categoryModel, allSubCategories.length),
                            transition: Transition.upToDown);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: rGreen,
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            SvgPicture.asset("assets/svgs/add.svg"),
                            const Text(
                              "Create a Sub Category",
                              style: TextStyle(color: rWhite),
                            ).marginOnly(left: 8)
                          ],
                        ).marginAll(12),
                      ),
                    )
                  ],
                ).marginOnly(top: 12),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12), color: rBg),
                  child: Column(
                    children: [
                      TableHeader(),
                      Theme(
                        data: Theme.of(context).copyWith(
                          iconTheme: const IconThemeData(color: Colors.white),
                        ),
                        child: ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          onReorder: (oldIndex, newIndex) async {
                            if (newIndex > oldIndex) newIndex -= 1;

                            final movedSubCategory =
                                allSubCategories.removeAt(oldIndex);
                            allSubCategories.insert(newIndex, movedSubCategory);

                            for (int i = 0; i < allSubCategories.length; i++) {
                              final subCategory = allSubCategories[i];
                              await subCategoryRef
                                  .doc(subCategory.id)
                                  .update({"order": i});
                            }
                            setState(() {});
                          },
                          children: [
                            if (allSubCategories.isNotEmpty)
                              for (int index = 0;
                                  index < allSubCategories.length;
                                  index++)
                                SubCategoryTile(
                                  allSubCategories[index],
                                  key: ValueKey(allSubCategories[index].id),
                                ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ).marginSymmetric(horizontal: 12, vertical: 12),
          );
        },
      ),
    );
  }
}

Widget TableHeader() {
  return Container(
    decoration: BoxDecoration(
      color: rWhite.withOpacity(0.05),
    ),
    child: const Row(
      children: [
        Expanded(
            flex: 1,
            child: Text(
              "ID",
              style: TextStyle(color: rHint, fontWeight: FontWeight.w600),
            )),
        Expanded(
            flex: 1,
            child: Text(
              "Order",
              style: TextStyle(color: rHint, fontWeight: FontWeight.w600),
            )),
        Expanded(
            flex: 2,
            child: Text(
              "Title",
              style: TextStyle(color: rHint, fontWeight: FontWeight.bold),
            )),
        Expanded(
            flex: 1,
            child: Text(
              "Status",
              style: TextStyle(color: rHint, fontWeight: FontWeight.w600),
            )),
        Expanded(
            flex: 1,
            child: Text(
              "Action",
              style: TextStyle(color: rHint, fontWeight: FontWeight.w600),
            )),
      ],
    ).marginSymmetric(horizontal: 12, vertical: 10),
  );
}

class SubCategoryTile extends StatefulWidget {
  final SubCategoryModel subCategoryModel;

  const SubCategoryTile(this.subCategoryModel, {super.key});

  @override
  State<SubCategoryTile> createState() => _SubCategoryTileState();
}

class _SubCategoryTileState extends State<SubCategoryTile> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            flex: 1,
            child: Text(
              "${widget.subCategoryModel.id.substring(0, 5)}...",
              style:
                  const TextStyle(color: rWhite, fontWeight: FontWeight.normal),
            )),
        Expanded(
            flex: 1,
            child: Text(
              "${widget.subCategoryModel.order}",
              style:
                  const TextStyle(color: rWhite, fontWeight: FontWeight.normal),
            )),
        Expanded(
            flex: 2,
            child: Text(
              widget.subCategoryModel.english,
              style:
                  const TextStyle(color: rWhite, fontWeight: FontWeight.normal),
            )),
        Expanded(
            flex: 1,
            child: Text(
              widget.subCategoryModel.isEnabled ? "Enabled" : "Disabled",
              style: TextStyle(
                  color: widget.subCategoryModel.isEnabled ? rGreen : rRed,
                  fontWeight: FontWeight.normal),
            )),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  debugPrint(
                      "Navigating to EditSubCategory for: ${widget.subCategoryModel.english}");
                  Get.to(() => EditSubCategory(widget.subCategoryModel),
                      transition: Transition.rightToLeft);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Tooltip(
                    message: "Edit SubCategory",
                    child: SvgPicture.asset(
                      "assets/svgs/eye.svg",
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).marginSymmetric(horizontal: 12, vertical: 10);
  }
}
