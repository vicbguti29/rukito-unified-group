import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FrozenBackground extends StatelessWidget {
  final Widget child;

  const FrozenBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Color base sólido
        Container(color: AppColors.veryLightGray),
        
        // 2. Imagen de Patrón Estático (No se encoge al redimensionar)
        Positioned.fill(
          child: Opacity(
            opacity: 0.35, 
            child: FittedBox(
              fit: BoxFit.none, // IMPORTANTE: No escala la imagen para ajustarla, la recorta.
              alignment: Alignment.topLeft,
              child: Image.asset(
                'assets/images/pattern_bg.png',
                repeat: ImageRepeat.repeat,
                width: 3000, // Forzamos un tamaño gigante para cubrir cualquier monitor
                height: 2000,
                scale: 0.2, // Un 25% más pequeño que el gigante anterior (0.25)
              ),
            ),
          ),
        ),

        // 3. Gradiente sutil para profundidad
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.4,
              colors: [
                AppColors.veryLightGray.withOpacity(0.1), 
                AppColors.veryLightGray.withOpacity(0.6),
              ],
            ),
          ),
        ),

        // 4. Contenido
        child,
      ],
    );
  }
}