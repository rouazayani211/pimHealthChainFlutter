import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

class CustomTextStyle {
  //app bar
  static TextStyle titleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    height: 19.36.sign,
    color: Color(0xff0e0e0c),
  );

  //grand titre
  static TextStyle h1 = TextStyle(
    fontSize: 32.sp,
    fontFamily: 'Verveine',
    fontWeight: FontWeight.w400,
    height: 33.44.sign,
  );

  //sous-titres
  static TextStyle h2 = TextStyle(
    fontSize: 16.sp,
    fontFamily: 'calibri',
    fontWeight: FontWeight.w500,
    height: 19.53.sign,
    color: Color(0xb30e0e0c),
  );

  //input label
  static TextStyle labelText = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textInputColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  //buttonText
  static TextStyle buttonText = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.2575.sign,
    color: const Color(0xffffffff),
  );

  //lien
  static TextStyle lien = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    //height: 1.2125.sign,
    decoration: TextDecoration.underline,
    color: const Color(0xff127998),
  );

  //sous-button
  static TextStyle h4 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    //height: 14.52.sign,
    color: const Color(0xff010D15),
  );
}
