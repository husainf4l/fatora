import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/users_service.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final UsersService _usersService = UsersService();

  late final TextEditingController _businessNameController;
  late final TextEditingController _businessAddressController;
  late final TextEditingController _taxNumberController;
  late final TextEditingController _phoneController;

  bool _isLoading = true;
  bool _isSaving = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _businessAddressController = TextEditingController();
    _taxNumberController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _taxNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _usersService.getCurrentUser();

      setState(() {
        _currentUser = user;

        _businessNameController.text = user.businessName ?? '';
        _businessAddressController.text = user.businessAddress ?? '';
        _taxNumberController.text = user.taxNumber ?? '';
        _phoneController.text = user.phone ?? '';

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

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(
          businessName:
              _businessNameController.text.isEmpty
                  ? null
                  : _businessNameController.text,
          businessAddress:
              _businessAddressController.text.isEmpty
                  ? null
                  : _businessAddressController.text,
          taxNumber:
              _taxNumberController.text.isEmpty
                  ? null
                  : _taxNumberController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        );

        await _usersService.updateCurrentUser(updatedUser);

        setState(() {
          _currentUser = updatedUser;
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ الإعدادات: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _usersService.logout();
      // Navigation will be handled by the auth state listener
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تسجيل الخروج: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User info card
                    if (_currentUser != null)
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.primary,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _currentUser!.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_currentUser!.email),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Business settings form
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'بيانات العمل',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _businessNameController,
                                decoration: const InputDecoration(
                                  labelText: 'اسم الشركة / المؤسسة',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.business),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _businessAddressController,
                                decoration: const InputDecoration(
                                  labelText: 'عنوان الشركة',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _taxNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'الرقم الضريبي',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.receipt),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الهاتف',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isSaving ? null : _saveSettings,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child:
                                    _isSaving
                                        ? const CircularProgressIndicator()
                                        : const Text(
                                          'حفظ الإعدادات',
                                          style: TextStyle(fontSize: 16),
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App settings
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إعدادات التطبيق',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: const Text('تغيير كلمة المرور'),
                              leading: const Icon(Icons.lock_outline),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // Navigate to change password screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'سيتم إضافة هذه الميزة قريباً',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text('المساعدة والدعم'),
                              leading: const Icon(Icons.help_outline),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // Navigate to help screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'سيتم إضافة هذه الميزة قريباً',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text('عن التطبيق'),
                              leading: const Icon(Icons.info_outline),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                showAboutDialog(
                                  context: context,
                                  applicationName: 'فاتورة',
                                  applicationVersion: '1.0.0',
                                  applicationIcon: const Icon(
                                    Icons.receipt,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                  children: const [
                                    Text(
                                      'تطبيق فاتورة هو تطبيق لإدارة الفواتير والعملاء والمنتجات بطريقة سهلة وبسيطة.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logout button
                    ElevatedButton.icon(
                      onPressed: _showLogoutConfirmation,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }
}
