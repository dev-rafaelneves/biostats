import 'package:flutter/material.dart';

class FractionalHorizontalClipper extends CustomClipper<Rect> {
  final double fraction;

  FractionalHorizontalClipper({required this.fraction});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(FractionalHorizontalClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}
