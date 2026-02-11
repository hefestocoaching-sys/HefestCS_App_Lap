import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';

class ClientRepository {
  final LocalClientDataSource _local;
  final ClientRemoteDataSource _remote;
  final Map<String, Timer> _remotePushDebounce = {};
  final Map<String, Client> _pendingRemotePush = {};

  ClientRepository({
    required LocalClientDataSource local,
    required ClientRemoteDataSource remote,
  }) : _local = local,
       _remote = remote;

  // === Local operations with remote push ===
  Future<void> saveClient(Client client) async {
    // 1) Guardado local (fuente de verdad)
    await _local.saveClient(client);

    // 2) Push remoto inmediato (fire-and-forget)
    _pendingRemotePush[client.id] = client;
    _remotePushDebounce[client.id]?.cancel();
    _remotePushDebounce[client.id] = Timer(
      const Duration(milliseconds: 700),
      () {
        final latest = _pendingRemotePush.remove(client.id);
        if (latest == null) return;
        unawaited(_pushClientRemote(latest, deleted: false).catchError((_) {}));
      },
    );
  }

  Future<List<Client>> getClients() => _local.getAllClients();

  Future<Client?> getClientById(String id) => _local.fetchClient(id);

  Future<void> deleteClient(String id) async {
    // 1) Obtener cliente antes de eliminar (para push con deleted:true)
    final client = await _local.fetchClient(id);
    if (client == null) return;

    // 2) Eliminación local (soft-delete)
    await _local.deleteClient(id);

    // 3) Push remoto inmediato (marcar como deleted en Firestore)
    _remotePushDebounce[id]?.cancel();
    _pendingRemotePush.remove(id);
    unawaited(_pushClientRemote(client, deleted: true).catchError((_) {}));
  }

  // === Remote operations (preparados pero sin activar) ===
  Future<void> upsertRemoteClient({
    required String coachId,
    required Client client,
    required bool deleted,
  }) async {
    await _remote.upsertClient(
      coachId: coachId,
      client: client,
      deleted: deleted,
    );
  }

  Future<List<RemoteClientSnapshot>> fetchRemoteClients({
    required String coachId,
    DateTime? since,
  }) {
    return _remote.fetchClients(coachId: coachId, since: since);
  }

  /// Helper privado: push silencioso a Firestore (no rompe flujos locales)
  Future<void> _pushClientRemote(Client client, {required bool deleted}) async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (e, st) {
      logger.error('Failed to get current user', e, st);
      // Firebase no inicializado (p.ej. tests). La fuente de verdad es local.
      return;
    }
    if (user == null) return; // Sin usuario autenticado, no hay push

    try {
      await _remote.upsertClient(
        coachId: user.uid,
        client: client,
        deleted: deleted,
      );
    } catch (e) {
      // Ignorar error: Firestore es réplica, no fuente de verdad
      // El cambio ya está en SQLite (guardado localmente)
    }
  }
}
