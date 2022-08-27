import 'package:flutter/material.dart';
import 'package:musify/style/appColors.dart';

class Spinner extends StatelessWidget {
  const Spinner({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    );
  }
}
