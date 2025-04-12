import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client_model.dart';
import '../utils/constants.dart';
import 'package:uuid/uuid.dart';

class ClientsService {
  static const String _clientsKey = 'clients_data';
  final Uuid _uuid = const Uuid();

  // Get all clients (with demo data if none exist)
  Future<List<Client>> getAllClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = prefs.getString(_clientsKey);

      if (clientsJson != null) {
        final List<dynamic> decoded = jsonDecode(clientsJson);
        return decoded.map((item) => Client.fromJson(item)).toList();
      } else {
        // Create demo clients if none exist
        final demoClients = _createDemoClients();
        await saveClients(demoClients);
        return demoClients;
      }
    } catch (e) {
      throw Exception('Failed to load clients: ${e.toString()}');
    }
  }

  // Create a new client
  Future<Client> createClient({
    required String name,
    required String email,
    String? phone,
    String? address,
    String? taxNumber,
    String? notes,
  }) async {
    try {
      final clients = await getAllClients();

      final newClient = Client(
        id: _uuid.v4(),
        name: name,
        email: email,
        phone: phone,
        address: address,
        taxNumber: taxNumber,
        notes: notes,
        createdAt: DateTime.now(),
      );

      clients.add(newClient);
      await saveClients(clients);

      return newClient;
    } catch (e) {
      throw Exception('Failed to create client: ${e.toString()}');
    }
  }

  // Update an existing client
  Future<Client> updateClient(Client client) async {
    try {
      final clients = await getAllClients();

      final index = clients.indexWhere((c) => c.id == client.id);
      if (index == -1) {
        throw Exception('Client not found');
      }

      clients[index] = client;
      await saveClients(clients);

      return client;
    } catch (e) {
      throw Exception('Failed to update client: ${e.toString()}');
    }
  }

  // Delete a client
  Future<void> deleteClient(String clientId) async {
    try {
      final clients = await getAllClients();

      final newList = clients.where((client) => client.id != clientId).toList();
      await saveClients(newList);
    } catch (e) {
      throw Exception('Failed to delete client: ${e.toString()}');
    }
  }

  // Get a client by ID
  Future<Client?> getClientById(String id) async {
    try {
      final clients = await getAllClients();
      return clients.firstWhere((client) => client.id == id);
    } catch (e) {
      return null;
    }
  }

  // Save clients to SharedPreferences
  Future<void> saveClients(List<Client> clients) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedClients = jsonEncode(
        clients.map((c) => c.toJson()).toList(),
      );
      await prefs.setString(_clientsKey, encodedClients);
    } catch (e) {
      throw Exception('Failed to save clients: ${e.toString()}');
    }
  }

  // Create demo clients
  List<Client> _createDemoClients() {
    return [
      Client(
        id: _uuid.v4(),
        name: 'شركة الأفق الرقمية',
        email: 'info@horizon-digital.com',
        phone: '0512345678',
        address: 'الرياض، المملكة العربية السعودية',
        taxNumber: '300123456700003',
        notes: 'عميل مميز منذ 2020',
        createdAt: DateTime.now(),
      ),
      Client(
        id: _uuid.v4(),
        name: 'مؤسسة المستقبل للتقنية',
        email: 'contact@future-tech.sa',
        phone: '0598765432',
        address: 'جدة، المملكة العربية السعودية',
        taxNumber: '300765432100008',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Client(
        id: _uuid.v4(),
        name: 'مطاعم الذواق',
        email: 'orders@aldhawaq.com',
        phone: '0555123456',
        address: 'الدمام، المملكة العربية السعودية',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Client(
        id: _uuid.v4(),
        name: 'مكتبة المعرفة',
        email: 'books@almarefa.com',
        phone: '0567890123',
        address: 'المدينة المنورة، المملكة العربية السعودية',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      Client(
        id: _uuid.v4(),
        name: 'محمد العلي',
        email: 'malali@example.com',
        phone: '0501234567',
        address: 'الخبر، المملكة العربية السعودية',
        notes: 'عميل فردي',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }
}
