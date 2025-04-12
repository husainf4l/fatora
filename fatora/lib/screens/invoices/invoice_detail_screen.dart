import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/client_model.dart';
import '../../models/product_model.dart';
import '../../models/invoice_model.dart';
import '../../services/clients_service.dart';
import '../../services/products_service.dart';
import '../../services/invoices_service.dart';
import '../../theme/app_colors.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice? invoice;

  const InvoiceDetailScreen({super.key, this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final ClientsService _clientsService = ClientsService();
  final ProductsService _productsService = ProductsService();
  final InvoicesService _invoicesService = InvoicesService();
  final Uuid _uuid = const Uuid();

  List<Client> _clients = [];
  List<Product> _products = [];
  Client? _selectedClient;
  List<InvoiceLineItem> _lineItems = [];
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController(
    text: '15',
  ); // Default 15% VAT in Saudi Arabia

  bool _isLoading = true;
  bool _isNewInvoice = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isNewInvoice = widget.invoice == null;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load clients
      final clients = await _clientsService.getAllClients();
      // Load products
      final products = await _productsService.getAllProducts();

      setState(() {
        _clients = clients;
        _products = products;

        if (_isNewInvoice) {
          // Set default values for new invoice
          _lineItems = [];
          if (clients.isNotEmpty) {
            _selectedClient = clients.first;
          }
        } else {
          // Set values from existing invoice
          _selectedClient = widget.invoice!.client;
          _lineItems = List.from(widget.invoice!.items);
          _issueDate = widget.invoice!.issueDate;
          _dueDate = widget.invoice!.dueDate;
          _notesController.text = widget.invoice!.notes ?? '';

          // Calculate tax rate from the invoice
          if (widget.invoice!.tax != null && widget.invoice!.subtotal > 0) {
            final taxRate =
                (widget.invoice!.tax! / widget.invoice!.subtotal) * 100;
            _taxRateController.text = taxRate.toStringAsFixed(0);
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: ${e.toString()}')),
        );
      }
    }
  }

  double _calculateSubtotal() {
    return _lineItems.fold(0, (sum, item) => sum + item.total);
  }

  double _calculateTax() {
    final subtotal = _calculateSubtotal();
    double taxRate = 0;
    try {
      taxRate = double.parse(_taxRateController.text) / 100;
    } catch (_) {
      // Ignore parsing errors
    }
    return subtotal * taxRate;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTax();
  }

  void _addLineItem() {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إضافة منتجات أولاً')));
      return;
    }

    setState(() {
      final product = _products.first;
      _lineItems.add(
        InvoiceLineItem(
          id: _uuid.v4(),
          description: product.name,
          quantity: 1,
          unitPrice: product.price,
          total: product.price,
          product: product,
        ),
      );
    });
  }

  void _updateLineItem(
    int index, {
    Product? product,
    double? quantity,
    double? unitPrice,
  }) {
    setState(() {
      final item = _lineItems[index];
      final updatedProduct = product ?? item.product;
      final updatedQuantity = quantity ?? item.quantity;
      final updatedUnitPrice = unitPrice ?? item.unitPrice;
      final total = updatedQuantity * updatedUnitPrice;

      _lineItems[index] = InvoiceLineItem(
        id: item.id,
        description: updatedProduct?.name ?? item.description,
        quantity: updatedQuantity,
        unitPrice: updatedUnitPrice,
        total: total,
        product: updatedProduct,
      );
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
    });
  }

  Future<void> _saveInvoice() async {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار عميل')));
      return;
    }

    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة منتج واحد على الأقل')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final double taxRate = double.tryParse(_taxRateController.text) ?? 15;

      if (_isNewInvoice) {
        await _invoicesService.createInvoice(
          clientId: _selectedClient!.id,
          issueDate: _issueDate,
          dueDate: _dueDate,
          items: _lineItems,
          taxRate: taxRate,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
        );
      } else {
        final updatedInvoice = Invoice(
          id: widget.invoice!.id,
          invoiceNumber: widget.invoice!.invoiceNumber,
          issueDate: _issueDate,
          dueDate: _dueDate,
          status: widget.invoice!.status,
          client: _selectedClient!,
          items: _lineItems,
          subtotal: _calculateSubtotal(),
          tax: _calculateTax(),
          total: _calculateTotal(),
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
          createdAt: widget.invoice!.createdAt,
          paidAt: widget.invoice!.paidAt,
          currency: 'SAR',
        );

        await _invoicesService.updateInvoice(updatedInvoice);
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isNewInvoice
                  ? 'تم إنشاء الفاتورة بنجاح'
                  : 'تم تحديث الفاتورة بنجاح',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _issueDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
          if (_dueDate.isBefore(_issueDate)) {
            _dueDate = _issueDate.add(const Duration(days: 14));
          }
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewInvoice ? 'إنشاء فاتورة جديدة' : 'تعديل الفاتورة'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Client selection
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'بيانات العميل',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<Client>(
                                decoration: const InputDecoration(
                                  labelText: 'اختر العميل *',
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedClient,
                                items:
                                    _clients.map((client) {
                                      return DropdownMenuItem<Client>(
                                        value: client,
                                        child: Text(client.name),
                                      );
                                    }).toList(),
                                onChanged: (Client? newValue) {
                                  setState(() {
                                    _selectedClient = newValue;
                                  });
                                },
                              ),
                              if (_selectedClient != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'البريد الإلكتروني: ${_selectedClient!.email}',
                                ),
                                if (_selectedClient!.phone != null)
                                  Text('الهاتف: ${_selectedClient!.phone}'),
                                if (_selectedClient!.address != null)
                                  Text('العنوان: ${_selectedClient!.address}'),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Invoice dates
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تواريخ الفاتورة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'تاريخ الإصدار',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: InkWell(
                                        onTap: () => _selectDate(context, true),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(dateFormat.format(_issueDate)),
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'تاريخ الاستحقاق',
                                        border: OutlineInputBorder(),
                                      ),
                                      child: InkWell(
                                        onTap:
                                            () => _selectDate(context, false),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(dateFormat.format(_dueDate)),
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Line items
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'بنود الفاتورة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _addLineItem,
                                    icon: const Icon(Icons.add),
                                    label: const Text('إضافة منتج'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _lineItems.length,
                                itemBuilder: (context, index) {
                                  final item = _lineItems[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: DropdownButtonFormField<
                                                  Product
                                                >(
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'المنتج/الخدمة',
                                                        isDense: true,
                                                      ),
                                                  value: item.product,
                                                  items:
                                                      _products.map((product) {
                                                        return DropdownMenuItem<
                                                          Product
                                                        >(
                                                          value: product,
                                                          child: Text(
                                                            product.name,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        );
                                                      }).toList(),
                                                  onChanged: (
                                                    Product? newValue,
                                                  ) {
                                                    if (newValue != null) {
                                                      _updateLineItem(
                                                        index,
                                                        product: newValue,
                                                        unitPrice:
                                                            newValue.price,
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed:
                                                    () =>
                                                        _removeLineItem(index),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  initialValue:
                                                      item.quantity.toString(),
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'الكمية',
                                                        isDense: true,
                                                      ),
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  onChanged: (value) {
                                                    final quantity =
                                                        double.tryParse(
                                                          value,
                                                        ) ??
                                                        item.quantity;
                                                    _updateLineItem(
                                                      index,
                                                      quantity: quantity,
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 3,
                                                child: TextFormField(
                                                  initialValue:
                                                      item.unitPrice.toString(),
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'السعر',
                                                        isDense: true,
                                                        suffixText: 'ر.س',
                                                      ),
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  onChanged: (value) {
                                                    final price =
                                                        double.tryParse(
                                                          value,
                                                        ) ??
                                                        item.unitPrice;
                                                    _updateLineItem(
                                                      index,
                                                      unitPrice: price,
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 3,
                                                child: InputDecorator(
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'الإجمالي',
                                                        isDense: true,
                                                      ),
                                                  child: Text(
                                                    '${item.total.toStringAsFixed(2)} ر.س',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
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
                              if (_lineItems.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'لا توجد منتجات، يرجى إضافة منتج',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Invoice totals
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ملخص الفاتورة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Expanded(
                                    flex: 2,
                                    child: Text('المجموع الفرعي:'),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${_calculateSubtotal().toStringAsFixed(2)} ر.س',
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text('ضريبة القيمة المضافة:'),
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: TextFormField(
                                      controller: _taxRateController,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        suffixText: '%',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          // Just to rebuild and recalculate totals
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_calculateTax().toStringAsFixed(2)} ر.س',
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  const Expanded(
                                    flex: 2,
                                    child: Text(
                                      'الإجمالي:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${_calculateTotal().toStringAsFixed(2)} ر.س',
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات',
                          border: OutlineInputBorder(),
                          hintText: 'أضف ملاحظات ستظهر في الفاتورة',
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveInvoice,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            _isSaving
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : Text(
                                  _isNewInvoice
                                      ? 'إنشاء الفاتورة'
                                      : 'حفظ التغييرات',
                                  style: const TextStyle(fontSize: 16),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
