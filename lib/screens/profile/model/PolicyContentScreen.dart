import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../services/api_service.dart';

class PolicyContentScreen extends StatefulWidget {
  final String title;
  final String endpoint;

  const PolicyContentScreen({
    super.key,
    required this.title,
    required this.endpoint,
  });

  @override
  State<PolicyContentScreen> createState() => _PolicyContentScreenState();
}

class _PolicyContentScreenState extends State<PolicyContentScreen> {
  bool _isLoading = true;
  String _htmlTitle = '';
  String _htmlContent = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get(endpoint: widget.endpoint);

      print("API RESPONSE TYPE: ${response.runtimeType}");
      print("API RESPONSE: $response");

      Map<String, dynamic> res;

      if (response is String) {
        res = jsonDecode(response) as Map<String, dynamic>;
      } else if (response is Map<String, dynamic>) {
        res = response;
      } else if (response is Map) {
        res = Map<String, dynamic>.from(response);
      } else {
        throw Exception("Unexpected response format");
      }

      final success = res["success"] == true;
      final data = res["data"];

      if (success && data != null && data is Map) {
        setState(() {
          _htmlTitle = data["title"]?.toString() ?? '';
          _htmlContent = data["content"]?.toString() ?? '';
          _isLoading = false;
        });

        print("TITLE: $_htmlTitle");
        print("CONTENT: $_htmlContent");
      } else {
        setState(() {
          _error = res["message"]?.toString() ?? "No data found";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("LOAD ERROR: $e");
      setState(() {
        _error = "Failed to load data: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_htmlTitle.trim().isNotEmpty)
                Html(
                  data: _htmlTitle,
                  style: {
                    "html": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      color: theme.colorScheme.onSurface,
                    ),
                    "h1": Style(
                      fontSize: FontSize(24),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(bottom: 12),
                    ),
                    "h2": Style(
                      fontSize: FontSize(22),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(bottom: 12),
                    ),
                    "h3": Style(
                      fontSize: FontSize(20),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(bottom: 12),
                    ),
                    "p": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(18),
                      fontWeight: FontWeight.w600,
                    ),
                  },
                ),
              if (_htmlTitle.trim().isNotEmpty)
                const SizedBox(height: 16),
              if (_htmlContent.trim().isNotEmpty)
                Html(
                  data: _htmlContent,
                  style: {
                    "html": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(15),
                      lineHeight: const LineHeight(1.6),
                      color: theme.colorScheme.onSurface,
                    ),
                    "p": Style(
                      margin: Margins.only(bottom: 14),
                    ),
                    "h1": Style(
                      fontSize: FontSize(22),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(bottom: 12, top: 10),
                    ),
                    "h2": Style(
                      fontSize: FontSize(20),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(bottom: 12, top: 10),
                    ),
                    "h3": Style(
                      fontSize: FontSize(18),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(bottom: 12, top: 10),
                    ),
                    "strong": Style(
                      fontWeight: FontWeight.bold,
                    ),
                  },
                ),
              if (_htmlTitle.trim().isEmpty &&
                  _htmlContent.trim().isEmpty)
                const Text("No content available"),
            ],
          ),
        ),
      ),
    );
  }
}