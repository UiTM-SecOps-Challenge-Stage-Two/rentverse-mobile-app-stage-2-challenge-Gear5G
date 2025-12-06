import 'package:flutter/material.dart';

/// Reusable app bar used across tenant screens.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String displayName;
  final Color backgroundColor;
  final double height;

  const CustomAppBar({
    super.key,
    required this.displayName,
    this.backgroundColor = Colors.transparent,
    this.height = 60,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      toolbarHeight: height,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selamat Datang',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none,
                color: Colors.black87,
                size: 28,
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
