import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/material.dart';
import 'add_address.dart';
import 'controller/address_services.dart';
import 'model/address_model.dart';

class AddressListScreen extends StatefulWidget {
  final bool isSelectionMode;
  final AddressModel? selectedAddress;

  const AddressListScreen({
    super.key,
    this.isSelectionMode = false,
    this.selectedAddress,
  });

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  late Future<List<AddressModel>> _future;
  AddressModel? _selectedAddress;
  int _listKey = 0; // incrementing this forces FutureBuilder to re-run

  @override
  void initState() {
    super.initState();
    _future = AddressService.fetchAddresses();
    _selectedAddress = widget.selectedAddress;
  }

  void _refresh() {
    setState(() {
      _listKey++;                                      // forces FutureBuilder rebuild
      _future = AddressService.fetchAddresses();
    });
  }

  /// Navigate to AddAddressScreen and refresh list when a new address is saved
  Future<void> _goToAddAddress() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );
    if (result == true) _refresh();                   // only refresh on actual save
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _appBar(cs, tt, isDark),
      body: FutureBuilder<List<AddressModel>>(
        key: ValueKey(_listKey),                       // forces rebuild on refresh
        future: _future,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          if (snapshot.hasError) {
            return _errorState(cs, tt, snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _emptyState(cs, tt, isDark);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
            children: [
              ...snapshot.data!.map((a) => _addressCard(a, cs, tt, isDark)),
              const SizedBox(height: 12),
              _addNewButton(cs, tt, isDark),
            ],
          );
        },
      ),
      bottomNavigationBar:
      widget.isSelectionMode && _selectedAddress != null
          ? _confirmBar(cs, tt, isDark)
          : null,
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────
  AppBar _appBar(ColorScheme cs, TextTheme tt, bool isDark) => AppBar(
    backgroundColor: cs.surface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    leading: Padding(
      padding: const EdgeInsets.all(8),
      child: _CircleAction(
        icon: Icons.keyboard_double_arrow_left_outlined,
        bg: isDark ? Colors.white : Colors.black,
        fg: isDark ? Colors.black : Colors.white,
        onTap: () => Navigator.pop(context),
      ),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isSelectionMode ? context.tr('txt_select_address') : context.tr('txt_saved_address'),
          style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        Text(
          widget.isSelectionMode
              ? context.tr('txt_choose_deliver_location')
              : context.tr('txt_manage_deliver_location'),
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    ),
  );

  // ── ADDRESS CARD ──────────────────────────────────────────────────────────
  Widget _addressCard(
      AddressModel address, ColorScheme cs, TextTheme tt, bool isDark) {
    final isSelected = _selectedAddress?.id == address.id;

    return GestureDetector(
      onTap: widget.isSelectionMode
          ? () => setState(() => _selectedAddress = address)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Row: type badge + selection + menu ─────────────────────
            Row(children: [

              // Selection radio
              if (widget.isSelectionMode) ...[
                Container(
                  width: 22, height: 22,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 13,
                      color: isDark ? Colors.black : Colors.white)
                      : null,
                ),
              ],

              // Type icon badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_typeIcon(address.name), size: 12,
                      color: isDark ? Colors.black : Colors.white),
                  const SizedBox(width: 4),
                  Text(address.name,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.black : Colors.white)),
                ]),
              ),

              // Default badge
              if (address.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star_rounded, size: 10,
                        color: Colors.green.shade700),
                    const SizedBox(width: 3),
                    Text(context.tr('txt_default'),
                        style: TextStyle(fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],

              const Spacer(),

              // // Menu (non-selection mode)
              // if (!widget.isSelectionMode)
              //   PopupMenuButton(
              //     icon: Container(
              //       width: 32, height: 32,
              //       decoration: BoxDecoration(
              //         color: isDark ? Colors.white10 : Colors.grey.shade100,
              //         borderRadius: BorderRadius.circular(8),
              //         border: Border.all(color: Colors.grey.shade300),
              //       ),
              //       child: Icon(Icons.more_horiz_rounded,
              //           size: 18, color: cs.onSurface),
              //     ),
              //     shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12)),
              //     itemBuilder: (_) => [
              //       PopupMenuItem(
              //         child: Row(children: [
              //           Icon(Icons.edit_outlined, size: 18, color: cs.onSurface),
              //           const SizedBox(width: 10),
              //           Text("Edit", style: tt.bodyMedium),
              //         ]),
              //         onTap: () {},
              //       ),
              //       PopupMenuItem(
              //         child: Row(children: [
              //           Icon(Icons.delete_outline, size: 18, color: cs.error),
              //           const SizedBox(width: 10),
              //           Text("Delete",
              //               style: tt.bodyMedium?.copyWith(color: cs.error)),
              //         ]),
              //         onTap: () {},
              //       ),
              //     ],
              //   ),
            ]),

            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),

            // ── Name + Mobile ──────────────────────────────────────────
            Row(children: [
              _CircleAction(
                icon: Icons.person_outline_rounded,
                bg: isDark ? Colors.white : Colors.black,
                fg: isDark ? Colors.black : Colors.white,
                onTap: () {},
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.fullName,
                      style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700, color: cs.onSurface)),
                  Text(address.mobile,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              )),
            ]),

            const SizedBox(height: 10),

            // ── Address ────────────────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _CircleAction(
                icon: Icons.location_on_outlined,
                bg: isDark ? Colors.white : Colors.black,
                fg: isDark ? Colors.black : Colors.white,
                onTap: () {},
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(
                "${address.address}, ${address.city}",
                style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant, height: 1.5),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  // ── ADD NEW BUTTON ────────────────────────────────────────────────────────
  Widget _addNewButton(ColorScheme cs, TextTheme tt, bool isDark) =>
      InkWell(
        onTap: _goToAddAddress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white : Colors.black,
              width: 1.5,
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_rounded, size: 16,
                  color: isDark ? Colors.black : Colors.white),
            ),
            const SizedBox(width: 10),
            Text(context.tr('txt_add_new_address'),
                style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
          ]),
        ),
      );

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _emptyState(ColorScheme cs, TextTheme tt, bool isDark) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(Icons.location_off_outlined,
                  size: 48, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(context.tr('txt_no_address'),
                style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(context.tr('add_your_first_delivery'),
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 28),
            SizedBox(
              width: 200, height: 50,
              child: ElevatedButton.icon(
                onPressed: _goToAddAddress,
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('txt_add_address')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      );

  // ── ERROR STATE ───────────────────────────────────────────────────────────
  Widget _errorState(ColorScheme cs, TextTheme tt, String error) =>
      Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline_rounded, size: 56, color: cs.error),
          const SizedBox(height: 12),
          Text(context.tr('txt_failed_to_load'),
              style: tt.titleMedium?.copyWith(color: cs.error)),
          const SizedBox(height: 6),
          Text(error,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextButton(onPressed: _refresh,
              child: Text(context.tr('txt_try_again'))),
        ]),
      );

  // ── CONFIRM BAR ───────────────────────────────────────────────────────────
  Widget _confirmBar(ColorScheme cs, TextTheme tt, bool isDark) =>
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07),
                blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedAddress),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(context.tr('txt_confirm_address'),
                  style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.black : Colors.white)),
            ),
          ),
        ),
      );

  // ── HELPERS ───────────────────────────────────────────────────────────────
  IconData _typeIcon(String name) {
    switch (name.toLowerCase()) {
      case "home":   return Icons.home_rounded;
      case "office": return Icons.business_center_rounded;
      case "shop":   return Icons.storefront_rounded;
      default:       return Icons.location_on_rounded;
    }
  }
}

// ── SHARED CIRCLE ACTION ──────────────────────────────────────────────────────
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40, width: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1),
                  blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(icon, color: fg, size: 18),
        ),
      ),
    );
  }
}