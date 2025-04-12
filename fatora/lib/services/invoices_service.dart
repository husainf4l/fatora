import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'clients_service.dart';
import 'products_service.dart';

class InvoicesService {
  static const String _invoicesKey = 'invoices_data';
  final Uuid _uuid = const Uuid();
  final ClientsService _clientsService = ClientsService();
  final ProductsService _productsService = ProductsService();

  // Get all invoices (with demo data if none exist)
  Future<List<Invoice>> getAllInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final invoicesJson = prefs.getString(_invoicesKey);

      if (invoicesJson != null) {
        final List<dynamic> decoded = jsonDecode(invoicesJson);
        return decoded.map((item) => Invoice.fromJson(item)).toList();
      } else {
        // Create demo invoices if none exist
        final demoInvoices = await _createDemoInvoices();
        await saveInvoices(demoInvoices);
        return demoInvoices;
      }
    } catch (e) {
      throw Exception('Failed to load invoices: ${e.toString()}');
    }
  }

  // Create a new invoice
  Future<Invoice> createInvoice({
    required String clientId,
    required DateTime issueDate,
    required DateTime dueDate,
    required List<InvoiceLineItem> items,
    double? taxRate,
    String? notes,
  }) async {
    try {
      final client = await _clientsService.getClientById(clientId);
      if (client == null) {
        throw Exception('Client not found');
      }

      final invoices = await getAllInvoices();

      // Calculate invoice number (simple implementation, can be improved)
      final invoiceNumber = 'INV-${DateTime.now().year}-${invoices.length + 1}';

      // Calculate subtotal, tax and total
      final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
      final tax = taxRate != null ? subtotal * (taxRate / 100) : null;
      final total = tax != null ? subtotal + tax : subtotal;

      final newInvoice = Invoice(
        id: _uuid.v4(),
        invoiceNumber: invoiceNumber,
        issueDate: issueDate,
        dueDate: dueDate,
        status: InvoiceStatus.draft,
        client: client,
        items: items,
        subtotal: subtotal,
        tax: tax,
        total: total,
        notes: notes,
        createdAt: DateTime.now(),
      );

      invoices.add(newInvoice);
      await saveInvoices(invoices);

      return newInvoice;
    } catch (e) {
      throw Exception('Failed to create invoice: ${e.toString()}');
    }
  }

  // Update an existing invoice
  Future<Invoice> updateInvoice(Invoice invoice) async {
    try {
      final invoices = await getAllInvoices();

      final index = invoices.indexWhere((i) => i.id == invoice.id);
      if (index == -1) {
        throw Exception('Invoice not found');
      }

      invoices[index] = invoice;
      await saveInvoices(invoices);

      return invoice;
    } catch (e) {
      throw Exception('Failed to update invoice: ${e.toString()}');
    }
  }

  // Update invoice status
  Future<Invoice> updateInvoiceStatus(
    String invoiceId,
    InvoiceStatus status,
  ) async {
    try {
      final invoices = await getAllInvoices();

      final index = invoices.indexWhere((i) => i.id == invoiceId);
      if (index == -1) {
        throw Exception('Invoice not found');
      }

      final updatedInvoice = invoices[index].copyWith(
        status: status,
        paidAt: status == InvoiceStatus.paid ? DateTime.now() : null,
      );

      invoices[index] = updatedInvoice;
      await saveInvoices(invoices);

      return updatedInvoice;
    } catch (e) {
      throw Exception('Failed to update invoice status: ${e.toString()}');
    }
  }

  // Delete an invoice
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      final invoices = await getAllInvoices();

      final newList =
          invoices.where((invoice) => invoice.id != invoiceId).toList();
      await saveInvoices(newList);
    } catch (e) {
      throw Exception('Failed to delete invoice: ${e.toString()}');
    }
  }

  // Get an invoice by ID
  Future<Invoice?> getInvoiceById(String id) async {
    try {
      final invoices = await getAllInvoices();
      return invoices.firstWhere((invoice) => invoice.id == id);
    } catch (e) {
      return null;
    }
  }

  // Save invoices to SharedPreferences
  Future<void> saveInvoices(List<Invoice> invoices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedInvoices = jsonEncode(
        invoices.map((i) => i.toJson()).toList(),
      );
      await prefs.setString(_invoicesKey, encodedInvoices);
    } catch (e) {
      throw Exception('Failed to save invoices: ${e.toString()}');
    }
  }

  // Create demo invoices
  Future<List<Invoice>> _createDemoInvoices() async {
    try {
      final clients = await _clientsService.getAllClients();
      final products = await _productsService.getAllProducts();

      if (clients.isEmpty || products.isEmpty) {
        return [];
      }

      final invoices = <Invoice>[];

      // Invoice 1 - Paid
      final invoice1Items = [
        InvoiceLineItem(
          id: _uuid.v4(),
          description: products[0].name,
          quantity: 1,
          unitPrice: products[0].price,
          total: products[0].price,
          product: products[0],
        ),
        InvoiceLineItem(
          id: _uuid.v4(),
          description: products[2].name,
          quantity: 2,
          unitPrice: products[2].price,
          total: products[2].price * 2,
          product: products[2],
        ),
      ];

      final subtotal1 = invoice1Items.fold(
        0.0,
        (sum, item) => sum + item.total,
      );
      final tax1 = subtotal1 * 0.15; // 15% VAT

      invoices.add(
        Invoice(
          id: _uuid.v4(),
          invoiceNumber: 'INV-2025-001',
          issueDate: DateTime.now().subtract(const Duration(days: 15)),
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
          status: InvoiceStatus.paid,
          client: clients[0],
          items: invoice1Items,
          subtotal: subtotal1,
          tax: tax1,
          total: subtotal1 + tax1,
          notes: 'تم الدفع بالتحويل المصرفي',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          paidAt: DateTime.now().subtract(const Duration(days: 7)),
          currency: 'SAR',
        ),
      );

      // Invoice 2 - Sent but unpaid
      final invoice2Items = [
        InvoiceLineItem(
          id: _uuid.v4(),
          description: products[1].name,
          quantity: 1,
          unitPrice: products[1].price,
          total: products[1].price,
          product: products[1],
        ),
      ];

      final subtotal2 = invoice2Items.fold(
        0.0,
        (sum, item) => sum + item.total,
      );
      final tax2 = subtotal2 * 0.15; // 15% VAT

      invoices.add(
        Invoice(
          id: _uuid.v4(),
          invoiceNumber: 'INV-2025-002',
          issueDate: DateTime.now().subtract(const Duration(days: 7)),
          dueDate: DateTime.now().add(const Duration(days: 14)),
          status: InvoiceStatus.sent,
          client: clients[1],
          items: invoice2Items,
          subtotal: subtotal2,
          tax: tax2,
          total: subtotal2 + tax2,
          notes: 'يرجى السداد خلال 14 يوم',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          currency: 'SAR',
        ),
      );

      // Invoice 3 - Draft
      final invoice3Items = [
        InvoiceLineItem(
          id: _uuid.v4(),
          description: products[3].name,
          quantity: 3,
          unitPrice: products[3].price,
          total: products[3].price * 3,
          product: products[3],
        ),
        InvoiceLineItem(
          id: _uuid.v4(),
          description: products[4].name,
          quantity: 1,
          unitPrice: products[4].price,
          total: products[4].price,
          product: products[4],
        ),
      ];

      final subtotal3 = invoice3Items.fold(
        0.0,
        (sum, item) => sum + item.total,
      );

      invoices.add(
        Invoice(
          id: _uuid.v4(),
          invoiceNumber: 'INV-2025-003',
          issueDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 30)),
          status: InvoiceStatus.draft,
          client: clients[2],
          items: invoice3Items,
          subtotal: subtotal3,
          total: subtotal3,
          createdAt: DateTime.now(),
          currency: 'SAR',
        ),
      );

      // Invoice 4 - Overdue
      final invoice4Items = [
        InvoiceLineItem(
          id: _uuid.v4(),
          description: products[2].name,
          quantity: 4,
          unitPrice: products[2].price,
          total: products[2].price * 4,
          product: products[2],
        ),
      ];

      final subtotal4 = invoice4Items.fold(
        0.0,
        (sum, item) => sum + item.total,
      );
      final tax4 = subtotal4 * 0.15; // 15% VAT

      invoices.add(
        Invoice(
          id: _uuid.v4(),
          invoiceNumber: 'INV-2025-004',
          issueDate: DateTime.now().subtract(const Duration(days: 45)),
          dueDate: DateTime.now().subtract(const Duration(days: 15)),
          status: InvoiceStatus.overdue,
          client: clients[3],
          items: invoice4Items,
          subtotal: subtotal4,
          tax: tax4,
          total: subtotal4 + tax4,
          notes: 'متأخرة - إرسال تذكير',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          currency: 'SAR',
        ),
      );

      return invoices;
    } catch (e) {
      throw Exception('Failed to create demo invoices: ${e.toString()}');
    }
  }

  // Get statistics for dashboard
  Future<Map<String, dynamic>> getInvoiceStatistics() async {
    try {
      final invoices = await getAllInvoices();

      double totalPaid = 0;
      double totalUnpaid = 0;
      double totalOverdue = 0;
      int paidCount = 0;
      int unpaidCount = 0;
      int overdueCount = 0;

      for (final invoice in invoices) {
        if (invoice.status == InvoiceStatus.paid) {
          totalPaid += invoice.total;
          paidCount++;
        } else if (invoice.status == InvoiceStatus.overdue) {
          totalOverdue += invoice.total;
          overdueCount++;
        } else if (invoice.status == InvoiceStatus.sent) {
          totalUnpaid += invoice.total;
          unpaidCount++;
        }
      }

      return {
        'totalPaid': totalPaid,
        'totalUnpaid': totalUnpaid,
        'totalOverdue': totalOverdue,
        'paidCount': paidCount,
        'unpaidCount': unpaidCount,
        'overdueCount': overdueCount,
        'totalInvoices': invoices.length,
      };
    } catch (e) {
      throw Exception('Failed to get invoice statistics: ${e.toString()}');
    }
  }
}
