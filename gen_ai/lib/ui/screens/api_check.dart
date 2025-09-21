import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';

class FactCheckReportPage extends StatelessWidget {
  const FactCheckReportPage({
    super.key,
    required this.apiResult,
  });

  final Map<String, dynamic> apiResult;


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1419) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Fact Check Report",
          style: GoogleFonts.gantari(
            fontSize: 22.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFactCheckCard(isDark),
            SizedBox(height: 16.h),
            _buildEducationalCard(isDark),
            SizedBox(height: 16.h),
            _buildSourcesCard(isDark),
            SizedBox(height: 16.h),
            _buildTechnicalInfoCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFactCheckCard(bool isDark) {
    String factCheck = 'No assessment available';
    bool isCompleted = false;

    factCheck = apiResult['results']?[0]?['fact_check_assessment'] ??
        apiResult['fact_check_assessment'] ??
        apiResult['assessment'] ??
        apiResult['corrected_text'] ??
        'No assessment available';

    isCompleted = apiResult['results']?[0]?['fact_check_completed'] ??
        apiResult['fact_check_completed'] ??
        apiResult['success'] ??
        false;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152032) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: (isCompleted ? const Color(0xFF81E556) : Colors.orange).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.warning,
                  color: isCompleted ? const Color(0xFF81E556) : Colors.orange,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "Fact Check Result",
                style: GoogleFonts.gantari(
                  fontSize: 20.sp,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: (isCompleted ? const Color(0xFF81E556) : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              factCheck,
              style: GoogleFonts.mulish(
                fontSize: 14.sp,
                color: isDark ? Colors.white : Colors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalCard(bool isDark) {
    String suggestions = 'No suggestions available';

    suggestions = apiResult['results']?[0]?['further_education_suggestions'] ??
        apiResult['further_education_suggestions'] ??
        apiResult['suggestions'] ??
        apiResult['education'] ??
        'No suggestions available';

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152032) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: primaryColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "Educational Information",
                style: GoogleFonts.gantari(
                  fontSize: 20.sp,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              suggestions,
              style: GoogleFonts.mulish(
                fontSize: 14.sp,
                color: isDark ? Colors.white : Colors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesCard(bool isDark) {
    List sources = [];

    sources = (apiResult['results']?[0]?['sources_used'] as List?) ??
        (apiResult['sources_used'] as List?) ??
        (apiResult['sources'] as List?) ??
        [];

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152032) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.link,
                  color: Colors.purple,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "Trusted Sources",
                style: GoogleFonts.gantari(
                  fontSize: 20.sp,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (sources.isEmpty)
            Text(
              "No sources available",
              style: GoogleFonts.mulish(
                fontSize: 14.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            )
          else
            ...sources.asMap().entries.map((entry) {
              int index = entry.key;
              String source = entry.value.toString();
              return _buildSourceItem(source, index, isDark);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSourceItem(String source, int index, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _launchURL(source),
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.mulish(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getSourceTitle(source),
                    style: GoogleFonts.mulish(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    source,
                    style: GoogleFonts.mulish(
                      fontSize: 11.sp,
                      color: Colors.purple,
                      height: 1.3,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 16.sp,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfoCard(bool isDark) {
    dynamic processedCount = 0;
    dynamic trustScore = 'N/A';
    dynamic timestamp = 'N/A';
    dynamic newsType = 'N/A';
    dynamic domain = 'N/A';

    processedCount = apiResult['processed_count'] ?? apiResult['count'] ?? 0;

    trustScore = apiResult['results']?[0]?['trust_score'] ??
        apiResult['trust_score'] ??
        'N/A';

    timestamp = apiResult['results']?[0]?['timestamp'] ??
        apiResult['timestamp'] ??
        'N/A';

    newsType = apiResult['results']?[0]?['news_type'] ??
        apiResult['news_type'] ??
        apiResult['type'] ??
        'N/A';

    domain = apiResult['results']?[0]?['misinformation_domain'] ??
        apiResult['misinformation_domain'] ??
        apiResult['domain'] ??
        'N/A';

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152032) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Colors.grey[600],
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "Technical Details",
                style:GoogleFonts.gantari(
                  fontSize: 20.sp,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildInfoRow("Processed Count", processedCount.toString(), isDark),
          _buildInfoRow("Trust Score", trustScore.toString(), isDark),
          _buildInfoRow("Content Type", newsType, isDark),
          _buildInfoRow("Domain", domain, isDark),
          _buildInfoRow("Timestamp", _formatTimestamp(timestamp.toString()), isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              "$label:",
              style: GoogleFonts.mulish(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.mulish(
                fontSize: 13.sp,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSourceTitle(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      // Common source titles
      if (host.contains('healthline')) return 'Healthline';
      if (host.contains('mayoclinic')) return 'Mayo Clinic';
      if (host.contains('webmd')) return 'WebMD';
      if (host.contains('nhs.uk')) return 'NHS (UK)';
      if (host.contains('cdc.gov')) return 'CDC';
      if (host.contains('nih.gov')) return 'NIH';
      if (host.contains('who.int')) return 'WHO';
      if (host.contains('pubmed')) return 'PubMed';
      if (host.contains('hopkinsmedicine')) return 'Johns Hopkins Medicine';
      if (host.contains('medlineplus')) return 'MedlinePlus';

      // Extract domain name
      return host.replaceAll('www.', '').split('.')[0].toUpperCase();
    } catch (e) {
      return 'Source';
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      if (timestamp == 'N/A' || timestamp.isEmpty) return 'N/A';

      // Try to parse the timestamp
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      log('Could not launch $url: $e');
    }
  }
}