import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/products_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;

  const ProductDetailScreen({super.key, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductsService _productsService = ProductsService();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _costController;
  late final TextEditingController _unitController;
  late final TextEditingController _quantityController;
  late final TextEditingController _skuController;

  bool _isLoading = false;
  bool _isNewProduct = true;

  @override
  void initState() {
    super.initState();

    _isNewProduct = widget.product == null;

    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _priceController = TextEditingController(
      text:
          widget.product?.price != null ? widget.product!.price.toString() : '',
    );
    _costController = TextEditingController(
      text: widget.product?.cost != null ? widget.product!.cost.toString() : '',
    );
    _unitController = TextEditingController(text: widget.product?.unit ?? '');
    _quantityController = TextEditingController(
      text:
          widget.product?.quantity != null
              ? widget.product!.quantity.toString()
              : '',
    );
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final double price = double.parse(_priceController.text);
      double? cost;
      int? quantity;

      if (_costController.text.isNotEmpty) {
        cost = double.parse(_costController.text);
      }

      if (_quantityController.text.isNotEmpty) {
        quantity = int.parse(_quantityController.text);
      }

      if (_isNewProduct) {
        await _productsService.createProduct(
          name: _nameController.text,
          description:
              _descriptionController.text.isNotEmpty
                  ? _descriptionController.text
                  : null,
          price: price,
          cost: cost,
          unit: _unitController.text.isNotEmpty ? _unitController.text : null,
          quantity: quantity,
          sku: _skuController.text.isNotEmpty ? _skuController.text : null,
        );
      } else {
        final updatedProduct = widget.product!.copyWith(
          name: _nameController.text,
          description:
              _descriptionController.text.isNotEmpty
                  ? _descriptionController.text
                  : null,
          price: price,
          cost: cost,
          unit: _unitController.text.isNotEmpty ? _unitController.text : null,
          quantity: quantity,
          sku: _skuController.text.isNotEmpty ? _skuController.text : null,
        );

        await _productsService.updateProduct(updatedProduct);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isNewProduct ? 'تم إضافة المنتج بنجاح' : 'تم تعديل المنتج بنجاح',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewProduct ? 'إضافة منتج جديد' : 'تعديل المنتج'),
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
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المنتج *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال اسم المنتج';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'وصف المنتج',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'سعر المنتج *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          suffixText: 'ر.س',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال سعر المنتج';
                          }
                          if (double.tryParse(value) == null) {
                            return 'يرجى إدخال قيمة رقمية صحيحة';
                          }
                          if (double.parse(value) < 0) {
                            return 'يجب أن يكون السعر أكبر من الصفر';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costController,
                        decoration: const InputDecoration(
                          labelText: 'تكلفة المنتج',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money_off),
                          suffixText: 'ر.س',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'يرجى إدخال قيمة رقمية صحيحة';
                            }
                            if (double.parse(value) < 0) {
                              return 'يجب أن تكون التكلفة أكبر من الصفر';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              decoration: const InputDecoration(
                                labelText: 'وحدة القياس',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.scale),
                                hintText: 'مثال: قطعة، ساعة، كيلو',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'الكمية المتاحة',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory_2),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (int.tryParse(value) == null) {
                                    return 'يرجى إدخال رقم صحيح';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'رمز المنتج (SKU)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isNewProduct ? 'إضافة المنتج' : 'حفظ التغييرات',
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
