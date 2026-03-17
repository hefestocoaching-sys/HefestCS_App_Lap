
import 'package:hcs_app_lap/domain/entities/client.dart';

abstract class LocalClientDataSource {
  Future<List<Client>> getAllClients();
  Future<Client?> fetchClient(String id);
  Future<void> saveClient(Client client);
  Future<void> deleteClient(String id);
  Future<List<Client>> getUnsyncedClients();
  Future<void> markClientAsSynced(String id);
}
