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
    final Color alertColor = AppColors.fromHex(alert.colorHex);

    return GestureDetector(
      onTap: () {
        if (!alert.isRead) {
          context.read<AlertProvider>().markAsRead(alert.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Fondo siempre blanco
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200, // Borde sutil siempre igual
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Barra indicadora izquierda
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: alertColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: alertColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            alert.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert.title,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: alert.isRead ? FontWeight.w700 : FontWeight.w900,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Badge de Severidad
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: alertColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: alertColor.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      alert.severityLabel,
                                      style: TextStyle(
                                        color: alertColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                alert.description,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade600,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(height: 1, color: Colors.grey.shade100),
                    const SizedBox(height: 12),

                    // Footer: Metadatos + Canales + Costo
                    Row(
                      children: [
                        _buildMetaTag(Icons.grid_view_rounded, alert.sensorId, Colors.blueGrey),
                        const SizedBox(width: 16),
                        _buildMetaTag(Icons.access_time_rounded, alert.formattedTime, Colors.blueGrey),
                        
                        const Spacer(),

                        // Iconos de Canales con Tooltip
                        if (alert.channels.isNotEmpty) ...[
                          Row(
                            children: alert.channels.map((channel) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: _buildChannelIcon(channel),
                              );
                            }).toList(),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Costo
                        if (alert.estimatedCost != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.attach_money, size: 14, color: Colors.red.shade700),
                                Text(
                                  alert.estimatedCost!.toStringAsFixed(0),
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Indicador de "No Leído"
              if (!alert.isRead)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.info.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaTag(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChannelIcon(String channel) {
    IconData icon;
    Color color;
    String tooltip;

    switch (channel.toUpperCase()) {
      case 'PUSH':
        icon = Icons.notifications_active;
        color = AppColors.info;
        tooltip = "Notificación Push enviada al dispositivo";
        break;
      case 'EMAIL':
        icon = Icons.email;
        color = Colors.indigo;
        tooltip = "Correo electrónico de reporte enviado";
        break;
      case 'SMS':
        icon = Icons.sms;
        color = Colors.orange;
        tooltip = "Mensaje de texto (SMS) urgente enviado";
        break;
      default:
        icon = Icons.send;
        color = Colors.grey;
        tooltip = "Notificación enviada vía $channel";
    }

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
