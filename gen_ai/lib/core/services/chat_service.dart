import 'package:flutter/material.dart';

import 'api_check.dart';


class CategorizePage extends StatefulWidget {
  const CategorizePage({Key? key}) : super(key: key);

  @override
  State<CategorizePage> createState() => _CategorizePageState();
}

class _CategorizePageState extends State<CategorizePage> {
  final TextEditingController _controller = TextEditingController();
  String _statusMessage = "";
  String _fullResponse = "";
  bool _loading = false;

  /// Your clean formatter
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
      return "⚠️ I've analyzed your query but couldn't provide a complete fact-check assessment. Please check the full report below.";
    }
  }

  Future<void> _categorize() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _statusMessage = "";
      _fullResponse = "";
    });

    try {
      final result = await ApiService.categorizeText(text);
      setState(() {
        _statusMessage = _generateResponseText(result);
        _fullResponse = result.toString(); // full raw JSON
      });
    } catch (e) {
      setState(() {
        _statusMessage = "❌ Error: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Misinformation Checker")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Enter text to check",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _categorize,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Check"),
            ),
            const SizedBox(height: 20),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _fullResponse,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
