import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// **INDUSTRIAL TAB BAR GLOBAL**
/// 
/// El componente [IndustrialTabBar] es el **único estándar visual obligatorio** 
/// para cualquier navegación por pestañas actual o futura dentro de VialSystems.
/// 
/// ### 🚨 REGLA GLOBAL DE USO OBLIGATORIO:
/// Debe utilizarse en:
/// * Nuevos módulos administrativos y dashboards futuros.
/// * Nuevos formularios operativos y submenús internos por secciones.
/// * Pantallas móviles, web y de escritorio.
/// * Navegación secundaria horizontal o selector de ventanas.
/// 
/// ### 🚫 PROHIBIDO:
/// * Usar `TabBar` estándar con estilos inline o colores hardcodeados.
/// * Usar texto negro sobre fondo oscuro o indicadores azules antiguos.
/// * Duplicar lógica visual o crear estilos individuales por pantalla.
/// 
/// ### 🎨 CRITERIO VISUAL (CAT & Trimble Inspired):
/// * **Sobre fondo oscuro (`onDarkBackground: true`)**:
///   - Activo: `AppColors.yellowIndustrial` (#F4B400)
///   - Inactivo: `Colors.white.withOpacity(0.72)`
/// * **Sobre fondo claro (`onDarkBackground: false`)**:
///   - Activo: `AppColors.darkGraphite` (#2B2B2B) con indicador `AppColors.yellowIndustrial`
///   - Inactivo: `AppColors.darkGraphite.withOpacity(0.65)`
/// * **Indicador Activo**: Grosor de 3.5px en Amarillo Industrial visible bajo luz solar directa.
class IndustrialTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<Widget> tabs;
  final bool isScrollable;
  final bool onDarkBackground;

  const IndustrialTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.onDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    // Definir colores estrictos según fondo oscuro o claro (CAT / Trimble ergonómico)
    final selectedColor = onDarkBackground 
        ? AppColors.yellowIndustrial 
        : AppColors.darkGraphite;
        
    final unselectedColor = onDarkBackground 
        ? Colors.white.withValues(alpha: 0.72) 
        : AppColors.darkGraphite.withValues(alpha: 0.65);

    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable,
      labelColor: selectedColor,
      unselectedLabelColor: unselectedColor,
      indicatorColor: AppColors.yellowIndustrial,
      indicatorWeight: 3.5, // Mínimo 3.5px de grosor visible bajo luz solar
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent, // Estilo limpio sin divisiones grises
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14.5,
        letterSpacing: 0.3,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48.0);
}
