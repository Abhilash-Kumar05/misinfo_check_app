import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GoogleFactCheckService {
  static const String baseUrl = "https://factchecktools.googleapis.com/v1alpha1";
  static const String apiKey = "AIzaSyAusLAIpIXZlDXLfDVZGiisTfzPXSYr280"; // Replace with your actual API key

  /// Search for fact-checked claims
  static Future<FactCheckResponse> searchClaims({
    String? query,
    String? languageCode = "en",
    int pageSize = 10,
    int offset = 0,
    String? reviewPublisherSiteFilter,
  }) async {
    try {
      // Validate that we have either a query or a publisher filter
      if ((query == null || query.trim().isEmpty) &&
          (reviewPublisherSiteFilter == null || reviewPublisherSiteFilter.trim().isEmpty)) {
        // Fallback: use a default search term
        query = 'misinformation';
      }

      final queryParams = <String, String>{
        'key': apiKey,
        'languageCode': languageCode ?? 'en',
        'pageSize': pageSize.toString(),
        'offset': offset.toString(),
      };

      // Add query or publisher filter
      if (query != null && query.trim().isNotEmpty) {
        queryParams['query'] = query.trim();
      }
      if (reviewPublisherSiteFilter != null && reviewPublisherSiteFilter.trim().isNotEmpty) {
        queryParams['reviewPublisherSiteFilter'] = reviewPublisherSiteFilter.trim();
      }

      final uri = Uri.parse("$baseUrl/claims:search").replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FactCheckResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        // Handle API key or parameter errors
        final errorData = jsonDecode(response.body);
        throw Exception('API Error: ${errorData['error']['message'] ?? 'Invalid request parameters'}');
      } else if (response.statusCode == 403) {
        throw Exception('API Key Error: Please check your Google Fact Check API key and permissions');
      } else {
        throw Exception('Failed to fetch fact checks: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Network Error: Please check your internet connection');
      }
      rethrow;
    }
  }

  /// Get recent fact checks (general trending misinformation)
  static Future<FactCheckResponse> getRecentFactChecks({
    int pageSize = 20,
    String? languageCode = "en",
  }) async {
    // Try multiple approaches to get content
    try {
      // First try: Search with rotating general topics
      const List<String> generalTopics = [
        'politics', 'health', 'covid', 'vaccine', 'election',
        'climate', 'social media', 'technology', 'news'
      ];

      final topicIndex = DateTime.now().millisecondsSinceEpoch % generalTopics.length;
      final selectedTopic = generalTopics[topicIndex];

      final result = await searchClaims(
        query: selectedTopic,
        pageSize: pageSize,
        languageCode: languageCode,
      );

      if (result.claims.isNotEmpty) {
        return result;
      }
    } catch (e) {
      print('Topic search failed: $e');
    }

    // Fallback: Try getting from popular fact-check publishers
    try {
      return await getFactChecksFromPopularPublishers(
        pageSize: pageSize,
        languageCode: languageCode,
      );
    } catch (e) {
      print('Publisher search failed: $e');
    }

    // Final fallback: Simple search
    return await searchClaims(
      query: 'fact check',
      pageSize: pageSize,
      languageCode: languageCode,
    );
  }

  /// Get fact checks from popular publishers
  static Future<FactCheckResponse> getFactChecksFromPopularPublishers({
    int pageSize = 20,
    String? languageCode = "en",
  }) async {
    const List<String> popularPublishers = [
      'snopes.com',
      'politifact.com',
      'factcheck.org',
      'reuters.com',
      'apnews.com'
    ];

    // Try each publisher until we get results
    for (String publisher in popularPublishers) {
      try {
        final result = await getFactChecksByPublisher(
          publisher,
          pageSize: pageSize ~/ 2, // Smaller size per publisher
          languageCode: languageCode,
        );

        if (result.claims.isNotEmpty) {
          return result;
        }
      } catch (e) {
        print('Failed to get from $publisher: $e');
        continue;
      }
    }

    // If all publishers fail, return empty response
    return FactCheckResponse(claims: []);
  }

  /// Search fact checks by topic
  static Future<FactCheckResponse> searchByTopic(
      String topic, {
        int pageSize = 10,
        String? languageCode = "en",
      }) async {
    return await searchClaims(
      query: topic,
      pageSize: pageSize,
      languageCode: languageCode,
    );
  }

  /// Get fact checks from specific publishers
  static Future<FactCheckResponse> getFactChecksByPublisher(
      String publisherSite, {
        int pageSize = 10,
        String? languageCode = "en",
      }) async {
    return await searchClaims(
      reviewPublisherSiteFilter: publisherSite,
      pageSize: pageSize,
      languageCode: languageCode,
    );
  }
}

