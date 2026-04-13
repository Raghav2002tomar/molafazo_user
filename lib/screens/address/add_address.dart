import 'dart:convert';
import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../../services/auth_service.dart';
import '../bottombar/CitySearchScreen.dart';
import '../bottombar/controller/CityService.dart';
import 'controller/address_services.dart';

class AddAddressScreen extends StatefulWidget {
  final String? profileName;
  final String? profileMobile;

  const AddAddressScreen({
    super.key,
    this.profileName,
    this.profileMobile,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final fullNameCtrl    = TextEditingController();
  final mobileCtrl      = TextEditingController();
  final addressCtrl     = TextEditingController();
  final cityCtrl        = TextEditingController();



  bool isSaving     = false;
  bool isDefault    = false;
  int? selectedCityId;

  int? mainCityId;
  String? mainCityName;
  bool _namePreFilled   = false;
  bool _mobilePreFilled = false;
  bool _isSomeoneElse   = false;



  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    if (widget.profileName != null && widget.profileName!.isNotEmpty) {
      fullNameCtrl.text = widget.profileName!;
      _namePreFilled = true;
    }
    if (widget.profileMobile != null && widget.profileMobile!.isNotEmpty) {
      mobileCtrl.text = widget.profileMobile!;
      _mobilePreFilled = true;
    }
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final mobile = await AuthStorage.getMobile();
    final name   = await AuthStorage.getName();
    if (!mounted) return;
    setState(() {
      if (mobile != null && mobile.isNotEmpty) {
        mobileCtrl.text   = mobile;
        _mobilePreFilled  = true;
      }
      if (name != null && name.isNotEmpty) {
        fullNameCtrl.text = name;
        _namePreFilled    = true;
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final c in [
      fullNameCtrl,
      mobileCtrl,
      addressCtrl,
      cityCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }



  // ── SAVE ──────────────────────────────────────────────────────────────────
  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await AddressService.saveAddress(data: {
        "name": "Address",
        "full_name": fullNameCtrl.text,
        "mobile": mobileCtrl.text,
        "address": addressCtrl.text,
        "city": cityCtrl.text,
        "is_default": isDefault ? 1 : 0,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  bool get _nameIsLocked         => _namePreFilled && !_isSomeoneElse;
  bool get _mobileIsLocked       => _mobilePreFilled && !_isSomeoneElse;
  bool get _showSomeoneElseOption => (_namePreFilled || _mobilePreFilled) && !_isSomeoneElse;

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _appBar(cs, tt, isDark),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [

                /// CONTACT INFORMATION
                _card(cs, isDark, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                        context.tr('txt_contact_info'),
                        Icons.person_outline_rounded,
                        cs,
                        tt,
                        isDark
                    ),
                    const SizedBox(height: 12),

                    _lockedOrField(
                      ctrl: fullNameCtrl,
                      label: context.tr('txt_full_name'),
                      icon: Icons.badge_outlined,
                      isLocked: _nameIsLocked,
                      cs: cs,
                      tt: tt,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 10),

                    _lockedOrField(
                      ctrl: mobileCtrl,
                      label: context.tr('txt_mobile_number'),
                      icon: Icons.phone_outlined,
                      isLocked: _mobileIsLocked,
                      keyboard: TextInputType.phone,
                      cs: cs,
                      tt: tt,
                      isDark: isDark,
                    ),

                    if (_showSomeoneElseOption) ...[
                      const SizedBox(height: 12),
                      _someoneElseBtn(cs, tt, isDark),
                    ],

                    if (_isSomeoneElse) ...[
                      const SizedBox(height: 8),
                      _someoneElseBanner(cs, tt, isDark),
                    ],
                  ],
                )),

                const SizedBox(height: 16),

                /// ADDRESS DETAILS
                _card(cs, isDark, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _sectionTitle(
                        context.tr('txt_address_details'),
                        Icons.home_work_outlined,
                        cs,
                        tt,
                        isDark
                    ),

                    const SizedBox(height: 12),

                    _inputField(
                      ctrl: addressCtrl,
                      label: context.tr('txt_full_address'),
                      icon: Icons.place_outlined,
                      maxLines: 2,
                      cs: cs,
                      tt: tt,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 10),

                    _cityField(context, cs, tt, isDark),
                  ],
                )),

                const SizedBox(height: 16),

                /// DEFAULT TOGGLE
                _card(cs, isDark, child: _defaultToggle(cs, tt, isDark)),

              ],            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(cs, tt, isDark),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────
  AppBar _appBar(ColorScheme cs, TextTheme tt, bool isDark) => AppBar(
    backgroundColor: cs.surface,
    foregroundColor: cs.onSurface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    leading: Padding(
      padding: const EdgeInsets.all(8),
      child: _CircleAction(
        icon: Icons.arrow_back_ios_new_rounded,
        bg: isDark ? Colors.white : Colors.black,
        fg: isDark ? Colors.black : Colors.white,
        onTap: () => Navigator.pop(context),
      ),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('txt_add_new_address'),
            style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700, color: cs.onSurface)),
        Text(context.tr('txt_fill_in_your_delivery_details'),
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    ),
  );

  Widget _cityField(
      BuildContext context,
      ColorScheme cs,
      TextTheme tt,
      bool isDark,
      ) {
    return InkWell(
      onTap: () async {

        /// SAVE CURRENT MAIN CITY
        final mainCity = await CityStorage.getCity();
        mainCityId = mainCity["id"];
        mainCityName = mainCity["name"];

        /// OPEN CITY SEARCH
        final city = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CitySearchScreen(type: "address" ),
          ),
        );

        if (city != null) {

          setState(() {
            selectedCityId = city["id"];
            cityCtrl.text = city["name"];
          });

          if (mainCityId != null && mainCityName != null) {
            await CityStorage.saveCity(mainCityId!, mainCityName!);
          } else {
            await CityStorage.removeCity();
          }
        }
      },
      child: AbsorbPointer(
        child: _inputField(
          ctrl: cityCtrl,
          label: context.tr('txt_city'),
          icon: Icons.location_city_outlined,
          cs: cs,
          tt: tt,
          isDark: isDark,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return context.tr('hint_select_city');
            }
            return null;
          },
        ),
      ),
    );
  }

  // ── CARD ──────────────────────────────────────────────────────────────────
  Widget _card(ColorScheme cs, bool isDark, {required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  // ── SECTION TITLE ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon, ColorScheme cs,
      TextTheme tt, bool isDark) =>
      Row(children: [
        _CircleAction(
          icon: icon,
          bg: isDark ? Colors.white : Colors.black,
          fg: isDark ? Colors.black : Colors.white,
          onTap: () {},
        ),
        const SizedBox(width: 10),
        Text(title,
            style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: cs.onSurface)),
      ]);

  // ── SEARCH FIELD ──────────────────────────────────────────────────────────


  Widget _searchLoader(ColorScheme cs) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
      const SizedBox(width: 8),
      Text(context.tr('txt_searching'),
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
    ]),
  );


  // ── LOCATION BUTTON ───────────────────────────────────────────────────────

  // ── LOCKED / EDITABLE ─────────────────────────────────────────────────────
  Widget _lockedOrField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required bool isLocked,
    required ColorScheme cs,
    required TextTheme tt,
    required bool isDark,
    TextInputType? keyboard,
  }) {
    if (isLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: isDark ? Colors.black : Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(ctrl.text, style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: cs.onSurface)),
            ],
          )),
          Icon(Icons.lock_outline_rounded, size: 15, color: cs.onSurfaceVariant),
        ]),
      );
    }
    return _inputField(ctrl: ctrl, label: label, icon: icon,
        keyboard: keyboard, cs: cs, tt: tt, isDark: isDark);
  }

  // ── SOMEONE ELSE ──────────────────────────────────────────────────────────
  Widget _someoneElseBtn(ColorScheme cs, TextTheme tt, bool isDark) =>
      InkWell(
        onTap: () => setState(() => _isSomeoneElse = true),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.people_alt_outlined, size: 15,
                  color: isDark ? Colors.black : Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('txt_deliver_to_else'),
                    style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700, color: cs.onSurface)),
                Text(context.tr('txt_recipient_change'),
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            )),
            Icon(Icons.arrow_forward_ios, size: 14, color: cs.onSurfaceVariant),
          ]),
        ),
      );

  Widget _someoneElseBanner(ColorScheme cs, TextTheme tt, bool isDark) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, size: 15, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(context.tr('txt_edit_name_mobile'),
              style: tt.labelSmall?.copyWith(
                  color: cs.onSurface, fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: () => setState(() { _isSomeoneElse = false; _loadFromStorage(); }),
            child: Icon(Icons.close_rounded, size: 15, color: cs.onSurfaceVariant),
          ),
        ]),
      );

  // ── TYPE CHIPS ────────────────────────────────────────────────────────────

  // ── DEFAULT TOGGLE ────────────────────────────────────────────────────────
  Widget _defaultToggle(ColorScheme cs, TextTheme tt, bool isDark) =>
      Row(children: [
        _CircleAction(
          icon: isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
          bg: isDark ? Colors.white : Colors.black,
          fg: isDark ? Colors.black : Colors.white,
          onTap: () => setState(() => isDefault = !isDefault),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('txt_save_as_default'),
                style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
            Text(context.tr('txt_automatically_used'),
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        )),
        Switch.adaptive(
          value: isDefault,
          onChanged: (v) => setState(() => isDefault = v),
          activeColor: isDark ? Colors.white : Colors.black,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]);

  // ── BOTTOM BAR ────────────────────────────────────────────────────────────
  Widget _bottomBar(ColorScheme cs, TextTheme tt, bool isDark) =>
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isSaving ? null : save,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: isSaving
                ? SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2,
                    color: isDark ? Colors.black : Colors.white))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_outline_rounded, size: 18),
              const SizedBox(width: 8),
              Text(context.tr('txt_save_address'), style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.black : Colors.white)),
            ]),
          ),
        ),
      );

  // ── INPUT FIELD ───────────────────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required ColorScheme cs,
    required TextTheme tt,
    required bool isDark,
    TextInputType? keyboard,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,   // ← custom validator support
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
        // Use custom validator if provided, otherwise fall back to "Required"
        validator: validator ?? (v) => (v == null || v.isEmpty) ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          prefixIcon: Icon(icon, size: 18, color: cs.onSurfaceVariant),
          filled: true,
          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.white : Colors.black, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.error)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.error, width: 1.5)),
          errorStyle: TextStyle(fontSize: 11, color: cs.error),
        ),
      );
}

// ── SHARED CIRCLE ACTION ─────────────────────────────────────────────────────
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