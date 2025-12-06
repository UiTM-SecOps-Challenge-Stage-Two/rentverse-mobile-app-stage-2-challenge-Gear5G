import 'package:flutter/material.dart';
import 'package:rentverse/features/property/domain/entity/list_property_entity.dart';
import 'package:rentverse/role/tenant/presentation/widget/detail_property/accessorise_widget.dart';
import 'package:rentverse/role/tenant/presentation/widget/detail_property/image_tile.dart';

class DetailProperty extends StatelessWidget {
  const DetailProperty({super.key, required this.property});

  final PropertyEntity property;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Property Detail'),
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageTile(images: property.images),
              AccessoriseWidget(attributes: property.attributes),
              const SizedBox(height: 16),
              Text(
                property.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${property.city}, ${property.country}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                property.description,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              // Additional property details can be placed here (price, amenities, etc.)
            ],
          ),
        ),
      ),
    );
  }
}