// Data Models
class FactCheckResponse {
  final List<FactCheckClaim> claims;
  final String? nextPageToken;

  FactCheckResponse({
    required this.claims,
    this.nextPageToken,
  });

  factory FactCheckResponse.fromJson(Map<String, dynamic> json) {
    return FactCheckResponse(
      claims: (json['claims'] as List<dynamic>?)
          ?.map((claim) => FactCheckClaim.fromJson(claim))
          .toList() ?? [],
      nextPageToken: json['nextPageToken'],
    );
  }
}

class FactCheckClaim {
  final String text;
  final String? claimant;
  final DateTime? claimDate;
  final List<ClaimReview> claimReviews;

  FactCheckClaim({
    required this.text,
    this.claimant,
    this.claimDate,
    required this.claimReviews,
  });

  factory FactCheckClaim.fromJson(Map<String, dynamic> json) {
    return FactCheckClaim(
      text: json['text'] ?? '',
      claimant: json['claimant'],
      claimDate: json['claimDate'] != null
          ? DateTime.tryParse(json['claimDate'])
          : null,
      claimReviews: (json['claimReview'] as List<dynamic>?)
          ?.map((review) => ClaimReview.fromJson(review))
          .toList() ?? [],
    );
  }
}

class ClaimReview {
  final Publisher? publisher;
  final String? url;
  final String? title;
  final String? reviewDate;
  final String? textualRating;
  final String? languageCode;

  ClaimReview({
    this.publisher,
    this.url,
    this.title,
    this.reviewDate,
    this.textualRating,
    this.languageCode,
  });

  factory ClaimReview.fromJson(Map<String, dynamic> json) {
    return ClaimReview(
      publisher: json['publisher'] != null
          ? Publisher.fromJson(json['publisher'])
          : null,
      url: json['url'],
      title: json['title'],
      reviewDate: json['reviewDate'],
      textualRating: json['textualRating'],
      languageCode: json['languageCode'],
    );
  }

  // Helper method to get rating color
  RatingType getRatingType() {
    final rating = textualRating?.toLowerCase() ?? '';
    if (rating.contains('false') || rating.contains('pants on fire')) {
      return RatingType.false_;
    } else if (rating.contains('mostly false') || rating.contains('incorrect')) {
      return RatingType.mostlyFalse;
    } else if (rating.contains('half') || rating.contains('mixed')) {
      return RatingType.mixed;
    } else if (rating.contains('mostly true') || rating.contains('correct')) {
      return RatingType.mostlyTrue;
    } else if (rating.contains('true')) {
      return RatingType.true_;
    }
    return RatingType.unknown;
  }
}

class Publisher {
  final String name;
  final String? site;

  Publisher({
    required this.name,
    this.site,
  });

  factory Publisher.fromJson(Map<String, dynamic> json) {
    return Publisher(
      name: json['name'] ?? '',
      site: json['site'],
    );
  }
}

enum RatingType {
  true_,
  mostlyTrue,
  mixed,
  mostlyFalse,
  false_,
  unknown,
}

// Extension to get colors for ratings
extension RatingTypeColors on RatingType {
  Color get color {
    switch (this) {
      case RatingType.true_:
        return Colors.green;
      case RatingType.mostlyTrue:
        return Colors.lightGreen;
      case RatingType.mixed:
        return Colors.orange;
      case RatingType.mostlyFalse:
        return Colors.redAccent;
      case RatingType.false_:
        return Colors.red;
      case RatingType.unknown:
        return Colors.grey;
    }
  }

  String get label {
    switch (this) {
      case RatingType.true_:
        return "TRUE";
      case RatingType.mostlyTrue:
        return "MOSTLY TRUE";
      case RatingType.mixed:
        return "MIXED";
      case RatingType.mostlyFalse:
        return "MOSTLY FALSE";
      case RatingType.false_:
        return "FALSE";
      case RatingType.unknown:
        return "UNRATED";
    }
  }
}