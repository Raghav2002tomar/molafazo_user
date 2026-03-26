import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../model/store_model.dart';

class StoreCardWidget extends StatelessWidget {
  final StoreModel store;
  final VoidCallback onTap;

  const StoreCardWidget({
    super.key,
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// STORE IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: store.logo != null
                  ? Image.network(
                "${ApiService.ImagebaseUrl}/${ApiService.store_logo_URL}${store.logo}",
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 140,
                color: cs.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.storefront,
                    size: 40,
                    color: cs.primary,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// STORE NAME
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // const SizedBox(height: 4),

                  /// STORE TYPES (Retail / Online / etc)
                  SizedBox(
                    height: 20,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: store.types.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: 4),
                      itemBuilder: (context, i) {
                        final t = store.types[i];
                        final label = storeTypeMap[t] ?? '';

                        return _typeChip(label);
                      },
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// DELIVERY OPTIONS
                  SizedBox(
                    height: 24,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [

                          if (store.deliveryBySeller)
                            _serviceChip(
                              icon: Icons.delivery_dining,
                              label: "Home Delivery",
                              color: Colors.green,
                            ),

                          if (store.selfPickup)
                            _serviceChip(
                              icon: Icons.store_mall_directory,
                              label: "Self Pickup",
                              color: Colors.blue,
                            ),

                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  /// CITY
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store.city,
                          style: tt.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  /// WORKING HOURS
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store.workingHours,
                          style: tt.labelSmall
                              ?.copyWith(color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// STORE TYPE CHIP
  Widget _typeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// DELIVERY SERVICE CHIP
  Widget _serviceChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

const storeTypeMap = {
  '1': 'Retail',
  '2': 'Online',
  '3': 'Wholesale',
  '4': 'Offline',
};