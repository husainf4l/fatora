import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../services/invoices_service.dart';
import '../../theme/app_colors.dart';
import 'invoice_detail_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final InvoicesService _invoicesService = InvoicesService();
  List<Invoice> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invoices = await _invoicesService.getAllInvoices();
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الفواتير: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteInvoice(String invoiceId) async {
    try {
      await _invoicesService.deleteInvoice(invoiceId);
      _loadInvoices();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف الفاتورة بنجاح')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حذف الفاتورة: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDeleteConfirmation(Invoice invoice) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل أنت متأكد من حذف الفاتورة "${invoice.invoiceNumber}"؟',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteInvoice(invoice.id);
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateInvoiceStatus(
    Invoice invoice,
    InvoiceStatus newStatus,
  ) async {
    try {
      await _invoicesService.updateInvoiceStatus(invoice.id, newStatus);
      _loadInvoices();

      String statusText = '';
      switch (newStatus) {
        case InvoiceStatus.draft:
          statusText = 'مسودة';
          break;
        case InvoiceStatus.sent:
          statusText = 'مرسلة';
          break;
        case InvoiceStatus.paid:
          statusText = 'مدفوعة';
          break;
        case InvoiceStatus.overdue:
          statusText = 'متأخرة';
          break;
        case InvoiceStatus.cancelled:
          statusText = 'ملغية';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة الفاتورة إلى $statusText')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث حالة الفاتورة: ${e.toString()}')),
      );
    }
  }

  void _navigateToInvoiceDetail(Invoice? invoice) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoice: invoice),
      ),
    );

    if (result == true) {
      _loadInvoices();
    }
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.black54;
    }
  }

  String _getStatusText(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return 'مسودة';
      case InvoiceStatus.sent:
        return 'مرسلة';
      case InvoiceStatus.paid:
        return 'مدفوعة';
      case InvoiceStatus.overdue:
        return 'متأخرة';
      case InvoiceStatus.cancelled:
        return 'ملغية';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _invoices.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد فواتير',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _navigateToInvoiceDetail(null),
                      child: const Text('إنشاء فاتورة جديدة'),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'عدد الفواتير: ${_invoices.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _invoices[index];
                          final dateFormat = DateFormat('yyyy/MM/dd');

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Row(
                                      children: [
                                        Text(
                                          invoice.invoiceNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              invoice.status,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusText(invoice.status),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      invoice.client.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${invoice.total.toStringAsFixed(2)} ${invoice.currency}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'تاريخ الإصدار: ${dateFormat.format(invoice.issueDate)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'تاريخ الاستحقاق: ${dateFormat.format(invoice.dueDate)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                invoice.isOverdue
                                                    ? Colors.red
                                                    : Colors.black87,
                                            fontWeight:
                                                invoice.isOverdue
                                                    ? FontWeight.bold
                                                    : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (invoice.status !=
                                              InvoiceStatus.paid &&
                                          invoice.status !=
                                              InvoiceStatus.cancelled)
                                        TextButton(
                                          onPressed:
                                              () => _updateInvoiceStatus(
                                                invoice,
                                                InvoiceStatus.paid,
                                              ),
                                          child: const Text('تم الدفع'),
                                        ),
                                      if (invoice.status == InvoiceStatus.draft)
                                        TextButton(
                                          onPressed:
                                              () => _updateInvoiceStatus(
                                                invoice,
                                                InvoiceStatus.sent,
                                              ),
                                          child: const Text('إرسال'),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: AppColors.primary,
                                        ),
                                        onPressed:
                                            () => _navigateToInvoiceDetail(
                                              invoice,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _showDeleteConfirmation(
                                              invoice,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToInvoiceDetail(null),
        tooltip: 'إنشاء فاتورة',
        child: const Icon(Icons.add),
      ),
    );
  }
}
