import 'package:hcs_app_lap/domain/entities/client.dart';

class ClientOutboxWrite {
  ClientOutboxWrite({
    required this.persistedClient,
    required this.queueItemId,
    required this.operationId,
    required this.action,
  });

  final Client persistedClient;
  final String queueItemId;
  final String operationId;
  final String action;
}

abstract class LocalClientDataSource {
  Future<List<Client>> getAllClients();
  Future<Client?> fetchClient(String id);
  Future<Client?> fetchClientIncludingDeleted(String id);
  Future<void> saveClient(Client client);
  Future<ClientOutboxWrite> saveClientWithOutbox(Client client);
  Future<void> deleteClient(String id);
  Future<ClientOutboxWrite> deleteClientWithOutbox(Client client);
  Future<List<Client>> getUnsyncedClients();
  Future<List<Client>> getUnsyncedDeletedClients();
  Future<void> markClientAsSynced(String id);
}
