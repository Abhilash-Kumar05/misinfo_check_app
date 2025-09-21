import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gen_ai/core/constants/style.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_check.dart';
import '../widgets/bottomfield.dart';
import '../widgets/chatbubble.dart';
import 'api_check.dart';


class EnhancedChatRoom extends StatefulWidget {
  const EnhancedChatRoom({super.key});

  @override
  State<EnhancedChatRoom> createState() => _EnhancedChatRoomState();
}

class _EnhancedChatRoomState extends State<EnhancedChatRoom> {
  bool isStart = false;
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || isLoading) return;

    setState(() {
      _messages.add({
        "text": text,
        "isUser": true,
        "timestamp": DateTime.now(),
      });
      _controller.clear();
      isStart = true;
      isLoading = true;
    });

    // Add typing indicator
    setState(() {
      _messages.add({
        "text": "Checking facts...",
        "isUser": false,
        "isTyping": true,
        "timestamp": DateTime.now(),
      });
    });

    try {
      // Call the actual API
      final apiResult = await ApiService.categorizeText(text);

      // Remove typing indicator
      setState(() {
        _messages.removeWhere((msg) => msg["isTyping"] == true);
      });

      // Generate response based on API result
      final responseText = _generateResponseText(apiResult);

      setState(() {
        _messages.add({
          "text": responseText,
          "isUser": false,
          "factCheckData": apiResult,
          "timestamp": DateTime.now(),
        });
        isLoading = false;
      });

    } catch (e) {
      // Remove typing indicator
      setState(() {
        _messages.removeWhere((msg) => msg["isTyping"] == true);
      });

      setState(() {
        _messages.add({
          "text": "Sorry, I encountered an error while fact-checking. Please try again.",
          "isUser": false,
          "timestamp": DateTime.now(),
        });
        isLoading = false;
      });
    }
  }

  String _generateResponseText(Map<String, dynamic> apiResult) {
    final assessmentRaw = apiResult['results']?[0]?['fact_check_assessment'] ??
        apiResult['fact_check_assessment'] ??
        '';
    final assessment = assessmentRaw.toString();

    final isCompletedRaw = apiResult['results']?[0]?['fact_check_completed'] ??
        apiResult['fact_check_completed'] ??
        false;
    final isCompleted = isCompletedRaw is bool
        ? isCompletedRaw
        : (isCompletedRaw.toString().toLowerCase() == 'true');

    if (isCompleted &&
        assessment.isNotEmpty &&
        !assessment.toLowerCase().contains('failed') &&
        !assessment.toLowerCase().contains('no assessment')) {
      return "✅ Fact-checked: $assessment";
    } else {
      return "⚠️ I've analyzed your query but couldn't provide a complete fact-check assessment. Please check the full report for more details.";
    }
  }


  void _viewFullReport(Map<String, dynamic> factCheckData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FactCheckReportPage(apiResult: factCheckData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          buildRow(context, "AI Fact Checker"),
          Expanded(
            child: isStart
                ? ListView.separated(
              padding: EdgeInsets.all(12.w),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];

                // Show typing indicator
                if (msg["isTyping"] == true) {
                  return _buildTypingIndicator();
                }

                return EnhancedChatBubble(
                  message: msg["text"],
                  currentuser: msg["isUser"],
                  factCheckData: msg["factCheckData"],
                  onViewFullReport: msg["factCheckData"] != null
                      ? () => _viewFullReport(msg["factCheckData"])
                      : null,
                );
              },
              separatorBuilder: (context, index) => SizedBox(height: 10.h),
            )
                : const Center(child: WelcomeScreen()),
          ),
          BottomField(
            controller: _controller,
            onTap: _sendMessage,

          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(right: 50.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Checking facts",
              style: GoogleFonts.mulish(
                fontSize: 14.sp,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 8.w),
            SizedBox(
              width: 50.w,
              height: 25.h,
              child: Transform.scale(
                scale: 4,
                child: Lottie.asset(
                  "assets/Loading Dots Blue.json",
                  // or BoxFit.cover depending on what you want
                ),
              ),)

        ],
        ),
      ),
    );
  }

  Widget buildRow(BuildContext context, String name) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 8.h),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            SizedBox(width: 10.w),
            Text(name, style: med),
          ],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Transform.scale(
              scale: 0.8,
              child: SvgPicture.asset('assets/robot.svg'),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '      Hi Boss! ',
                    style: TextStyle(
                      fontFamily: "Gantari",
                      fontSize: 32.sp,
                      color: primaryColor,
                    ),
                  ),
                  TextSpan(
                    text: "Don't \nstress, just fact-check",
                    style: TextStyle(
                      fontFamily: "Gantari",
                      fontSize: 32.sp,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Enhanced Bottom Field with Loading State


class EnhancedBottomField extends StatelessWidget {
  const EnhancedBottomField({
    super.key,
    required this.controller,
    required this.onTap,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152032) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !isLoading,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.mulish(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: isLoading ? "Fact-checking..." : "Ask me to fact-check something...",
                    hintStyle: GoogleFonts.mulish(
                      fontSize: 14.sp,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: isLoading ? null : onTap,
              child: Container(
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  color: isLoading ? Colors.grey : primaryColor,
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20.sp,
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