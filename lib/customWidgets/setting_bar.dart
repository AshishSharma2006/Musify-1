import 'package:flutter/material.dart';
import 'package:musify/style/appColors.dart';

class SettingBar extends StatelessWidget {
  SettingBar(this.tileName, this.tileIcon, this.onTap);

  final Function() onTap;
  final String tileName;
  final IconData tileIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 60, right: 60, bottom: 6),
      child: Card(
        color: bgLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2.3,
        child: ListTile(
          leading: Icon(tileIcon, color: accent),
          title: Text(
            tileName,
            style: TextStyle(color: accent),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
