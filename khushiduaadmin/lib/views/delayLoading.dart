import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../widgets/customLoading.dart';

class DelayLoading extends StatefulWidget {
  const DelayLoading({super.key});

  @override
  State<DelayLoading> createState() => _DelayLoadingState();
}

class _DelayLoadingState extends State<DelayLoading> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: rWhite.withOpacity(0.2),
          child: const CustomLoading()),
    );
  }
}
