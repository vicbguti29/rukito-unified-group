import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../providers/alert_provider.dart';
import '../theme/app_colors.dart';

class AlertItemWidget extends StatelessWidget {
  final Alert alert;

  const AlertItemWidget({
    Key? key,
    required this.alert,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!alert.isRead) {
          context.read<AlertProvider>().markAsRead(alert.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.fromHex(alert.colorHex),
              width: 4,
            ),
          ),
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Contenido principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título con emoji
                    Row(
                      children: [
                        Text(
                          alert.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Tiempo y datos técnicos
                    Text(
                      alert.formattedTime,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),

                    // Descripción
                    Text(
                      alert.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Información adicional si existe
                    if (alert.affectedContent != null ||
                        alert.estimatedCost != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            if (alert.affectedContent != null) ...[
                              Text(
                                'Afecta: ${alert.affectedContent}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (alert.estimatedCost != null)
                                const SizedBox(width: 16),
                            ],
                            if (alert.estimatedCost != null)
                              Text(
                                'Costo: \$${alert.estimatedCost?.toStringAsFixed(0) ?? '0'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.fromHex(alert.colorHex),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Badge de prioridad y estado
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fromHex(alert.colorHex),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      alert.priorityLabel,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!alert.isRead)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
