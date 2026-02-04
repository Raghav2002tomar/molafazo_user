import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller/address_services.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final fullNameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pinCtrl = TextEditingController();

  bool isDefault = false;
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await AddressService.saveAddress(
        data: {
          "name": nameCtrl.text.trim(),
          "full_name": fullNameCtrl.text.trim(),
          "mobile": mobileCtrl.text.trim(),
          "address": addressCtrl.text.trim(),
          "city": cityCtrl.text.trim(),
          "state": stateCtrl.text.trim(),
          "pincode": pinCtrl.text.trim(),
          "is_default": isDefault ? 1 : 0,
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Address"),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              label: "Address Name",
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            _field(
              label: "Full Name",
              controller: fullNameCtrl,
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            _field(
              label: "Mobile Number",
              controller: mobileCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.length != 10) {
                  return "Enter valid 10-digit mobile";
                }
                return null;
              },
            ),
            _field(
              label: "Address",
              controller: addressCtrl,
              maxLines: 2,
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            _field(
              label: "City",
              controller: cityCtrl,
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            _field(
              label: "State",
              controller: stateCtrl,
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            _field(
              label: "Pincode",
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.length != 6) {
                  return "Enter valid 6-digit pincode";
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: isDefault,
              title: const Text("Make this default address"),
              onChanged: (v) => setState(() => isDefault = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text("Save Address"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) {
      return "This field is required";
    }
    return null;
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
