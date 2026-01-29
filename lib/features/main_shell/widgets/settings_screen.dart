import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/client_list_screen.dart';
import 'package:hcs_app_lap/features/main_shell/widgets/inactive_clients_screen.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/glass_container.dart';
import 'package:hcs_app_lap/utils/widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Ajustes / Sistema"),
        backgroundColor: kAppBarColor,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          const SectionHeader(
            title: "ADMINISTRACIÓN",
            icon: Icons.admin_panel_settings_rounded,
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            context,
            title: "Directorio de Atletas",
            subtitle: "Crear nuevos perfiles, buscar o eliminar expedientes.",
            icon: Icons.people_alt_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClientListScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            context,
            title: "Clientes Desactivados",
            subtitle:
                "Reactivar o eliminar permanentemente clientes desactivados.",
            icon: Icons.person_off_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InactiveClientsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            context,
            title: "Cerrar sesión",
            subtitle: "Finaliza la sesión actual y vuelve a iniciar.",
            icon: Icons.logout,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          // Aquí podrás agregar más ajustes en el futuro (ej. Unidades, Tema, Cuenta)
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kPrimaryColor.withAlpha(38),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kPrimaryColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: kTextColorSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: kTextColorSecondary),
        onTap: onTap,
      ),
    );
  }
}
