import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/backlog_provider.dart';
import '../../../domain/entities/game_list.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BacklogProvider>(
        builder: (context, provider, _) {
          final lists = provider.gameLists;

          if (lists.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              return _buildListCard(context, lists[index], provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateListDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Lista'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 100,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 24),
            Text(
              'Sin colecciones',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Crea listas personalizadas para organizar tus juegos.\nPor ejemplo: "RPGs favoritos", "Para jugar en verano"...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateListDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear Primera Lista'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, GameList list, BacklogProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/collections/${list.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.collections_bookmark,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (list.description != null && list.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        list.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 6),
                    FutureBuilder<int>(
                      future: provider.getListItemCount(list.id),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text(
                          '$count ${count == 1 ? 'juego' : 'juegos'}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showCreateListDialog(context, existingList: list);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, list);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
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

  void _showCreateListDialog(BuildContext context, {GameList? existingList}) {
    final nameController = TextEditingController(text: existingList?.name ?? '');
    final descController = TextEditingController(text: existingList?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingList == null ? 'Nueva Colección' : 'Editar Colección'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: RPGs favoritos',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Describe tu colección...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final provider = context.read<BacklogProvider>();
              bool success;

              if (existingList == null) {
                success = await provider.createGameList(
                  name: name,
                  description: descController.text.trim().isNotEmpty
                      ? descController.text.trim()
                      : null,
                );
              } else {
                success = await provider.updateGameList(
                  listId: existingList.id,
                  name: name,
                  description: descController.text.trim().isNotEmpty
                      ? descController.text.trim()
                      : null,
                );
              }

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(existingList == null
                        ? 'Colección creada'
                        : 'Colección actualizada'),
                  ),
                );
              }
            },
            child: Text(existingList == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, GameList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar colección?'),
        content: Text('Se eliminará "${list.name}" y todos sus juegos asociados serán desvinculados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<BacklogProvider>();
              final success = await provider.deleteGameList(list.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Colección eliminada')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
