import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gen_ai/core/constants/colors.dart';
import 'package:gen_ai/ui/screens/news_screen.dart';
import 'package:gen_ai/ui/widgets/intro_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/style.dart';
import 'chat_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgcolor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: 18.w, right: 18.w, top: 45.h, bottom: 40.h),
              child: const CustomAppBar(),
            ),

            // 👋 Welcome Text + Bot Illustration
            Padding(
              padding: EdgeInsets.only(left: 18.w),
              child: const TextSvg(),
            ),

            // 🚀 Feature Cards
            Padding(
              padding: EdgeInsets.all(10.w),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.93,
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 5,
                children: [
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming Soon!')),
                      );
                    },
                    child: const CustomCard(
                      icon: Icons.mic,
                      mainhead: 'Talk with Bot',
                      subHeading: 'Chat naturally and get instant answers.',
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EnhancedChatRoom())),
                    child: const CustomCard(
                      icon: Icons.chat_bubble_outline,
                      mainhead: 'Chat with Bot',
                      subHeading: 'Get responses and advice in real time.',
                    ),
                  ),
                ],
              ),
            ),

            // 📰 Fake News Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ScamList())),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: const Color(0xFFD8ECFC),
                    width: double.infinity,
                    height: 180.r,
                    padding: EdgeInsets.all(8.w),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Container(
                            color: Colors.white,
                            height: 160.h,
                            width: 120.w,
                            child: Transform.scale(
                              scale: 1.15,
                              child: Image.asset('assets/fake.png'),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        SizedBox(
                          height: 180.h,
                          child: Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Fake News",
                                  style: TextStyle(
                                    fontFamily: "Gantari",
                                    fontSize: 22.sp,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Let's Explore What \nMisinformation is Spreading",
                                  style: TextStyle(
                                    fontFamily: "Gantari",
                                    fontSize: 14.sp,
                                    color: Colors.black54,
                                  ),
                                ),
                                const Spacer(),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: SizedBox(
                                    height: 32.h,
                                    width: 122.w,
                                    child: Row(
                                      children: [
                                        Text(
                                          "Explore Now",
                                          style: GoogleFonts.gantari(
                                            color: primaryColor,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(Icons.arrow_right_alt_rounded,
                                            color: primaryColor),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),

                  ),
                ),
              ),
            ),



          ],
        ),
      ),
    );
  }
}

// 👋 Welcome Text + Bot
class TextSvg extends StatelessWidget {
  const TextSvg({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 120.h, // Set a fixed height instead of Expanded
      child: Row(
        children: [
          Expanded( // Move Expanded here instead
            child: Stack(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Hi Boss! ',
                        style: TextStyle(
                          fontFamily: "Gantari",
                          fontSize: 34.sp,
                          color: primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: "How can         \nI help you today?",
                        style: TextStyle(
                          fontFamily: "Gantari",
                          fontSize: 34.sp,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: -20.w, // Changed from left to right for better positioning
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Transform.scale(
                      scale: 0.86,
                      child: SvgPicture.asset("assets/robot.svg"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔝 Custom App Bar
class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleAvatar(
          radius: 21.r,
          backgroundColor: cardcolor,
          child: Image.asset('assets/profile.png'),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.menu, size: 25.w, color: Colors.black),
        )
      ],
    );
  }
}
