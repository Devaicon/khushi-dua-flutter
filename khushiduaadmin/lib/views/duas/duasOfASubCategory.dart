import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/models/subCategoryModel.dart';

import '../../constants/colors.dart';
import '../../constants/firebaseRef.dart';
import '../../controllers/duaController.dart';
import '../../models/duaModel.dart';
import '../../widgets/topBar.dart';
import 'editDua.dart';

class DuasOfASubCategory extends StatefulWidget {
  SubCategoryModel model;
  DuasOfASubCategory(this.model, {super.key});

  @override
  State<DuasOfASubCategory> createState() => _DuasOfASubCategoryState();
}

class _DuasOfASubCategoryState extends State<DuasOfASubCategory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: GetBuilder<DuaController>(
        builder: (duaController) {
          final filteredDuas = duaController.allDuas
              .where((dua) => dua.subCategoryIds.contains(widget.model.id))
              .toList();
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TopBar(title: "Duas"),
                InkWell(
                  onTap: () => Get.back(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios, color: rWhite, size: 16),
                      SizedBox(width: 4),
                      Text("Back", style: TextStyle(color: rWhite)),
                    ],
                  ),
                ).marginOnly(top: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Duas of ${widget.model.english}",
                      style: const TextStyle(
                          color: rWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 20),
                    ),
                  ],
                ).marginOnly(top: 6),
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

                            // final movedCategory = duaController.allDuas.removeAt(oldIndex);
                            // duaController.allDuas.insert(newIndex, movedCategory);

                            final movedCategory =
                                filteredDuas.removeAt(oldIndex);
                            filteredDuas.insert(newIndex, movedCategory);

                            for (int i = 0; i < filteredDuas.length; i++) {
                              final dua = filteredDuas[i];
                              await duaRef.doc(dua.id).update({"order": i});
                            }
                            setState(() {});
                          },
                          children: [
                            for (int index = 0;
                                index < filteredDuas.length;
                                index++)
                              DuaTile(
                                filteredDuas[index],
                                key: ValueKey(filteredDuas[index].id),
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

class DuaTile extends StatefulWidget {
  final DuaModel duaModel;

  const DuaTile(this.duaModel, {super.key});

  @override
  State<DuaTile> createState() => _DuaTileState();
}

class _DuaTileState extends State<DuaTile> {
  void _showDeleteDialog(BuildContext context) {
    bool deleteLittleKids = widget.duaModel.littleKids;
    bool deleteOlderKids = widget.duaModel.olderKids;
    bool deleteGrownUps = widget.duaModel.grownUps;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ElasticIn(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: rBg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text(
                  "Delete Dua",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rWhite,
                      fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Remove from which sections?",
                      style: TextStyle(color: rHint, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (widget.duaModel.littleKids)
                      Row(
                        children: [
                          Checkbox(
                            value: deleteLittleKids,
                            activeColor: rRed,
                            checkColor: Colors.white,
                            onChanged: (val) =>
                                setDialogState(() => deleteLittleKids = val!),
                          ),
                          const Text("Little Kids",
                              style: TextStyle(color: rWhite)),
                        ],
                      ),
                    if (widget.duaModel.olderKids)
                      Row(
                        children: [
                          Checkbox(
                            value: deleteOlderKids,
                            activeColor: rRed,
                            checkColor: Colors.white,
                            onChanged: (val) =>
                                setDialogState(() => deleteOlderKids = val!),
                          ),
                          const Text("Older Kids",
                              style: TextStyle(color: rWhite)),
                        ],
                      ),
                    if (widget.duaModel.grownUps)
                      Row(
                        children: [
                          Checkbox(
                            value: deleteGrownUps,
                            activeColor: rRed,
                            checkColor: Colors.white,
                            onChanged: (val) =>
                                setDialogState(() => deleteGrownUps = val!),
                          ),
                          const Text("Grown Ups",
                              style: TextStyle(color: rWhite)),
                        ],
                      ),
                  ],
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.1,
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: rGreen),
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                rGreen.withOpacity(0.22),
                                rGreen.withOpacity(0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Cancel",
                              style: TextStyle(
                                  color: rWhite, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (!deleteLittleKids &&
                              !deleteOlderKids &&
                              !deleteGrownUps) {
                            return;
                          }
                          Get.find<DuaController>().deleteDua(
                            widget.duaModel,
                            deleteLittleKids: deleteLittleKids,
                            deleteOlderKids: deleteOlderKids,
                            deleteGrownUps: deleteGrownUps,
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.1,
                          height: 44,
                          decoration: BoxDecoration(
                            color: rRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Delete",
                              style: TextStyle(
                                  color: rWhite, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            flex: 1,
            child: Text(
              "${widget.duaModel.id.substring(0, 5)}...",
              style:
                  const TextStyle(color: rWhite, fontWeight: FontWeight.normal),
            )),
        Expanded(
            flex: 2,
            child: Text(
              widget.duaModel.english,
              style:
                  const TextStyle(color: rWhite, fontWeight: FontWeight.normal),
            )),
        Expanded(
            flex: 1,
            child: Text(
              widget.duaModel.isEnabled ? "Enabled" : "Disabled",
              style: TextStyle(
                  color: widget.duaModel.isEnabled ? rGreen : rRed,
                  fontWeight: FontWeight.normal),
            )),
        Expanded(
            flex: 1,
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    Get.to(EditDua(duaModel: widget.duaModel));
                  },
                  child: SvgPicture.asset("assets/svgs/eye.svg"),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => _showDeleteDialog(context),
                  child: const Icon(Icons.delete_outline,
                      color: rRed, size: 20),
                ),
              ],
            )),
      ],
    ).marginSymmetric(horizontal: 12, vertical: 10);
  }
}
