import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hcs_app_lap/domain/entities/client.dart';
import './remote_client_datasource.dart';

class RemoteClientDataSourceImpl implements RemoteClientDataSource {
  final FirebaseFirestore _firestore;

  RemoteClientDataSourceImpl({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Client?> getClientById(String id) async {
    final doc = await _firestore.collection('clients').doc(id).get();
    if (doc.exists) {
      return Client.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<List<Client>> getAllClients() async {
    final snapshot = await _firestore.collection('clients').get();
    return snapshot.docs.map((doc) => Client.fromJson(doc.data())).toList();
  }

  @override
  Future<void> saveClient(Client client) async {
    final docRef = _firestore.collection('clients').doc(client.id);
    await docRef.set(client.toJson());
  }

  @override
  Future<void> deleteClient(String id) async {
    await _firestore.collection('clients').doc(id).delete();
  }

  @override
  Future<void> pushClient(Client client) {
    return saveClient(client);
  }

  @override
  Future<Client?> fetchClient(String id) {
    return getClientById(id);
  }
}
