import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hcs_app_lap/core/utils/app_logger.dart';
import 'package:hcs_app_lap/data/datasources/local/database_helper.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource_impl.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';

class BackgroundSyncService {
  static final BackgroundSyncService instance = BackgroundSyncService._();

  final FirebaseAuth _auth;
  final LocalClientDataSource _localRepository;
  final ClientRemoteDataSource _remoteRepository;

  bool _isSyncing = false;

  BackgroundSyncService._({
    FirebaseAuth? auth,
    LocalClientDataSource? localRepository,
    ClientRemoteDataSource? remoteRepository,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _localRepository =
           localRepository ??
           LocalClientDataSourceImpl(DatabaseHelper.instance),
       _remoteRepository =
           remoteRepository ??
           ClientFirestoreDataSource(FirebaseFirestore.instance);

  Future<void> trySyncPendingData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final pending = await _localRepository.getUnsyncedClients();
      final pendingDeleted = await _localRepository.getUnsyncedDeletedClients();

      for (final client in pending) {
        await _syncClient(coachId: user.uid, client: client, deleted: false);
      }
      for (final client in pendingDeleted) {
        await _syncClient(coachId: user.uid, client: client, deleted: true);
      }
    } catch (e, st) {
      logger.warning('Background sync skipped', {
        'error': e.toString(),
        'stackTrace': st.toString(),
      });
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncClient({
    required String coachId,
    required Client client,
    required bool deleted,
  }) async {
    try {
      await _remoteRepository.upsertClient(
        coachId: coachId,
        client: client,
        deleted: deleted,
      );

      await _localRepository.markClientAsSynced(client.id);
    } catch (e, st) {
      logger.warning('Background client sync failed', {
        'clientId': client.id,
        'deleted': deleted,
        'error': e.toString(),
        'stackTrace': st.toString(),
      });
    }
  }
}
