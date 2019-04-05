import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// https://material.io/tools/color/#!/?view.left=0&view.right=0&primary.color=FFA5DD&secondary.color=7ED776&secondary.text.color=ffffff
class ThemeMetrics {
  static const primaryColor = Color.fromARGB(0xff, 0xff, 0xa5, 0xdd);
  static const primaryColorLight = Color.fromARGB(0xff, 0xff, 0xd7, 0xff);
  static const primaryColorDark = Color.fromARGB(0xff, 0xcb, 0x75, 0xab);

  static const primaryColorText = Colors.black;

  static const secondaryColor = Color.fromARGB(0xff, 0x7e, 0xd7, 0x76);
  static const secondaryColorLight = Color.fromARGB(0xff, 0xb1, 0xff, 0xa6);
  static const secondaryColorDark = Color.fromARGB(0xff, 0x4c, 0xa5, 0x48);

  static const secondaryColorText = Colors.white;

  static const neutralDark = Color.fromARGB(0xff, 0xe1, 0xe2, 0xe1);
  static const neutralLight = Color.fromARGB(0xff, 0xf5, 0xf5, 0xf6);

  static ThemeData fullTheme() {
    final titleFont =
        TextTheme(title: TextStyle(fontFamily: "GrandHotel", fontSize: 26.0));

    final typography = Typography(
        platform: defaultTargetPlatform,
        dense: Typography.dense2018,
        englishLike: Typography.englishLike2018.merge(titleFont),
        tall: Typography.tall2018);

    return ThemeData(
        primaryColor: primaryColor,
        primaryColorLight: primaryColorLight,
        primaryColorDark: primaryColorDark,
        primaryTextTheme:
            typography.englishLike.apply(bodyColor: primaryColorText),
        buttonTheme: ButtonThemeData(
            textTheme: ButtonTextTheme.primary, buttonColor: primaryColor),
        backgroundColor: neutralLight,
        dialogBackgroundColor: neutralLight,
        scaffoldBackgroundColor: neutralLight,
        accentColor: secondaryColor,
        toggleableActiveColor: secondaryColor,
        accentTextTheme:
            typography.englishLike.apply(displayColor: secondaryColorText),
        typography: typography);
  }
}
