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

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: widget.color,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      widget.categoryModel.getName(
                        userController.selectedLanguage,
                      ),
                      style: const TextStyle(
                        color: rbluedark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.color, widget.color.withOpacity(0.8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            top: -30,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 150,
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          Center(
                            child: Hero(
                              tag: 'category_logo_${widget.categoryModel.id}',
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.network(
                                  widget.categoryModel.logo,
                                  width: 60,
                                  height: 60,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.category,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: rbluedark,
                    ),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Get.back();
                      }
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return SubCategoryTile(
                        widget.color,
                        subCategories[index],
                        index,
                        isClickable: isEnabled(index),
                      );
                    }, childCount: subCategories.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SubCategoryTile extends StatefulWidget {
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
  State<SubCategoryTile> createState() => _SubCategoryTileState();
}

class _SubCategoryTileState extends State<SubCategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeInAnimationBTT(
      delay: (widget.index * 0.1) + 0.1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTapDown: widget.isClickable ? (_) => _controller.forward() : null,
          onTapUp: widget.isClickable ? (_) => _controller.reverse() : null,
          onTapCancel: widget.isClickable ? () => _controller.reverse() : null,
          onTap: widget.isClickable
              ? () {
                  final themeController = Get.find<ThemeController>();
                  if (themeController.selectedAgeGroup == 0 ||
                      themeController.selectedAgeGroup == 1) {
                    Get.to(
                      ImageScreen(subCategoryModel: widget.subCategoryModel),
                      transition: Transition.fadeIn,
                    );
                  } else {
                    Get.to(OpenDuasScreen(widget.subCategoryModel));
                  }
                }
              : null,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: widget.isClickable
                      ? widget.color.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 12,
                        color: widget.isClickable
                            ? widget.color
                            : Colors.grey.withOpacity(0.3),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 360
                                ? 12
                                : 20,
                            vertical: MediaQuery.of(context).size.width < 360
                                ? 12
                                : 20,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.subCategoryModel.getName(
                                    Get.find<UserController>().selectedLanguage,
                                  ),
                                  style: TextStyle(
                                    color: widget.isClickable
                                        ? rbluedark
                                        : Colors.grey,
                                    fontSize:
                                        MediaQuery.of(context).size.width < 360
                                        ? 14
                                        : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                widget.isClickable
                                    ? Icons.arrow_forward_ios_rounded
                                    : Icons.lock_rounded,
                                color: widget.isClickable
                                    ? widget.color
                                    : Colors.grey.withOpacity(0.5),
                                size: MediaQuery.of(context).size.width < 360
                                    ? 14
                                    : 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
