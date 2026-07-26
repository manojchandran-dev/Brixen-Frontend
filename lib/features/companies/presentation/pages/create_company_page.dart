import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../domain/entities/company.dart';
import '../providers/companies_provider.dart';

class CreateCompanyPage extends ConsumerStatefulWidget {
  final bool fromMenu;
  const CreateCompanyPage({super.key, this.fromMenu = false});

  @override
  ConsumerState<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends ConsumerState<CreateCompanyPage> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _submitting = false;

  // Step 1 — Company Identity
  final _nameCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _foundedCtrl = TextEditingController();
  String? _industry;
  String? _entityType;
  String? _size;

  // Step 2 — Contact & Owner
  final _ownerCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _secondaryEmailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  // Step 3 — Location & Setup
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  String? _country;
  String? _plan;
  bool _isActive = true;

  static const List<String> _countries = [
    'India', 'United States', 'United Kingdom', 'Canada',
    'Australia', 'Germany', 'France', 'Singapore', 'UAE', 'Other',
  ];
  static const List<String> _industries = [
    'Technology', 'Healthcare', 'Finance', 'Retail',
    'Manufacturing', 'Education', 'Real Estate', 'Hospitality',
    'Transportation', 'Other',
  ];
  static const List<String> _entityTypes = [
    'Sole Proprietorship', 'Partnership', 'LLP',
    'Private Limited', 'Public Limited', 'One Person Company',
    'Trust / NGO', 'Other',
  ];
  static const List<String> _plans = [
    'Basic', 'Standard', 'Professional', 'Enterprise',
  ];
  static const List<String> _sizes = [
    '1–10', '11–50', '51–200', '201–500', '500+',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _gstCtrl.dispose(); _panCtrl.dispose();
    _foundedCtrl.dispose(); _ownerCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _secondaryEmailCtrl.dispose(); _websiteCtrl.dispose();
    _addressCtrl.dispose(); _cityCtrl.dispose(); _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  GlobalKey<FormState> get _currentFormKey => [_step1Key, _step2Key, _step3Key][_currentStep];

  void _next() {
    if (!_currentFormKey.currentState!.validate()) return;
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _back() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _submit() async {
    if (!_currentFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    ref.read(companiesProvider.notifier).addCompany(Company(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      code: null,
      ownerName: _ownerCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      country: _country,
      pincode: _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
      industryType: _industry,
      entityType: _entityType,
      panNumber: _panCtrl.text.trim().isEmpty ? null : _panCtrl.text.trim().toUpperCase(),
      subscriptionPlan: _plan,
      isActive: _isActive,
      createdAt: DateTime.now(),
    ));
    if (!mounted) return;
    if (widget.fromMenu) {
      context.pop();
    } else {
      context.go(AppRouter.companies);
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
          onTap: () {
            if (_currentStep == 0) {
              if (widget.fromMenu) {
                context.pop();
              } else {
                context.go(AppRouter.companies);
              }
            } else {
              _back();
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.silverGradient : null,
              color: isDark ? null : AppColors.lightTextPrimary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16,
                color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.fromMenu)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text('Menu',
                        style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(Icons.chevron_right_rounded, size: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text('Companies',
                        style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(Icons.chevron_right_rounded, size: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  ),
                  Text('Create',
                      style: TextStyle(color: cs.onSurface, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              )
            else
              Text('Create Company',
                  style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
            if (!widget.fromMenu)
              Text('Step ${_currentStep + 1} of 3 — ${_stepTitle(_currentStep)}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11))
            else
              Text('Create Company — Step ${_currentStep + 1} of 3',
                  style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: _buildStep(context),
              ),
            ),
          ),
          _buildNavBar(context),
        ],
      ),
    );
  }

  String _stepTitle(int step) => ['Company Identity', 'Contact & Owner', 'Location & Setup'][step];

  Widget _buildStep(BuildContext context) {
    switch (_currentStep) {
      case 0: return _Step1(formKey: _step1Key, nameCtrl: _nameCtrl, gstCtrl: _gstCtrl, panCtrl: _panCtrl, foundedCtrl: _foundedCtrl, industry: _industry, entityType: _entityType, size: _size, industries: _industries, entityTypes: _entityTypes, sizes: _sizes, onIndustryChanged: (v) => setState(() => _industry = v), onEntityTypeChanged: (v) => setState(() => _entityType = v), onSizeChanged: (v) => setState(() => _size = v));
      case 1: return _Step2(formKey: _step2Key, ownerCtrl: _ownerCtrl, emailCtrl: _emailCtrl, phoneCtrl: _phoneCtrl, secondaryEmailCtrl: _secondaryEmailCtrl, websiteCtrl: _websiteCtrl);
      default: return _Step3(formKey: _step3Key, addressCtrl: _addressCtrl, cityCtrl: _cityCtrl, stateCtrl: _stateCtrl, pincodeCtrl: _pincodeCtrl, country: _country, plan: _plan, countries: _countries, plans: _plans, isActive: _isActive, onCountryChanged: (v) => setState(() => _country = v), onPlanChanged: (v) => setState(() => _plan = v), onStatusChanged: (v) => setState(() => _isActive = v));
    }
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: BrixenButton(
                label: 'Back',
                isOutlined: true,
                onPressed: _back,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: BrixenButton(
              label: _currentStep == 2 ? 'Create Company' : 'Continue',
              isLoading: _submitting,
              onPressed: _submitting ? null : (_currentStep == 2 ? _submit : _next),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = ['Identity', 'Contact', 'Location'];

    // Active/done: silver gradient in dark, near-black in light
    final activeCircleGradient = isDark ? AppColors.silverGradient : null;
    final activeCircleColor = isDark ? null : AppColors.lightTextPrimary;
    final activeContentColor = isDark ? AppColors.black : AppColors.white;
    final activeLineColor = isDark ? AppColors.silver : AppColors.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (i > 0)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i <= currentStep ? activeLineColor : Theme.of(context).dividerColor,
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: (done || active) ? activeCircleGradient : null,
                              color: (done || active) ? activeCircleColor : cs.surfaceContainerHighest,
                              border: Border.all(
                                color: (done || active) ? activeLineColor : Theme.of(context).dividerColor,
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: done
                                  ? Icon(Icons.check_rounded, size: 14, color: activeContentColor)
                                  : Text('${i + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: active ? activeContentColor : cs.onSurfaceVariant,
                                      )),
                            ),
                          ),
                          if (i < 2)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i < currentStep ? activeLineColor : Theme.of(context).dividerColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          color: active ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Step 1: Company Identity ─────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, gstCtrl, panCtrl, foundedCtrl;
  final String? industry, entityType, size;
  final List<String> industries, entityTypes, sizes;
  final void Function(String?) onIndustryChanged;
  final void Function(String?) onEntityTypeChanged;
  final void Function(String?) onSizeChanged;

  const _Step1({
    required this.formKey,
    required this.nameCtrl,
    required this.gstCtrl,
    required this.panCtrl,
    required this.foundedCtrl,
    required this.industry,
    required this.entityType,
    required this.size,
    required this.industries,
    required this.entityTypes,
    required this.sizes,
    required this.onIndustryChanged,
    required this.onEntityTypeChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          BrixenTextField(
            label: 'GST Number',
            hint: 'e.g. 22AAAAA0000A1Z5',
            controller: gstCtrl,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Company Name *',
            hint: 'Enter company name',
            controller: nameCtrl,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.business_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 22),

          BrixenDropdown<String>(
            hint: 'Entity type',
            value: entityType,
            items: entityTypes,
            labelOf: (s) => s,
            icon: Icons.account_balance_outlined,
            onChanged: onEntityTypeChanged,
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'PAN Card',
            hint: 'e.g. ABCDE1234F',
            controller: panCtrl,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.credit_card_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v.trim().toUpperCase())) {
                return 'Invalid PAN — format: ABCDE1234F';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),

          BrixenDropdown<String>(
            hint: 'Select industry type',
            value: industry,
            items: industries,
            labelOf: (s) => s,
            icon: Icons.work_outline,
            onChanged: onIndustryChanged,
          ),
          const SizedBox(height: 22),

          BrixenDropdown<String>(
            hint: 'Company size',
            value: size,
            items: sizes,
            labelOf: (s) => s,
            icon: Icons.groups_outlined,
            onChanged: onSizeChanged,
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Founded Year',
            hint: 'e.g. 2015',
            controller: foundedCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// ── Step 2: Contact & Owner ──────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ownerCtrl, emailCtrl, phoneCtrl,
      secondaryEmailCtrl, websiteCtrl;

  const _Step2({
    required this.formKey, required this.ownerCtrl, required this.emailCtrl,
    required this.phoneCtrl, required this.secondaryEmailCtrl, required this.websiteCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          BrixenTextField(
            label: 'Owner Name *',
            hint: 'Full name of owner',
            controller: ownerCtrl,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Email *',
            hint: 'Primary email address',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Phone Number',
            hint: 'e.g. +91 98765 43210',
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Secondary Email',
            hint: 'Alternate contact email',
            controller: secondaryEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Website',
            hint: 'https://company.com',
            controller: websiteCtrl,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.language_outlined),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// ── Step 3: Location & Setup ─────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressCtrl, cityCtrl, stateCtrl, pincodeCtrl;
  final String? country, plan;
  final List<String> countries, plans;
  final bool isActive;
  final void Function(String?) onCountryChanged;
  final void Function(String?) onPlanChanged;
  final void Function(bool) onStatusChanged;

  const _Step3({
    required this.formKey, required this.addressCtrl, required this.cityCtrl,
    required this.stateCtrl, required this.pincodeCtrl, required this.country,
    required this.plan, required this.countries, required this.plans,
    required this.isActive, required this.onCountryChanged,
    required this.onPlanChanged, required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          _AddressField(controller: addressCtrl),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'City',
            hint: 'Enter city',
            controller: cityCtrl,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.location_city_outlined),
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'State / Province',
            hint: 'Enter state',
            controller: stateCtrl,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.map_outlined),
          ),
          const SizedBox(height: 22),

          BrixenDropdown<String>(
            hint: 'Select country',
            value: country,
            items: countries,
            labelOf: (s) => s,
            icon: Icons.language_outlined,
            onChanged: onCountryChanged,
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Pincode / ZIP',
            hint: 'Enter pincode',
            controller: pincodeCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.pin_outlined),
          ),
          const SizedBox(height: 22),

          BrixenDropdown<String>(
            hint: 'Select subscription plan',
            value: plan,
            items: plans,
            labelOf: (s) => s,
            icon: Icons.card_membership_outlined,
            onChanged: onPlanChanged,
          ),
          const SizedBox(height: 20),

          Text('Company Status',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _StatusBtn(label: 'Active', selected: isActive, isActive: true, onTap: () => onStatusChanged(true))),
            const SizedBox(width: 12),
            Expanded(child: _StatusBtn(label: 'Inactive', selected: !isActive, isActive: false, onTap: () => onStatusChanged(false))),
          ]),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// ── Shared Widgets ───────────────────────────────────────────────────────────


class _StatusBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusBtn({required this.label, required this.selected, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.silver : Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 8, color: isActive ? AppColors.accentEmerald : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: selected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }
}

class _AddressField extends StatefulWidget {
  final TextEditingController controller;
  const _AddressField({required this.controller});

  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
  final _focus = FocusNode();
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    widget.controller.addListener(() {
      final has = widget.controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showLabel = _focused || _hasText;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppColors.silver : Theme.of(context).dividerColor,
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 14),
                child: Icon(Icons.location_on_outlined, color: cs.onSurfaceVariant, size: 20),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  maxLines: 3,
                  style: TextStyle(color: cs.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: showLabel ? 'Street address' : 'Address',
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
            top: -9,
            left: 12,
            child: Container(
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Address',
                style: TextStyle(
                  color: _focused ? AppColors.silver : cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
