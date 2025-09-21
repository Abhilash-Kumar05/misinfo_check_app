import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gen_ai/core/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class EnhancedChatBubble extends StatelessWidget {
  const EnhancedChatBubble({
    super.key,
    required this.message,
    required this.currentuser,
    this.factCheckData,
    this.onViewFullReport,
  });

  final String message;
  final bool currentuser;
  final Map<String, dynamic>? factCheckData;
  final VoidCallback? onViewFullReport;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alignment = currentuser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: 1.sw * 0.75),
        margin: EdgeInsets.only(
          left: currentuser ? 50.w : 0,
          right: currentuser ? 0 : 50.w,
        ),
        child: Column(
          crossAxisAlignment: currentuser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Main message bubble
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: currentuser
                    ? primaryColor
                    : isDark
                    ? const Color(0xFF152032)
                    : const Color(0xFFFFE1E1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                message,
                style: GoogleFonts.mulish(
                  fontSize: 14.sp,
                  color: currentuser
                      ? Colors.white
                      : isDark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),

            // Fact check summary (only for AI responses)
            if (!currentuser && factCheckData != null) ...[
              SizedBox(height: 8.h),
              _buildFactCheckSummary(context, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFactCheckSummary(BuildContext context, bool isDark) {
    final trustScore = _getTrustScore();
    final hasAssessment = _hasValidAssessment();

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with trust score
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 16.sp,
                color: _getScoreColor(trustScore),
              ),
              SizedBox(width: 6.w),
              Text(
                "Fact Check",
                style: GoogleFonts.mulish(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: _getScoreColor(trustScore).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  trustScore,
                  style: GoogleFonts.mulish(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: _getScoreColor(trustScore),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Quick assessment
          if (hasAssessment)
            Text(
              _getQuickAssessment(),
              style: GoogleFonts.mulish(
                fontSize: 11.sp,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          SizedBox(height: 8.h),

          // View full report button
          GestureDetector(
            onTap: onViewFullReport,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "View Full Report",
                    style: GoogleFonts.mulish(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10.sp,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTrustScore() {
    if (factCheckData == null) return "N/A";

    final score = factCheckData?['results']?[0]?['trust_score'] ??
        factCheckData?['trust_score'] ??
        "N/A";
    return score.toString();
  }

  bool _hasValidAssessment() {
    if (factCheckData == null) return false;

    final assessment = factCheckData?['results']?[0]?['fact_check_assessment'] ??
        factCheckData?['fact_check_assessment'] ??
        "";

    return assessment.toString().isNotEmpty &&
        !assessment.toString().toLowerCase().contains("no assessment") &&
        !assessment.toString().toLowerCase().contains("failed");
  }

  String _getQuickAssessment() {
    if (factCheckData == null) return "No assessment available";

    final assessment = factCheckData?['results']?[0]?['fact_check_assessment'] ??
        factCheckData?['fact_check_assessment'] ??
        factCheckData?['corrected_text'] ??
        "No assessment available";

    return assessment.toString();
  }

  Color _getScoreColor(String score) {
    if (score == "N/A" || score.isEmpty) return Colors.grey;

    try {
      final numScore = double.tryParse(score) ?? 0;
      if (numScore >= 0.8) return Colors.green;
      if (numScore >= 0.6) return Colors.orange;
      return Colors.red;
    } catch (e) {
      return Colors.grey;
    }
  }
}