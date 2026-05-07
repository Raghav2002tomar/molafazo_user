import 'package:ecom/extensions/context_extension.dart';
import 'package:flutter/material.dart';

class DeliveryFilterScreen extends StatefulWidget {
  final String? initialDeliveryType;
  final int? initialTimeValue;
  final String? initialTimeUnit;
  final Function(Map<String, dynamic>)? onApply;
  final VoidCallback? onClose;

  const DeliveryFilterScreen({
    super.key,
    this.initialDeliveryType,
    this.initialTimeValue,
    this.initialTimeUnit,
    this.onApply,
    this.onClose,
  });

  @override
  State<DeliveryFilterScreen> createState() => _DeliveryFilterScreenState();
}

class _DeliveryFilterScreenState extends State<DeliveryFilterScreen> {
  String selectedDeliveryType = 'courier';
  String selectedTime = '3_hours';

  final List<String> timeOptions = [
    '3_hours',
    '6_hours',
    '9_hours',
    '12_hours',
    '1_day',
  ];

  @override
  void initState() {
    super.initState();

    selectedDeliveryType = widget.initialDeliveryType ?? 'courier';

    if (widget.initialTimeUnit == 'day') {
      selectedTime = '1_day';
    } else if (widget.initialTimeValue != null) {
      selectedTime = '${widget.initialTimeValue}_hours';
    }
  }

  int get deliveryTimeValue => int.parse(selectedTime.split('_').first);

  String get deliveryTimeUnit => selectedTime.split('_').last;

  String getSelectedTimeText() {
    if (selectedTime == '1_day') return context.tr('txt_up_to_1_day');
    if (selectedTime == '3_hours') return context.tr('txt_up_to_3_hours');
    if (selectedTime == '6_hours') return context.tr('txt_up_to_6_hours');
    if (selectedTime == '9_hours') return context.tr('txt_up_to_9_hours');
    return context.tr('txt_up_to_12_hours');
  }

  void applyFilter() {
    widget.onApply?.call({
      "delivery_type": selectedDeliveryType,
      "delivery_time_value": deliveryTimeValue,
      "delivery_time_unit": deliveryTimeUnit,
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = timeOptions.indexOf(selectedTime).toDouble();

    return Container(
      height: 190,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: widget.onClose,
                child: const Icon(Icons.close, size: 30, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('txt_filters'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              _typeChip(
                title: context.tr('txt_delivery_door'),
                type: 'courier',
              ),
              const SizedBox(width: 16),
              _typeChip(
                title: context.tr('txt_delivery_taxi'),
                type: 'taxi',
              ),
            ],
          ),

          const SizedBox(height: 12),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.black,
              inactiveTrackColor: Colors.black,
              thumbColor: const Color(0xff00C96B),
              overlayColor: const Color(0xff00C96B).withOpacity(0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: selectedIndex < 0 ? 0 : selectedIndex,
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: (value) {
                setState(() {
                  selectedTime = timeOptions[value.round()];
                });
              },
            ),
          ),

          Row(
            children: [
              const Spacer(),
              Text(
                getSelectedTimeText(),
                style: const TextStyle(fontSize: 17, color: Colors.black),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: applyFilter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    context.tr('txt_apply_filter'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip({
    required String title,
    required String type,
  }) {
    final selected = selectedDeliveryType == type;

    return InkWell(
      onTap: () {
        setState(() {
          selectedDeliveryType = type;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff00C96B) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}