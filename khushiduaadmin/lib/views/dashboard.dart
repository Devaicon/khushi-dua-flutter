import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/controllers/categoryController.dart';
import 'package:khushiduaadmin/controllers/duaController.dart';
import 'package:khushiduaadmin/controllers/notificationController.dart';
import 'package:khushiduaadmin/controllers/userController.dart';
import 'package:khushiduaadmin/views/tabs/categories.dart';
import 'package:khushiduaadmin/views/tabs/duas.dart';
import 'package:khushiduaadmin/views/tabs/home.dart';
import 'package:khushiduaadmin/views/tabs/notifications.dart';
import 'package:khushiduaadmin/views/tabs/profile.dart';
import 'package:khushiduaadmin/views/tabs/users.dart';
import 'package:khushiduaadmin/views/tabs/mlSettings.dart';
import 'dart:html' as html;
import '../constants/colors.dart';
import '../controllers/authController.dart';
import 'auth/login.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  late Widget selectedView = HomeTab();

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData()async{
    await Get.find<AuthController>().getAdminDetails();
    Get.find<CategoryController>().getAllCategories();
    Get.find<CategoryController>().getAllSubCategories();
    Get.find<DuaController>().getAllDuas();
    Get.find<UserController>().getAllUsers();
    Get.find<NotificationController>().getAllNotifications();
  }
  switchView(Widget screen,var tabId,var user){
    setState(() {
      selectedView=screen;
      if(tabId!=null){
        _selectedTab=tabId;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBg,
      body: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.16,
            height: double.infinity,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Khushi Dua Admin",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: rWhite),),
                            Image.asset("assets/images/logo.png",width: 40,height: 40,)
                          ],
                        ),
                      ).marginOnly(top: 12),
                      ListTile(
                        tileColor: _selectedTab == 0 ? rGreen : rBg,
                        leading: SvgPicture.asset(
                          "assets/svgs/dashboard.svg",
                          color: _selectedTab == 0 ? rWhite : rHint,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                color: _selectedTab == 0 ? rWhite : rHint,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: _selectedTab == 0 ? rWhite : rHint,
                              size: 15,
                            )
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTab = 0;
                            selectedView = HomeTab();
                          });
                        },
                      ).marginOnly(top: 20),
                      ListTile(
                        tileColor: _selectedTab == 1 ? rGreen : rBg,
                        leading: SvgPicture.asset(
                          "assets/svgs/coins.svg",
                          color: _selectedTab == 1 ? rWhite : rHint,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Categories',
                              style: TextStyle(
                                color: _selectedTab == 1 ? rWhite : rHint,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: _selectedTab == 1 ? rWhite : rHint,
                              size: 15,
                            )
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTab = 1;
                            selectedView = CategoriesTab();
                          });
                        },
                      ),

                      ListTile(
                        tileColor: _selectedTab == 3 ? rGreen : rBg,
                        leading: SvgPicture.asset(
                          "assets/svgs/ad.svg",
                          color: _selectedTab == 3 ? rWhite : rHint,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Duas',
                              style: TextStyle(
                                color: _selectedTab == 3 ? rWhite : rHint,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: _selectedTab == 3 ? rWhite : rHint,
                              size: 15,
                            )
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTab = 3;
                            selectedView = DuasTab();
                          });
                        },
                      ),
                      ListTile(
                        tileColor: _selectedTab == 2 ? rGreen : rBg,
                        leading: SvgPicture.asset(
                          "assets/svgs/users.svg",
                          color: _selectedTab == 2 ? rWhite : rHint,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Users',
                              style: TextStyle(
                                color: _selectedTab == 2 ? rWhite : rHint,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: _selectedTab == 2 ? rWhite : rHint,
                              size: 15,
                            )
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTab = 2;
                            selectedView = UsersTab();
                          });
                        },
                      ),

                      ListTile(
                        tileColor: _selectedTab == 9 ? rGreen : rBg,
                        leading: Icon(Icons.notifications_active_outlined,color: _selectedTab == 9 ? rWhite : rHint ,) ,

                        // SvgPicture.asset(
                        //   "assets/svgs/users.svg",
                        //   color: _selectedTab == 9 ? rWhite : rHint,
                        // ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                color: _selectedTab == 9 ? rWhite : rHint,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: _selectedTab == 9 ? rWhite : rHint,
                              size: 15,
                            )
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTab = 9;
                            selectedView = NotificationTab();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                //profile section
                Column(
                  children: [
                    ListTile(
                      tileColor: _selectedTab == 5 ? rGreen : rBg,
                      leading: SvgPicture.asset(
                        "assets/svgs/user.svg",
                        color: _selectedTab == 5 ? rWhite : rHint,
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile',
                            style: TextStyle(
                              color: _selectedTab == 5 ? rWhite : rHint,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: _selectedTab == 5 ? rWhite : rHint,
                            size: 15,
                          )
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedTab = 5;
                          selectedView = ProfileTab();
                        });
                      },
                    ),
                    ListTile(
                      tileColor: _selectedTab == 6 ? rGreen : rBg,
                      leading: Icon(
                        Icons.settings_applications,
                        color: _selectedTab == 6 ? rWhite : rHint,
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ML Settings',
                            style: TextStyle(
                              color: _selectedTab == 6 ? rWhite : rHint,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: _selectedTab == 6 ? rWhite : rHint,
                            size: 15,
                          )
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedTab = 6;
                          selectedView = MLSettingsTab();
                        });
                      },
                    ),
                    ListTile(
                      tileColor: _selectedTab == 8 ? rGreen : rBg,
                      leading: SvgPicture.asset(
                        "assets/svgs/logout.svg",
                        color: _selectedTab == 8 ? rWhite : rHint,
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: _selectedTab == 8 ? rWhite : rHint,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: _selectedTab == 8 ? rWhite : rHint,
                            size: 15,
                          )
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedTab = 8;
                          showLogOutPopup();
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20,),
              ],
            ),
          ),
          Expanded(child: selectedView),
        ],
      ),
    );
  }
  showLogOutPopup(){
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ElasticIn(
          child: AlertDialog(
            backgroundColor: rBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Center(child: Text("Are you sure?", style: TextStyle(fontWeight: FontWeight.bold, color: rWhite))),
            content: Text(
              "You want to Logout",
              style: TextStyle(fontSize: 16, color: rWhite),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.15,
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
                      child: Text("Cancel", style: TextStyle(color: rWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      html.window.localStorage.remove('adminId');
                      Get.off(LoginScreen(),transition: Transition.fade);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: rRed),
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            rRed,
                            rRed,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text("Logout", style: TextStyle(color: rWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
          ),
        );
      },
    );
  }
}
