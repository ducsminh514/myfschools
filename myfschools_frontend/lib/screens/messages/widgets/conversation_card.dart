import 'package:flutter/material.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/messages_controller.dart';

class ConversationCard extends StatelessWidget {
  final ConversationItem item;
  final VoidCallback onTap;

  const ConversationCard({super.key, required this.item, required this.onTap});

  Color get _avatarColor {
    switch (item.type) {
      case 'teacher': return AppColors.navyMid;
      case 'admin':   return AppColors.orange;
      case 'system':  return AppColors.green;
      default:        return AppColors.navyMid;
    }
  }

  String get _initials {
    final parts = item.name.split(' ');
    if (parts.length >= 2) return '${parts.last[0]}${parts[parts.length - 2][0]}';
    return item.name[0];
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Avatar + online dot ──
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _avatarColor.withOpacity(0.15),
                    child: Text(
                      _initials,
                      style: TextStyle(
                        color: _avatarColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (item.isOnline)
                    Positioned(
                      bottom: 1, right: 1,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // ── Nội dung ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên + giờ
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.unread > 0 ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: item.unread > 0 ? AppColors.orange : AppColors.textLight,
                            fontWeight: item.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Role
                    Text(
                      item.role,
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),

                    const SizedBox(height: 4),

                    // Preview + badge unread
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.lastMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: item.unread > 0 ? AppColors.textPrimary : AppColors.textSub,
                              fontWeight: item.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.unread > 0)
                          Container(
                            width: 18, height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.unread}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
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
      ),
    );
  }
}