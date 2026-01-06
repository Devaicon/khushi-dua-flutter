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
            child: InkWell(
              onTap: () {
                Get.to(EditDua(duaModel: widget.duaModel));
              },
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset("assets/svgs/eye.svg")),
            )),
      ],
    ).marginSymmetric(horizontal: 12, vertical: 10);
  }
}
