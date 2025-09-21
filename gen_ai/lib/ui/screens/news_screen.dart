import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gen_ai/core/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/style.dart';
import '../../core/services/news_service.dart';
 // Add this import



class ScamList extends StatefulWidget {
  @override
  _ScamListState createState() => _ScamListState();
}

class _ScamListState extends State<ScamList> {
  List<FactCheckClaim> factCheckedNews = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  // Categories for filtering
  final List<String> categories = [
    'All',
    'Politics',
    'Health',
    'Technology',
    'Social Media',
    'COVID-19',
    'Climate'
  ];

  String selectedCategory = 'All';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFactCheckedNews();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFactCheckedNews() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await GoogleFactCheckService.getRecentFactChecks(
        pageSize: 50,
      );

      setState(() {
        factCheckedNews = response.claims;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _searchFactChecks(String query) async {
    if (query.trim().isEmpty) {
      _loadFactCheckedNews();
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await GoogleFactCheckService.searchByTopic(
        query,
        pageSize: 30,
      );

      setState(() {
        factCheckedNews = response.claims;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _filterByCategory(String category) async {
    setState(() {
      selectedCategory = category;
    });

    if (category == 'All') {
      _loadFactCheckedNews();
    } else {
      _searchFactChecks(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text("Misinformation News", style: med),
        actions: [
          IconButton(
            onPressed: _loadFactCheckedNews,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: hasError ? _buildErrorState() : Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Category filter
          _buildCategoryFilter(),

          5.verticalSpace,

          // Content
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : factCheckedNews.isEmpty
                ? _buildEmptyState()
                : _buildNewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search fact checks...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              searchController.clear();
              _loadFactCheckedNews();
            },
            icon: Icon(Icons.clear),
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: _searchFactChecks,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) => _filterByCategory(category),
              backgroundColor: Colors.grey[100],
              selectedColor: primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : Colors.black54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 16),
          Text(
            "Loading fact-checked news...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          SizedBox(height: 16),
          Text(
            "Failed to load fact checks",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage.contains('API')
                  ? "Please check your API key and internet connection"
                  : errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFactCheckedNews,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.fact_check,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "No fact checks found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            selectedCategory == 'All'
                ? "Try searching for specific topics"
                : "No results for '$selectedCategory'",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    return ListView.builder(
      itemCount: factCheckedNews.length,
      itemBuilder: (context, index) {
        final claim = factCheckedNews[index];
        return _buildNewsItem(claim, index);
      },
    );
  }

  Widget _buildNewsItem(FactCheckClaim claim, int index) {
    final primaryReview = claim.claimReviews.isNotEmpty
        ? claim.claimReviews.first
        : null;

    final ratingType = primaryReview?.getRatingType() ?? RatingType.unknown;
    final publisherName = primaryReview?.publisher?.name ?? "Fact Checker";
    final reviewDate = primaryReview?.reviewDate ?? claim.claimDate?.toIso8601String();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showClaimDetails(claim),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating badge and publisher
                Row(
                  children: [
                    _buildRatingBadge(ratingType),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        publisherName,
                        style: GoogleFonts.lato(
                          color: primaryColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (reviewDate != null)
                      Text(
                        _formatTimeAgo(reviewDate),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11.sp,
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 12),

                // Claim text
                Text(
                  claim.text,
                  style: TextStyle(
                    fontFamily: "Gantari",
                    fontSize: 16.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 12),

                // Claimant and additional info
                if (claim.claimant != null) ...[
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Claimed by: ${claim.claimant}",
                          style: TextStyle(
                            fontFamily: "Gantari",
                            fontSize: 13.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],

                // Bottom row with rating details and review count
                Row(
                  children: [
                    if (primaryReview?.textualRating != null)
                      Expanded(
                        child: Text(
                          "Rating: ${primaryReview!.textualRating}",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: ratingType.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.fact_check,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          "${claim.claimReviews.length} review${claim.claimReviews.length != 1 ? 's' : ''}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(RatingType ratingType) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ratingType.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ratingType.label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  void _showClaimDetails(FactCheckClaim claim) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildClaimDetailsModal(claim),
    );
  }

  Widget _buildClaimDetailsModal(FactCheckClaim claim) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Fact Check Details",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          Divider(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Claim text
                  Text(
                    "Claim:",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    claim.text,
                    style: TextStyle(fontSize: 16.sp),
                  ),

                  if (claim.claimant != null) ...[
                    SizedBox(height: 16),
                    Text(
                      "Claimant:",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(claim.claimant!),
                  ],

                  SizedBox(height: 20),

                  // Reviews
                  Text(
                    "Fact Check Reviews:",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 12),

                  ...claim.claimReviews.map((review) => _buildReviewCard(review)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ClaimReview review) {
    final ratingType = review.getRatingType();

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildRatingBadge(ratingType),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    review.publisher?.name ?? "Unknown Publisher",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),

            if (review.title != null) ...[
              SizedBox(height: 8),
              InkWell(
                onTap: () => _launchUrl(review.url),
                child: Text(
                  review.title!,
                  style: TextStyle(
                    color: primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],

            if (review.textualRating != null) ...[
              SizedBox(height: 8),
              Text("Rating: ${review.textualRating}"),
            ],
          ],
        ),
      ),
    );
  }

  void _launchUrl(String? url) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}