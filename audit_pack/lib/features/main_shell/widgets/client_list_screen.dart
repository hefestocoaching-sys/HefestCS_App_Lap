import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/utils/theme.dart';
import 'package:hcs_app_lap/utils/widgets/glass_container.dart';
import 'package:hcs_app_lap/utils/widgets/hcs_input_decoration.dart';
import 'package:hcs_app_lap/utils/widgets/section_header.dart';
// Asumiendo que tienes un provider para la lista de clientes. Si no, esto es un mock estructural.
// import 'package:hcs_app_lap/features/main_shell/providers/client_list_provider.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Aquí deberías observar tu provider de lista de clientes real
    // final clientsAsync = ref.watch(clientListProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Directorio de Atletas"),
        backgroundColor: kAppBarColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {}, // Implementar ordenamiento
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showAddClientDialog(context),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.person_add),
        label: const Text("Nuevo Atleta"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de Búsqueda
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                decoration:
                    hcsDecoration(
                      context,
                      hintText: "Buscar por nombre...",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: kTextColorSecondary,
                      ),
                    ).copyWith(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                style: const TextStyle(color: kTextColor),
              ),
            ),
            const SizedBox(height: 24),

            // Lista (Mock visual hasta conectar provider)
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Mock
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassContainer(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: kPrimaryColor.withAlpha(51),
                          child: Text(
                            "A$index",
                            style: const TextStyle(color: kPrimaryColor),
                          ),
                        ),
                        title: Text(
                          "Atleta Ejemplo $index",
                          style: const TextStyle(
                            color: kTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          "Última actualización: Hoy",
                          style: TextStyle(
                            color: kTextColorSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: kTextColorSecondary,
                        ),
                        onTap: () {
                          // Navegar al Dashboard del cliente (Client Summary)
                          // ref.read(clientProvider.notifier).selectClient(id);
                          // Navigator.pushNamed(context, '/client-dashboard');
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClientDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: const SectionHeader(
          title: "NUEVO ATLETA",
          icon: Icons.person_add,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Ingresa el nombre completo del atleta para comenzar su expediente.",
              style: TextStyle(color: kTextColorSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: hcsDecoration(context, labelText: "Nombre Completo"),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              // Lógica de creación aquí
              Navigator.pop(context);
            },
            child: const Text("Crear Expediente"),
          ),
        ],
      ),
    );
  }
}
