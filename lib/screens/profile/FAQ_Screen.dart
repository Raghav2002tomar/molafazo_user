// lib/screens/faq/faq_screen.dart

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
        title: 'Orders & Shipping',
        items: [
          FAQItem(
            question: 'How can I track my order?',
            answer: 'You can track your order by going to "My Orders" section in your profile. Click on the specific order to see real-time tracking information. You will also receive email updates with tracking links once your order is shipped.',
          ),
          FAQItem(
            question: 'How long does delivery take?',
            answer: 'Delivery typically takes 2-3 business days for metro cities and 3-5 business days for other locations. International shipping may take 7-14 business days. You can check estimated delivery time on the product page.',
          ),
          FAQItem(
            question: 'What are the shipping charges?',
            answer: 'Shipping is free on orders above 499 c. For orders below 499 c. , a nominal shipping fee of 40 c. applies. Some products may have special shipping charges which will be clearly mentioned on the product page.',
          ),
          FAQItem(
            question: 'Can I change my delivery address after placing an order?',
            answer: 'Address can be changed within 2 hours of placing the order, provided the order hasn\'t been processed yet. Go to "My Orders", select the order and click on "Change Address" option.',
          ),
        ],
      ),
      FAQCategory(
        title: 'Returns & Refunds',
        items: [
          FAQItem(
            question: 'What is your return policy?',
            answer: 'We offer 7-day easy returns on most products. Items must be unused, in original packaging with all tags attached. Some products like innerwear, personal care items are non-returnable due to hygiene reasons.',
          ),
          FAQItem(
            question: 'How do I initiate a return?',
            answer: 'Go to "My Orders", select the item you want to return and click on "Return/Replace". Choose the reason for return and submit. You\'ll receive a confirmation email with return instructions.',
          ),
          FAQItem(
            question: 'When will I get my refund?',
            answer: 'Refunds are processed within 5-7 business days after we receive and verify the returned item. The amount will be credited to your original payment method. UPI payments may reflect faster.',
          ),
          FAQItem(
            question: 'Do you offer exchange?',
            answer: 'Yes, we offer exchange for size or color issues. You can request exchange through the "Return/Replace" option in your orders. If the exchange isn\'t possible, you can opt for a refund.',
          ),
        ],
      ),
      FAQCategory(
        title: 'Payments',
        items: [
          FAQItem(
            question: 'What payment methods do you accept?',
            answer: 'We accept all major payment methods including Credit/Debit Cards, UPI (Google Pay, PhonePe, Paytm), Net Banking, and Cash on Delivery. EMI options are also available on select banks.',
          ),
          FAQItem(
            question: 'Is Cash on Delivery available?',
            answer: 'Yes, Cash on Delivery is available for orders up to 50,000 c. A small convenience fee of 25 c. may apply for COD orders. COD is subject to address verification.',
          ),
          FAQItem(
            question: 'Is it safe to save my card details?',
            answer: 'Absolutely! We use industry-standard encryption and are PCI-DSS compliant. Your card details are stored securely and never shared with any third parties.',
          ),
          FAQItem(
            question: 'Why was my payment deducted but order not confirmed?',
            answer: 'Sometimes due to technical glitches, payment may be deducted but order not confirmed. Don\'t worry, the amount will be auto-refunded within 3-4 business days. If not, contact our support.',
          ),
        ],
      ),
      FAQCategory(
        title: 'Account & Security',
        items: [
          FAQItem(
            question: 'How do I reset my password?',
            answer: 'Click on "Forgot Password" on the login page. Enter your registered email, you\'ll receive a password reset link. Follow the instructions to set a new password.',
          ),
          FAQItem(
            question: 'Can I have multiple addresses?',
            answer: 'Yes, you can save multiple addresses in your account. Go to Profile > Shipping Address to add, edit or delete addresses. You can select your preferred address at checkout.',
          ),
          FAQItem(
            question: 'How do I delete my account?',
            answer: 'To delete your account, please contact our customer support. Note that account deletion is permanent and all your data will be removed as per our privacy policy.',
          ),
          FAQItem(
            question: 'Is my personal information secure?',
            answer: 'We take data security seriously. All personal information is encrypted and we never share your data with third parties without your consent. Read our Privacy Policy for more details.',
          ),
        ],
      ),
      FAQCategory(
        title: 'Products & Availability',
        items: [
          FAQItem(
            question: 'Are the products authentic?',
            answer: 'Yes, all products sold on our platform are 100% authentic and sourced directly from brands or authorized distributors. We have strict quality checks in place.',
          ),
          FAQItem(
            question: 'What if an item is out of stock?',
            answer: 'You can enable "Notify Me" on out-of-stock products. We\'ll send you an email/SMS as soon as the item is back in stock.',
          ),
          FAQItem(
            question: 'Do you provide warranty on products?',
            answer: 'Warranty varies by product category. Electronics typically come with manufacturer warranty. Check the product description for specific warranty information.',
          ),
          FAQItem(
            question: 'Can I pre-order upcoming products?',
            answer: 'Yes, select products offer pre-order options. You can pay a small amount to pre-order and the remaining amount when the product launches.',
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
          'FAQs',
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
                          hintText: 'Search FAQs...',
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
                '${category.items.length} questions',
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
                    'No results found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching with different keywords',
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