import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/member.dart';

class MemberAvatar extends StatelessWidget {
  final Member member;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const MemberAvatar({
    super.key,
    required this.member,
    this.radius = 20.0,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (member.photoPath != null && member.photoPath!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundImage: kIsWeb
            ? NetworkImage(member.photoPath!)
            : FileImage(File(member.photoPath!)) as ImageProvider,
        onBackgroundImageError: (exception, stackTrace) {
          // If image fails to load, you could show a fallback here.
          // For now, it will just show the background color.
        },
      );
    }

    // Fallback to initial if no photo is available
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
      child: Text(
        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
        style: textStyle ?? TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
