import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/style.dart';

class CustomCard extends StatelessWidget {
  final IconData icon;
  final String mainhead;
  final String subHeading;

  const CustomCard({
    Key? key,
    required this.icon,
    required this.mainhead,
    required this.subHeading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(


        color: const Color(0xFFD8ECFC), // light blue background
       //
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  color: Colors.white,
                    height: 40.r,
                    width: 40.r,
                    child: Icon(icon, size: 25.r, color: Colors.black87)),
              ),
              Spacer(),
              Text(
                mainhead,
                style: TextStyle(
                  fontFamily: "Gantari",
                  fontSize: 22.sp,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subHeading,
                style: TextStyle(
                  fontFamily: "Gantari",
                  fontSize: 13.sp,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
