// lib/screens/faq/faq_screen.dart

import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/material.dart';

// Model classes (keep them in a separate file as shown below)
class FAQCategory {
  final String title;
  final List<FAQItem> items;

  FAQCategory({
    required this.title,
    required this.items,
  });
}

class FAQItem {
  final String question;
  final String answer;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  List<FAQCategory> _categories = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  void _loadFAQs() {
    _categories = [
      FAQCategory(
        title: context.tr('txt_order_shipping'),
        items: [
          FAQItem(
            question: context.tr('faq_track_order_q'),
            answer: context.tr('faq_track_order_a'),
          ),
          FAQItem(
            question: context.tr('faq_delivery_time_q'),
            answer: context.tr('faq_delivery_time_a'),
          ),
          FAQItem(
            question: context.tr('faq_shipping_charges_q'),
            answer: context.tr('faq_shipping_charges_a'),
          ),
          FAQItem(
            question: context.tr('faq_change_address_q'),
            answer: context.tr('faq_change_address_a'),
          ),
        ],
      ),
      FAQCategory(
        title: context.tr('faq_returns'),
        items: [
            FAQItem(
              question: context.tr('faq_return_policy_q'),
              answer: context.tr('faq_return_policy_a'),
            ),
            FAQItem(
              question: context.tr('faq_initiate_return_q'),
              answer: context.tr('faq_initiate_return_a'),
            ),
            FAQItem(
              question: context.tr('faq_refund_time_q'),
              answer: context.tr('faq_refund_time_a'),
            ),
            FAQItem(
              question: context.tr('faq_exchange_q'),
              answer: context.tr('faq_exchange_a'),
            ),
          ],
      ),
      FAQCategory(
        title: context.tr('faq_payments'),
        items: [
          FAQItem(
            question: context.tr('faq_payment_methods_q'),
            answer: context.tr('faq_payment_methods_a'),
          ),
          FAQItem(
            question: context.tr('faq_cod_q'),
            answer: context.tr('faq_cod_a'),
          ),
          FAQItem(
            question: context.tr('faq_card_safety_q'),
            answer: context.tr('faq_card_safety_a'),
          ),
          FAQItem(
            question: context.tr('faq_payment_failed_q'),
            answer: context.tr('faq_payment_failed_a'),
          ),
        ],
      ),
      FAQCategory(
        title: context.tr('faq_account'),
        items: [
          FAQItem(
            question: context.tr('faq_reset_password_q'),
            answer: context.tr('faq_reset_password_a'),
          ),
          FAQItem(
            question: context.tr('faq_multiple_address_q'),
            answer: context.tr('faq_multiple_address_a'),
          ),
          FAQItem(
            question: context.tr('faq_delete_account_q'),
            answer: context.tr('faq_delete_account_a'),
          ),
          FAQItem(
            question: context.tr('faq_data_security_q'),
            answer: context.tr('faq_data_security_a'),
          ),
        ],
      ),
      FAQCategory(
        title: context.tr('faq_products'),
        items: [
          FAQItem(
            question: context.tr('faq_authentic_products_q'),
            answer: context.tr('faq_authentic_products_a'),
          ),
          FAQItem(
            question: context.tr('faq_out_of_stock_q'),
            answer: context.tr('faq_out_of_stock_a'),
          ),
          FAQItem(
            question: context.tr('faq_warranty_q'),
            answer: context.tr('faq_warranty_a'),
          ),
          FAQItem(
            question: context.tr('faq_preorder_q'),
            answer: context.tr('faq_preorder_a'),
          ),
        ],
      ),
    ];
  }

  List<FAQItem> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _categories.expand((c) => c.items).toList();
    }
    return _categories
        .expand((c) => c.items)
        .where((item) =>
    item.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.answer.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Map<String, List<FAQItem>> get _groupedFilteredItems {
    if (_searchQuery.isEmpty) {
      return {for (var c in _categories) c.title: c.items};
    }
    final result = <String, List<FAQItem>>{};
    for (var category in _categories) {
      final matched = category.items
          .where((item) =>
      item.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.answer.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      if (matched.isNotEmpty) {
        result[category.title] = matched;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(25),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.black : Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          context.tr('faq_title'),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Search Bar - Styled like your profile card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: context.tr('faq_search_hint'),
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),

                          // ✅ Remove background color
                          filled: false,
                          fillColor: Colors.transparent,

                          // ✅ Remove all borders
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,

                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: cs.onSurfaceVariant, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // FAQ Content
              _searchQuery.isEmpty
                  ? _buildCategoryList(cs, tt, isDark)
                  : _buildSearchResults(cs, tt, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(ColorScheme cs, TextTheme tt, bool isDark) {
    return Column(
      children: _categories.map((category) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              childrenPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.help_outline,
                  color: isDark ? Colors.black : Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                category.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              subtitle: Text(
                '${category.items.length} ${context.tr('faq_questions')}',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                Icons.keyboard_arrow_down,
                color: cs.onSurfaceVariant,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: category.items.map((item) {
                      return _buildFAQItem(item, cs, tt, isDark);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults(ColorScheme cs, TextTheme tt, bool isDark) {
    final grouped = _groupedFilteredItems;

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('faq_no_results'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('faq_try_different'),
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
            ...entry.value.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildFAQItem(item, cs, tt, isDark, showBorder: false),
            )),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFAQItem(FAQItem item, ColorScheme cs, TextTheme tt, bool isDark, {bool showBorder = true}) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
          top: BorderSide(color: cs.outlineVariant, width: 1),
        )
            : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          title: Text(
            item.question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              item.isExpanded ? Icons.remove : Icons.add,
              color: isDark ? Colors.black : Colors.white,
              size: 14,
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              item.isExpanded = expanded;
            });
          },
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: Text(
                item.answer,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative: Quick FAQ Tiles (Optional)
class QuickFAQScreen extends StatelessWidget {
  const QuickFAQScreen({super.key});

  final List<Map<String, String>> quickFAQs = const [
    {
      'question': 'Track my order?',
      'answer': 'Go to My Orders and click on the order to see tracking.',
      'icon': '📍',
    },
    {
      'question': 'Return policy?',
      'answer': '7-day easy returns on most products.',
      'icon': '🔄',
    },
    {
      'question': 'Payment methods?',
      'answer': 'Cards, UPI, NetBanking, and COD accepted.',
      'icon': '💳',
    },
    {
      'question': 'Delivery time?',
      'answer': '2-3 business days for metro cities.',
      'icon': '🚚',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(25),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.black : Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Quick Help',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: quickFAQs.length,
          itemBuilder: (context, index) {
            final faq = quickFAQs[index];
            return InkWell(
              onTap: () {
                _showAnswerDialog(context, faq['question']!, faq['answer']!);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      faq['icon']!,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        faq['question']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAnswerDialog(BuildContext context, String question, String answer) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: isDark ? Colors.black : Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}