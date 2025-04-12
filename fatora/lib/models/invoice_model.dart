import 'client_model.dart';
import 'product_model.dart';

class InvoiceLineItem {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double? taxRate;
  final double total;
  final Product? product;

  InvoiceLineItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.taxRate,
    required this.total,
    this.product,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      taxRate: json['taxRate'] != null ? (json['taxRate']).toDouble() : null,
      total: (json['total'] ?? 0).toDouble(),
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
      'total': total,
      'product': product?.toJson(),
    };
  }
}

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final InvoiceStatus status;
  final Client client;
  final List<InvoiceLineItem> items;
  final double subtotal;
  final double? tax;
  final double total;
  final String? notes;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? currency; // Default to SAR for Saudi Riyal

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.client,
    required this.items,
    required this.subtotal,
    this.tax,
    required this.total,
    this.notes,
    required this.createdAt,
    this.paidAt,
    this.currency = 'SAR',
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      issueDate: DateTime.parse(json['issueDate']),
      dueDate: DateTime.parse(json['dueDate']),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString() == 'InvoiceStatus.${json['status']}',
        orElse: () => InvoiceStatus.draft,
      ),
      client: Client.fromJson(json['client']),
      items:
          (json['items'] as List)
              .map((item) => InvoiceLineItem.fromJson(item))
              .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: json['tax'] != null ? (json['tax']).toDouble() : null,
      total: (json['total'] ?? 0).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      currency: json['currency'] ?? 'SAR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'client': client.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'currency': currency,
    };
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    InvoiceStatus? status,
    Client? client,
    List<InvoiceLineItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? notes,
    DateTime? createdAt,
    DateTime? paidAt,
    String? currency,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      client: client ?? this.client,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      currency: currency ?? this.currency,
    );
  }

  // Utility methods
  bool get isPaid => status == InvoiceStatus.paid;
  bool get isOverdue =>
      status != InvoiceStatus.paid &&
      status != InvoiceStatus.cancelled &&
      DateTime.now().isAfter(dueDate);
}
