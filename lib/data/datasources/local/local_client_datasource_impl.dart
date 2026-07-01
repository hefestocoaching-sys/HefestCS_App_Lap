import 'package:hcs_app_lap/domain/entities/client.dart';
import 'package:hcs_app_lap/data/datasources/local/database_helper.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource.dart';

class LocalClientDataSourceImpl implements LocalClientDataSource {
  final DatabaseHelper dbHelper;

  LocalClientDataSourceImpl(this.dbHelper);

  @override
  Future<Client?> fetchClient(String id) {
    // Usamos el nombre correcto para obtener
    return dbHelper.getClientById(id);
  }

  @override
  Future<Client?> fetchClientIncludingDeleted(String id) {
    return dbHelper.getClientByIdIncludingDeleted(id);
  }

  @override
  Future<List<Client>> getAllClients() {
    return dbHelper.getAllClients();
  }

  @override
  Future<void> saveClient(Client client) {
    // CORRECCIÓN: Usamos 'upsertClient' que es el método que ya tienes en DatabaseHelper
    return dbHelper.upsertClient(client);
  }

  @override
  Future<ClientOutboxWrite> saveClientWithOutbox(Client client) {
    return dbHelper.upsertClientWithOutbox(client);
  }

  @override
  Future<void> deleteClient(String id) {
    // Usamos el borrado lógico
    return dbHelper.softDeleteClient(id);
  }

  @override
  Future<ClientOutboxWrite> deleteClientWithOutbox(Client client) {
    return dbHelper.softDeleteClientWithOutbox(client);
  }

  @override
  Future<List<Client>> getUnsyncedClients() {
    return dbHelper.getUnsyncedClients();
  }

  @override
  Future<List<Client>> getUnsyncedDeletedClients() {
    return dbHelper.getUnsyncedDeletedClients();
  }

  @override
  Future<void> markClientAsSynced(String id) {
    return dbHelper.markClientAsSynced(id);
  }
}
