import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../domain/entities/customer.dart';
import '../providers/customers_provider.dart';

class CreateCustomerPage extends ConsumerStatefulWidget {
  final Customer? editCustomer;
  final bool fromMasters;
  const CreateCustomerPage({super.key, this.editCustomer, this.fromMasters = false});

  @override
  ConsumerState<CreateCustomerPage> createState() => _CreateCustomerPageState();
}

class _CreateCustomerPageState extends ConsumerState<CreateCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  final _nameCtrl     = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _gstCtrl      = TextEditingController();

  bool get _isEditing => widget.editCustomer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.editCustomer;
    if (c != null) {
      _nameCtrl.text     = c.name;
      _shopNameCtrl.text = c.shopName ?? '';
      _phoneCtrl.text    = c.phone ?? '';
      _emailCtrl.text    = c.email ?? '';
      _addressCtrl.text  = c.address ?? '';
      _gstCtrl.text      = c.gstNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shopNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final customer = Customer(
      id: _isEditing ? widget.editCustomer!.id : '',
      name:      _nameCtrl.text.trim(),
      shopName:  _shopNameCtrl.text.trim().isEmpty ? null : _shopNameCtrl.text.trim(),
      phone:     _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email:     _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address:   _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      gstNumber: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
      createdAt: _isEditing ? widget.editCustomer!.createdAt : DateTime.now(),
    );

    try {
      if (_isEditing) {
        await ref.read(customersProvider.notifier).updateCustomer(customer);
      } else {
        await ref.read(customersProvider.notifier).addCustomer(customer);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dangerFill),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).dividerColor),
        ),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.silverGradient : null,
              color: isDark ? null : AppColors.lightPrimary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppColors.shadows([
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2),
                  blurRadius: 6, offset: const Offset(0, 2),
                ),
              ]),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16,
                color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.fromMasters)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go(AppRouter.companies),
                      child: Text('Menu', style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(Icons.chevron_right_rounded, size: 13,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('Masters', style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(Icons.chevron_right_rounded, size: 13,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('Customers', style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(Icons.chevron_right_rounded, size: 13,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    ),
                    Text(_isEditing ? 'Edit' : 'Create',
                        style: TextStyle(color: cs.onSurface, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              Text(_isEditing ? 'Edit Customer' : 'New Customer',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            // Name
            BrixenTextField(
              label: 'Name *',
              hint: 'Full name',
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // Shop Name
            BrixenTextField(
              label: 'Shop Name',
              hint: 'Business or shop name (optional)',
              controller: _shopNameCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.storefront_outlined),
            ),
            const SizedBox(height: 20),

            // Phone
            BrixenTextField(
              label: 'Phone',
              hint: '+91 9876543210',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: 20),

            // Email
            BrixenTextField(
              label: 'Email',
              hint: 'customer@example.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            const SizedBox(height: 20),

            // GST Number
            BrixenTextField(
              label: 'GST Number',
              hint: '22AAAAA0000A1Z5',
              controller: _gstCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.receipt_outlined),
            ),
            const SizedBox(height: 20),

            // Address
            _AddressField(controller: _addressCtrl),
            const SizedBox(height: 32),

            BrixenButton(
              label: _isEditing ? 'Save Changes' : 'Create Customer',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Address multiline field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AddressField extends StatefulWidget {
  final TextEditingController controller;
  const _AddressField({required this.controller});

  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = widget.controller.text.isNotEmpty;
    final showLabel = _focused || hasText;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? (isDark ? AppColors.silver : AppColors.lightPrimary)
                  : Theme.of(context).dividerColor,
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 14),
                child: Icon(Icons.location_on_outlined,
                    color: cs.onSurfaceVariant, size: 20),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  maxLines: 3,
                  style: TextStyle(color: cs.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: showLabel ? 'Street, City, State, PIN' : 'Address',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(8, 14, 16, 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel)
          Positioned(
            top: -9, left: 12,
            child: Container(
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Address',
                  style: TextStyle(
                    color: _focused ? AppColors.silver : cs.onSurfaceVariant,
                    fontSize: 12,
                  )),
            ),
          ),
      ],
    );
  }
}
