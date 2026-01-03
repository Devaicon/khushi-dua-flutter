import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/controllers/themeController.dart';
import 'package:khushidua/controllers/userController.dart';
import '../../animations/fadeInAnimationBTT.dart';
import '../../constants/colors.dart';
import '../../models/categoryModel.dart';
import '../../models/subCategoryModel.dart';
import '../imageScreen.dart';
import '../openDuasScreen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel categoryModel;
  final Color color;

  const CategoryDetailScreen(this.categoryModel, this.color, {super.key});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CategoryController>().getSubCategories(widget.categoryModel);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return SafeArea(
      child: Scaffold(
        body: GetBuilder<CategoryController>(
          builder: (categoryController) {
            final subCategories = categoryController.filteredSubCategories;
            final allDuas = Get.find<DuaController>().allDuas;
            final userModel = userController.userModel;
            final readDuas = userModel?.readDuas ?? [];
            final total = subCategories.length;
            final half = (total / 2).ceil();

            List<bool> subCategoryCompleted = List.generate(total, (index) {
              final subId = subCategories[index].id;
              final duas = allDuas.where(
                (d) => d.subCategoryIds.contains(subId),
              );
              return duas.isNotEmpty &&
                  duas.every((d) => readDuas.contains(d.id));
            });

            int completedInFirstHalf = subCategoryCompleted
                .sublist(0, half)
                .where((e) => e)
                .length;

            bool isEnabled(int index) {
              if (userModel == null) return index < half;
              if (userModel.isMember == true) return true;
              return index < half || completedInFirstHalf == half;
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Material(
                        elevation: 8,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 150,
                          decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: InkWell(
                                  onTap: () => Get.back(),
                                  child: const Icon(Icons.arrow_back),
                                ),
                              ).marginSymmetric(horizontal: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 10),
                                  FadeInAnimationBTT(
                                    delay: 1,
                                    child: Text(
                                      widget.categoryModel.getName(
                                        userController.selectedLanguage,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ).marginOnly(top: 8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: subCategories.length,
                        itemBuilder: (context, index) {
                          return SubCategoryTile(
                            widget.color,
                            subCategories[index],
                            index,
                            isClickable: isEnabled(index),
                          );
                        },
                      ).marginSymmetric(horizontal: 20),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                if (categoryController.isLoading)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: rwhite.withOpacity(0.5),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SubCategoryTile extends StatelessWidget {
  final Color color;
  final SubCategoryModel subCategoryModel;
  final int index;
  final bool isClickable;

  const SubCategoryTile(
    this.color,
    this.subCategoryModel,
    this.index, {
    super.key,
    required this.isClickable,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimationBTT(
      delay: double.parse(index.toString()),
      child: InkWell(
        onTap: isClickable
            ? () {
                final themeController = Get.find<ThemeController>();
                if (themeController.selectedAgeGroup == 0 ||
                    themeController.selectedAgeGroup == 1) {
                  Get.to(
                    ImageScreen(subCategoryModel: subCategoryModel),
                    transition: Transition.fadeIn,
                  );
                } else {
                  Get.to(OpenDuasScreen(subCategoryModel));
                }
              }
            : null,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subCategoryModel.getName(
                      Get.find<UserController>().selectedLanguage,
                    ),
                    style: TextStyle(
                      color: rblack.withOpacity(0.6),
                      fontSize: 20,
                    ),
                  ),
                ),
                Icon(
                  isClickable ? Icons.navigate_next : Icons.lock_outline,
                  color: rblack,
                ),
              ],
            ).marginSymmetric(horizontal: 50, vertical: 20),
          ),
        ).marginOnly(top: 20),
      ),
    );
  }
}
