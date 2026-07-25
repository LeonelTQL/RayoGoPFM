import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(status.toUpperCase()), avatar: const Icon(Icons.local_shipping, size: 18));
  }
}
