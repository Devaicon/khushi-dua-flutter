import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

import '../constants/colors.dart';

class CustomLoading extends StatefulWidget {
  const CustomLoading({super.key});

  @override
  State<CustomLoading> createState() => _CustomLoadingState();
}

class _CustomLoadingState extends State<CustomLoading> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.1,
        height: MediaQuery.of(context).size.width * 0.1,
        child: const LoadingIndicator(
            indicatorType: Indicator.ballScaleMultiple,
            colors: [rGreen, rHint, rRed],
            strokeWidth: 14,
            backgroundColor: Colors.transparent,
            pathBackgroundColor: Colors.black),
      ),
    );
  }
}
