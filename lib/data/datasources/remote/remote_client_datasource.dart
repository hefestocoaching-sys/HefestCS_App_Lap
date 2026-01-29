import '../../../domain/entities/client.dart';

abstract class RemoteClientDataSource {
  Future<void> saveClient(Client client);
  Future<Client?> getClientById(String id);
  Future<List<Client>> getAllClients();
  Future<void> deleteClient(String id);
  Future<void> pushClient(Client client);
  Future<Client?> fetchClient(String id);
}
