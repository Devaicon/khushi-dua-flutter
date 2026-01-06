import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/constants/firebaseRef.dart';
import 'package:khushiduaadmin/controllers/duaController.dart';
import 'package:khushiduaadmin/models/duaModel.dart';
import 'package:khushiduaadmin/views/duas/createNewDua.dart';
import 'package:khushiduaadmin/views/duas/editDua.dart';

import '../../constants/colors.dart';
import '../../widgets/topBar.dart';

class DuasTab extends StatefulWidget {
  const DuasTab({super.key});

  @override
  State<DuasTab> createState() => _DuasTabState();
}

class _DuasTabState extends State<DuasTab> {
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: GetBuilder<DuaController>(
        builder: (duaController) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TopBar(title: "Duas"),
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
                                      begin: 0,
                                      end: duaController.allDuas.length),
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
                                  "Total Duas",
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
                                      end: duaController.allDuas
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
                                  "Disabled Duas",
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
                                      end: duaController.allDuas
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
                                  "Enabled Duas",
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
                      "All Duas",
                      style: TextStyle(
                          color: rWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 20),
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        Get.to(const CreateNewDua(),
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
                              "Create a new Dua",
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

                            final movedDua =
                                duaController.allDuas.removeAt(oldIndex);
                            duaController.allDuas.insert(newIndex, movedDua);

                            final batch = FirebaseFirestore.instance.batch();
                            for (int i = 0;
                                i < duaController.allDuas.length;
                                i++) {
                              final dua = duaController.allDuas[i];
                              dua.order = i;
                              batch.update(duaRef.doc(dua.id), {"order": i});
                            }

                            try {
                              duaController.update();
                              await batch.commit();
                            } catch (e) {
                              debugPrint("Error updating dua order: $e");
                            }
                          },
                          children: [
                            for (int index = 0;
                                index < duaController.allDuas.length;
                                index++)
                              DuaTile(
                                duaController.allDuas[index],
                                key: ValueKey(duaController.allDuas[index].id),
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
