import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/constants/firebaseRef.dart';
import 'package:khushiduaadmin/controllers/notificationController.dart';
import 'package:khushiduaadmin/controllers/userController.dart';
import 'package:khushiduaadmin/models/userModel.dart';

import '../../constants/colors.dart';
import '../../widgets/topBar.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: GetBuilder<UserController>(
        builder: (userController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(title: "Users"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Container(
                      height: 125,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16), color: rBg),
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
                                    end: userController.allUsers.length),
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
                                "Total Users",
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
                          borderRadius: BorderRadius.circular(16), color: rBg),
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
                                    end: userController.allUsers
                                        .where((element) =>
                                            element.isMember == true)
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
                                "Total Members",
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
                          borderRadius: BorderRadius.circular(16), color: rBg),
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
                                    end: userController.allUsers
                                        .where((element) =>
                                            element.isBlocked == true)
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
                                "Blocked Users",
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
                    ListView.builder(
                      itemCount: userController.allUsers.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return UserTile(userController.allUsers[index]);
                      },
                    ),
                  ],
                ),
              )
            ],
          ).marginSymmetric(horizontal: 12, vertical: 12);
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
              "Email",
              style: TextStyle(color: rHint, fontWeight: FontWeight.w600),
            )),
        Expanded(
            flex: 1,
            child: Text(
              "Name",
              style: TextStyle(color: rHint, fontWeight: FontWeight.w600),
            )),
        Expanded(
            flex: 1,
            child: Text(
              "Is Member",
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

class UserTile extends StatefulWidget {
  final UserModel userModel;

  const UserTile(this.userModel, {super.key});

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            flex: 1,
            child: Text(
              "${widget.userModel.id.substring(0, 5)}...",
              style:
                  const TextStyle(color: rWhite, fontWeight: FontWeight.normal),
            )),
        Expanded(
            flex: 2,
            child: Text(
              widget.userModel.email,
              style:
                  const TextStyle(color: rWhite, fontWeight: FontWeight.normal),
            )),
        Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userModel.name,
                  style: const TextStyle(
                      color: rWhite, fontWeight: FontWeight.normal),
                )
              ],
            )),
        Expanded(
            flex: 1,
            child: Text(
              "${widget.userModel.isMember}",
              style: TextStyle(
                  color: widget.userModel.isMember ? rGreen : rRed,
                  fontWeight: FontWeight.normal),
            )),
        Expanded(
            flex: 1,
            child: Text(
              widget.userModel.isBlocked ? "Blocked" : "Active",
              style: TextStyle(
                  color: widget.userModel.isBlocked ? rRed : rGreen,
                  fontWeight: FontWeight.normal),
            )),
        Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    //show membership dialog
                    if (widget.userModel.isMember) {
                      showMemberPopUp(false);
                    } else {
                      showMemberPopUp(true);
                    }
                  },
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.credit_card,
                        color: widget.userModel.isMember ? rHint : rGreen,
                      )),
                ).marginOnly(left: 12),
                InkWell(
                  onTap: () {
                    //show block popup
                    if (widget.userModel.isBlocked) {
                      showBlockPopUp(false);
                    } else {
                      showBlockPopUp(true);
                    }
                  },
                  child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.block,
                        color: rRed,
                      )),
                ).marginOnly(left: 12),
              ],
            )),
      ],
    ).marginSymmetric(horizontal: 12, vertical: 10);
  }

  showBlockPopUp(bool action) {
    showDialog(
      context: context,
      builder: (context) {
        return ElasticIn(
          child: AlertDialog(
            backgroundColor: rBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(action ? "Block" : "UnBlock",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: rWhite)),
            content: action
                ? Text(
                    "Are you sure you want to block ${widget.userModel.name}?",
                    style: const TextStyle(fontSize: 16, color: rWhite),
                  )
                : Text(
                    "Are you sure you want to unblock ${widget.userModel.name}?",
                    style: const TextStyle(fontSize: 16, color: rWhite),
                  ),
            actions: [
              TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: rRed),
                  )),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () async {
                  await userRef
                      .doc(widget.userModel.id)
                      .update({"isBlocked": action});
                  if (action == true) {
                    await Get.find<NotificationController>()
                        .sendIndividualNotification(
                            widget.userModel,
                            "Account suspended",
                            "Your account has been blocked due to malicious activity");
                  } else {
                    await Get.find<NotificationController>()
                        .sendIndividualNotification(
                            widget.userModel,
                            "Account activated",
                            "Your account has been unbanned");
                  }
                  Get.back();
                },
                child: Container(
                  // width: MediaQuery.of(context).size.width * 0.7,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: rGreen),
                    borderRadius: BorderRadius.circular(16),
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
                  child: const Text("Confirm",
                      style: TextStyle(
                          color: rWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
          ),
        );
      },
    );
  }

  showMemberPopUp(bool action) {
    showDialog(
      context: context,
      builder: (context) {
        return ElasticIn(
          child: AlertDialog(
            backgroundColor: rBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(action ? "Grant Membership" : "Revoke Membership",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: rWhite)),
            content: action
                ? Text(
                    "Are you sure you want to make ${widget.userModel.name} paid member?",
                    style: const TextStyle(fontSize: 16, color: rWhite),
                  )
                : Text(
                    "Are you sure you want to revoke ${widget.userModel.name}'s membership?",
                    style: const TextStyle(fontSize: 16, color: rWhite),
                  ),
            actions: [
              TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: rRed),
                  )),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () async {
                  await userRef
                      .doc(widget.userModel.id)
                      .update({"isMember": action});
                  if (action) {
                    await Get.find<NotificationController>()
                        .sendIndividualNotification(
                            widget.userModel,
                            "Account upgraded",
                            "You have successfully purchased premium membership");
                  } else {
                    await Get.find<NotificationController>()
                        .sendIndividualNotification(
                            widget.userModel,
                            "Account degraded",
                            "You account membership has been expired");
                  }
                  Get.back();
                },
                child: Container(
                  // width: MediaQuery.of(context).size.width * 0.7,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: rGreen),
                    borderRadius: BorderRadius.circular(16),
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
                  child: const Text("Confirm",
                      style: TextStyle(
                          color: rWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
          ),
        );
      },
    );
  }
}
