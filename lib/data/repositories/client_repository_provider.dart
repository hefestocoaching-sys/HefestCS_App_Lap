import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hcs_app_lap/data/datasources/local/database_helper.dart';
import 'package:hcs_app_lap/data/datasources/local/local_client_datasource_impl.dart';
import 'package:hcs_app_lap/data/datasources/remote/client_firestore_datasource.dart';
import 'package:hcs_app_lap/data/repositories/client_repository.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final local = LocalClientDataSourceImpl(DatabaseHelper.instance);
  final remote = ClientFirestoreDataSource(FirebaseFirestore.instance);
  return ClientRepository(local: local, remote: remote);
});
