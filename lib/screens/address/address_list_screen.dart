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

  @override
  void initState() {
    super.initState();
    _future = AddressService.fetchAddresses();
    _selectedAddress = widget.selectedAddress;
  }

  void _refresh() {
    setState(() {
      _future = AddressService.fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: _CircleAction(
            icon: Icons.keyboard_double_arrow_left_outlined,
            bg: isDark ? Colors.white : Colors.black,
            fg: isDark ? Colors.black : Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.isSelectionMode ? "Select Address" : "Saved Addresses",
          style: tt.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<AddressModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: cs.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: cs.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading addresses',
                    style: tt.titleMedium?.copyWith(color: cs.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context, cs, tt);
          }

          final addresses = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...addresses.map((address) => _addressCard(address, cs, tt)),
              const SizedBox(height: 16),
              _addNewButton(cs, tt),
            ],
          );
        },
      ),
      bottomNavigationBar: widget.isSelectionMode && _selectedAddress != null
          ? _buildConfirmButton(context, cs, tt, isDark)
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.location_off_outlined,
              size: 60,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Addresses Found',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first delivery address',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAddressScreen()),
              );
              _refresh();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard(AddressModel address, ColorScheme cs, TextTheme tt) {
    final isSelected = _selectedAddress?.id == address.id;

    return GestureDetector(
      onTap: widget.isSelectionMode
          ? () {
        setState(() {
          _selectedAddress = address;
        });
      }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withOpacity(0.3)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.05),
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
                if (widget.isSelectionMode)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? cs.primary : cs.outlineVariant,
                        width: 2,
                      ),
                      color: isSelected ? cs.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                        : null,
                  ),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        address.name,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Default",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!widget.isSelectionMode)
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20, color: cs.onSurface),
                            const SizedBox(width: 8),
                            const Text('Edit'),
                          ],
                        ),
                        onTap: () {
                          // Handle edit
                        },
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: cs.error),
                            const SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: cs.error)),
                          ],
                        ),
                        onTap: () {
                          // Handle delete
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.fullName,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              address.mobile,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${address.address}, ${address.city}, ${address.state} - ${address.pincode}",
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addNewButton(ColorScheme cs, TextTheme tt) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAddressScreen()),
          );
          _refresh();
        },
        icon: Icon(Icons.add, color: cs.primary),
        label: Text(
          "Add New Address",
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(
      BuildContext context,
      ColorScheme cs,
      TextTheme tt,
      bool isDark,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _selectedAddress);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Confirm Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }
}