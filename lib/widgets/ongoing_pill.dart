import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';

class OngoingNotificationData {
  final String key;
  final String packageName;
  final String title;
  final String content;
  final Uint8List? iconBytes;
  final List<String> actions;

  const OngoingNotificationData({
    required this.key,
    required this.packageName,
    required this.title,
    required this.content,
    this.iconBytes,
    this.actions = const [],
  });
}

class OngoingPill extends StatelessWidget {
  final OngoingNotificationData data;
  final VoidCallback onTap;
  final ValueChanged<int> onActionTap;

  const OngoingPill({
    super.key,
    required this.data,
    required this.onTap,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.holoSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.holoCyan.withValues(alpha: 0.3),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),

              // 1. App Icon / Indicator
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.holoCyan.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: data.iconBytes != null
                    ? ClipOval(child: Image.memory(data.iconBytes!, fit: BoxFit.cover))
                    : const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.holoCyan,
                        size: 16,
                      ),
              ),

              const SizedBox(width: 12),

              // 2. Info Text (Title + Live State)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.holoCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      data.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Tactical Action Buttons (Stop, Pause, Add 1m, etc.)
              if (data.actions.isNotEmpty) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(data.actions.take(2).length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: AppColors.holoCyan.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onActionTap(index);
                        },
                        child: Text(
                          data.actions[index].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ] else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}