import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../domain/entities/employee.dart';
import '../providers/employees_provider.dart';

class CreateEmployeePage extends ConsumerStatefulWidget {
  final bool fromMasters;
  final Employee? editEmployee;
  const CreateEmployeePage({super.key, this.fromMasters = false, this.editEmployee});

  @override
  ConsumerState<CreateEmployeePage> createState() => _CreateEmployeePageState();
}

class _CreateEmployeePageState extends ConsumerState<CreateEmployeePage> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _submitting = false;

  static const _labels = ['Personal', 'Employment', 'Banking', 'Review'];

  // Step 1 — Personal Info
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _gender;
  DateTime? _dateOfBirth;

  // Step 2 — Employment Info
  final _departmentCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  DateTime? _joiningDate;
  String? _employmentType;
  String _status = 'Active';
  Employee? _manager;

  // Step 3 — Banking & Government IDs
  final _panCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  // Step 4 — Emergency Contact
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  static const _genders = ['Male', 'Female', 'Other'];
  static const _employmentTypes = ['Full-time', 'Part-time', 'Contract', 'Intern'];
  static const _statuses = ['Active', 'Inactive', 'On Leave'];

  bool get _isEditing => widget.editEmployee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editEmployee;
    if (e != null) {
      _firstNameCtrl.text = e.firstName;
      _lastNameCtrl.text = e.lastName ?? '';
      _emailCtrl.text = e.email ?? '';
      _phoneCtrl.text = e.phone ?? '';
      _addressCtrl.text = e.address ?? '';
      _gender = e.gender;
      _dateOfBirth = e.dateOfBirth;
      _departmentCtrl.text = e.department ?? '';
      _designationCtrl.text = e.designation ?? '';
      _salaryCtrl.text = e.salary?.toStringAsFixed(2) ?? '';
      _joiningDate = e.joiningDate;
      _employmentType = e.employmentType;
      _status = e.status;
      _panCtrl.text = e.panNumber ?? '';
      _aadhaarCtrl.text = e.aadhaarNumber ?? '';
      _bankNameCtrl.text = e.bankName ?? '';
      _accountNumberCtrl.text = e.accountNumber ?? '';
      _ifscCtrl.text = e.ifscCode ?? '';
      _emergencyNameCtrl.text = e.emergencyContactName ?? '';
      _emergencyPhoneCtrl.text = e.emergencyContactPhone ?? '';
      if (e.managerId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final list = ref.read(employeesProvider).valueOrNull ?? [];
          final found = list.where((x) => x.id == e.managerId).firstOrNull;
          if (found != null) setState(() => _manager = found);
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    _departmentCtrl.dispose(); _designationCtrl.dispose(); _salaryCtrl.dispose();
    _panCtrl.dispose(); _aadhaarCtrl.dispose(); _bankNameCtrl.dispose(); _accountNumberCtrl.dispose(); _ifscCtrl.dispose();
    _emergencyNameCtrl.dispose(); _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  GlobalKey<FormState> get _currentFormKey => [_step1Key, _step2Key, _step3Key, _step4Key][_currentStep];

  void _next() { if (!_currentFormKey.currentState!.validate()) return; if (_currentStep < 3) setState(() => _currentStep++); }
  void _back() { if (_currentStep > 0) setState(() => _currentStep--); }

  Future<void> _submit() async {
    if (!_currentFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 400));
    final notifier = ref.read(employeesProvider.notifier);
    final employee = Employee(
      id: _isEditing ? widget.editEmployee!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      employeeCode: _isEditing ? widget.editEmployee!.employeeCode : notifier.nextEmployeeCode(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim().isEmpty ? null : _lastNameCtrl.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirth,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      joiningDate: _joiningDate,
      department: _departmentCtrl.text.trim().isEmpty ? null : _departmentCtrl.text.trim(),
      designation: _designationCtrl.text.trim().isEmpty ? null : _designationCtrl.text.trim(),
      managerId: _manager?.id,
      managerName: _manager?.fullName,
      employmentType: _employmentType,
      salary: double.tryParse(_salaryCtrl.text.trim()),
      panNumber: _panCtrl.text.trim().isEmpty ? null : _panCtrl.text.trim().toUpperCase(),
      aadhaarNumber: _aadhaarCtrl.text.trim().isEmpty ? null : _aadhaarCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim().isEmpty ? null : _bankNameCtrl.text.trim(),
      accountNumber: _accountNumberCtrl.text.trim().isEmpty ? null : _accountNumberCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim().isEmpty ? null : _ifscCtrl.text.trim().toUpperCase(),
      emergencyContactName: _emergencyNameCtrl.text.trim().isEmpty ? null : _emergencyNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim().isEmpty ? null : _emergencyPhoneCtrl.text.trim(),
      status: _status,
      createdAt: _isEditing ? widget.editEmployee!.createdAt : DateTime.now(),
    );
    if (_isEditing) { await notifier.updateEmployee(employee); }
    else            { await notifier.addEmployee(employee); }
    if (!mounted) return;
    if (widget.fromMasters) { context.pop(); } else { context.go(AppRouter.employees); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final employees = ref.watch(employeesProvider).valueOrNull ?? <Employee>[];
    final managerOptions = employees.where((e) => e.id != widget.editEmployee?.id).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Theme.of(context).dividerColor)),
        leading: GestureDetector(
          onTap: () { if (_currentStep == 0) { widget.fromMasters ? context.pop() : context.go(AppRouter.employees); } else { _back(); } },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.silverGradient : null,
              color: isDark ? null : AppColors.lightTextPrimary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.fromMasters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                GestureDetector(onTap: () => context.pop(), child: Text('Menu', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.chevron_right_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                GestureDetector(onTap: () => context.pop(), child: Text('Masters', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.chevron_right_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                GestureDetector(onTap: () => context.pop(), child: Text('Employees', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.chevron_right_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                Text(_isEditing ? 'Edit' : 'Create', style: TextStyle(color: cs.onSurface, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            )
          else
            Text(_isEditing ? 'Edit Employee' : 'New Employee', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
          Text('Step ${_currentStep + 1} of 4 — ${_labels[_currentStep]}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
        ]),
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep, labels: _labels, accentColor: AppColors.accentEmerald),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim), child: child)),
              child: KeyedSubtree(key: ValueKey(_currentStep), child: _buildStep(managerOptions)),
            ),
          ),
          _NavBar(currentStep: _currentStep, totalSteps: 4, submitting: _submitting, isEditing: _isEditing, onBack: _back, onNext: _next, onSubmit: _submit),
        ],
      ),
    );
  }

  Widget _buildStep(List<Employee> managerOptions) {
    switch (_currentStep) {
      case 0:
        return _Step1(
          formKey: _step1Key,
          firstNameCtrl: _firstNameCtrl, lastNameCtrl: _lastNameCtrl,
          emailCtrl: _emailCtrl, phoneCtrl: _phoneCtrl, addressCtrl: _addressCtrl,
          gender: _gender, genders: _genders, onGenderChanged: (v) => setState(() => _gender = v),
          dateOfBirth: _dateOfBirth, onDobChanged: (d) => setState(() => _dateOfBirth = d),
        );
      case 1:
        return _Step2(
          formKey: _step2Key,
          departmentCtrl: _departmentCtrl, designationCtrl: _designationCtrl, salaryCtrl: _salaryCtrl,
          joiningDate: _joiningDate, onJoiningDateChanged: (d) => setState(() => _joiningDate = d),
          employmentType: _employmentType, employmentTypes: _employmentTypes, onEmploymentTypeChanged: (v) => setState(() => _employmentType = v),
          status: _status, statuses: _statuses, onStatusChanged: (v) => setState(() => _status = v ?? 'Active'),
          manager: _manager, managerOptions: managerOptions, onManagerChanged: (m) => setState(() => _manager = m),
        );
      case 2:
        return _Step3(
          formKey: _step3Key,
          panCtrl: _panCtrl, aadhaarCtrl: _aadhaarCtrl,
          bankNameCtrl: _bankNameCtrl, accountNumberCtrl: _accountNumberCtrl, ifscCtrl: _ifscCtrl,
        );
      default:
        return _Step4(
          formKey: _step4Key,
          emergencyNameCtrl: _emergencyNameCtrl, emergencyPhoneCtrl: _emergencyPhoneCtrl,
          preview: {
            'Name': [_firstNameCtrl.text.trim(), _lastNameCtrl.text.trim()].where((s) => s.isNotEmpty).join(' ').isEmpty ? '—' : [_firstNameCtrl.text.trim(), _lastNameCtrl.text.trim()].where((s) => s.isNotEmpty).join(' '),
            'Gender': _gender ?? '—',
            'Date of Birth': _dateOfBirth == null ? '—' : DateFormat('dd MMM yyyy').format(_dateOfBirth!),
            'Department': _departmentCtrl.text.trim().isEmpty ? '—' : _departmentCtrl.text.trim(),
            'Designation': _designationCtrl.text.trim().isEmpty ? '—' : _designationCtrl.text.trim(),
            'Employment Type': _employmentType ?? '—',
            'Manager': _manager?.fullName ?? '—',
            'Salary': _salaryCtrl.text.trim().isEmpty ? '—' : '₹${_salaryCtrl.text.trim()}',
            'Status': _status,
          },
        );
    }
  }
}

// ── Step Indicator ─────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  final Color accentColor;
  const _StepIndicator({required this.currentStep, required this.labels, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(labels.length, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(child: Row(children: [
            Expanded(child: Column(children: [
              Row(children: [
                if (i > 0) Expanded(child: Container(height: 2, color: i <= currentStep ? accentColor : Theme.of(context).dividerColor)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (done || active) ? accentColor : cs.surfaceContainerHighest,
                    border: Border.all(color: (done || active) ? accentColor : Theme.of(context).dividerColor, width: active ? 2 : 1),
                  ),
                  child: Center(child: done
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : cs.onSurfaceVariant))),
                ),
                if (i < labels.length - 1) Expanded(child: Container(height: 2, color: i < currentStep ? accentColor : Theme.of(context).dividerColor)),
              ]),
              const SizedBox(height: 6),
              Text(labels[i], style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: active ? cs.onSurface : cs.onSurfaceVariant)),
            ])),
          ]));
        }),
      ),
    );
  }
}

// ── Nav Bar ────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int currentStep, totalSteps; final bool submitting, isEditing;
  final VoidCallback onBack, onNext, onSubmit;
  const _NavBar({required this.currentStep, required this.totalSteps, required this.submitting, required this.isEditing, required this.onBack, required this.onNext, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
      child: Row(children: [
        if (currentStep > 0) ...[Expanded(child: BrixenButton(label: 'Back', isOutlined: true, onPressed: onBack)), const SizedBox(width: 12)],
        Expanded(flex: 2, child: BrixenButton(
          label: isLast ? (isEditing ? 'Save Changes' : 'Create Employee') : 'Continue',
          isLoading: submitting,
          onPressed: submitting ? null : (isLast ? onSubmit : onNext),
        )),
      ]),
    );
  }
}

// ── Step 1: Personal Info ──────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl, lastNameCtrl, emailCtrl, phoneCtrl, addressCtrl;
  final String? gender;
  final List<String> genders;
  final void Function(String?) onGenderChanged;
  final DateTime? dateOfBirth;
  final void Function(DateTime?) onDobChanged;

  const _Step1({
    required this.formKey, required this.firstNameCtrl, required this.lastNameCtrl,
    required this.emailCtrl, required this.phoneCtrl, required this.addressCtrl,
    required this.gender, required this.genders, required this.onGenderChanged,
    required this.dateOfBirth, required this.onDobChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 28, 16, 16), children: [
        BrixenTextField(
          label: 'First Name *', hint: 'Enter first name',
          controller: firstNameCtrl, textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline_rounded),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 22),
        BrixenTextField(
          label: 'Last Name', hint: 'Enter last name',
          controller: lastNameCtrl, textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline_rounded),
        ),
        const SizedBox(height: 22),
        BrixenDropdown<String>(hint: 'Gender', value: gender, items: genders, labelOf: (s) => s, icon: Icons.wc_rounded, onChanged: onGenderChanged),
        const SizedBox(height: 22),
        _OptionalDateField(label: 'Date of Birth', value: dateOfBirth, onChanged: onDobChanged),
        const SizedBox(height: 22),
        BrixenTextField(
          label: 'Email', hint: 'employee@example.com',
          controller: emailCtrl, textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.mail_outline_rounded),
        ),
        const SizedBox(height: 22),
        BrixenTextField(
          label: 'Phone', hint: 'Enter phone number',
          controller: phoneCtrl, textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
        const SizedBox(height: 22),
        _MultilineField(controller: addressCtrl, label: 'Address', hint: 'Enter residential address', icon: Icons.location_on_outlined),
        const SizedBox(height: 22),
      ]),
    );
  }
}

// ── Step 2: Employment Info ────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController departmentCtrl, designationCtrl, salaryCtrl;
  final DateTime? joiningDate;
  final void Function(DateTime?) onJoiningDateChanged;
  final String? employmentType;
  final List<String> employmentTypes;
  final void Function(String?) onEmploymentTypeChanged;
  final String status;
  final List<String> statuses;
  final void Function(String?) onStatusChanged;
  final Employee? manager;
  final List<Employee> managerOptions;
  final void Function(Employee?) onManagerChanged;

  const _Step2({
    required this.formKey, required this.departmentCtrl, required this.designationCtrl, required this.salaryCtrl,
    required this.joiningDate, required this.onJoiningDateChanged,
    required this.employmentType, required this.employmentTypes, required this.onEmploymentTypeChanged,
    required this.status, required this.statuses, required this.onStatusChanged,
    required this.manager, required this.managerOptions, required this.onManagerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 28, 16, 16), children: [
        BrixenTextField(label: 'Department', hint: 'e.g. Engineering', controller: departmentCtrl, textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.apartment_outlined)),
        const SizedBox(height: 22),
        BrixenTextField(label: 'Designation', hint: 'e.g. Software Engineer', controller: designationCtrl, textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.badge_outlined)),
        const SizedBox(height: 22),
        _OptionalDateField(label: 'Joining Date', value: joiningDate, onChanged: onJoiningDateChanged),
        const SizedBox(height: 22),
        BrixenDropdown<String>(hint: 'Employment Type', value: employmentType, items: employmentTypes, labelOf: (s) => s, icon: Icons.work_outline_rounded, onChanged: onEmploymentTypeChanged),
        const SizedBox(height: 22),
        if (managerOptions.isNotEmpty) ...[
          BrixenDropdown<Employee>(hint: 'Manager', value: manager, items: managerOptions, labelOf: (e) => e.fullName, icon: Icons.supervisor_account_outlined, onChanged: onManagerChanged),
          const SizedBox(height: 22),
        ],
        BrixenTextField(label: 'Salary', hint: '0.00', controller: salaryCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.currency_rupee_rounded)),
        const SizedBox(height: 22),
        Text('Status', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: statuses.map((s) {
          final selected = s == status;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: s == statuses.last ? 0 : 8),
            child: _StatusChip(label: s, selected: selected, onTap: () => onStatusChanged(s)),
          ));
        }).toList()),
        const SizedBox(height: 22),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _StatusChip({required this.label, required this.selected, required this.onTap});

  Color _color() {
    switch (label) {
      case 'Active': return AppColors.accentEmerald;
      case 'Inactive': return AppColors.accentRose;
      default: return AppColors.accentGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : Theme.of(context).dividerColor),
        ),
        child: Center(child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          fontSize: 12,
        ))),
      ),
    );
  }
}

// ── Step 3: Banking & Government IDs ───────────────────────────────────────

class _Step3 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController panCtrl, aadhaarCtrl, bankNameCtrl, accountNumberCtrl, ifscCtrl;
  const _Step3({required this.formKey, required this.panCtrl, required this.aadhaarCtrl, required this.bankNameCtrl, required this.accountNumberCtrl, required this.ifscCtrl});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 28, 16, 16), children: [
        BrixenTextField(label: 'PAN Number', hint: 'ABCDE1234F', controller: panCtrl, textCapitalization: TextCapitalization.characters, textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.badge_outlined)),
        const SizedBox(height: 22),
        BrixenTextField(label: 'Aadhaar Number', hint: 'Enter 12-digit Aadhaar number', controller: aadhaarCtrl, keyboardType: TextInputType.number, textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.credit_card_outlined)),
        const SizedBox(height: 22),
        BrixenTextField(label: 'Bank Name', hint: 'Enter bank name', controller: bankNameCtrl, textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.account_balance_outlined)),
        const SizedBox(height: 22),
        BrixenTextField(label: 'Account Number', hint: 'Enter bank account number', controller: accountNumberCtrl, keyboardType: TextInputType.number, textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.numbers_rounded)),
        const SizedBox(height: 22),
        BrixenTextField(label: 'IFSC Code', hint: 'e.g. HDFC0001234', controller: ifscCtrl, textCapitalization: TextCapitalization.characters, textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.account_balance_wallet_outlined)),
        const SizedBox(height: 22),
      ]),
    );
  }
}

// ── Step 4: Emergency Contact & Review ─────────────────────────────────────

class _Step4 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emergencyNameCtrl, emergencyPhoneCtrl;
  final Map<String, String> preview;
  const _Step4({required this.formKey, required this.emergencyNameCtrl, required this.emergencyPhoneCtrl, required this.preview});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: formKey,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 28, 16, 16), children: [
        BrixenTextField(label: 'Emergency Contact Name', hint: 'Enter contact name', controller: emergencyNameCtrl, textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.contact_emergency_outlined)),
        const SizedBox(height: 22),
        BrixenTextField(label: 'Emergency Contact Phone', hint: 'Enter contact phone', controller: emergencyPhoneCtrl, keyboardType: TextInputType.phone, prefixIcon: const Icon(Icons.phone_in_talk_outlined)),
        const SizedBox(height: 28),
        Text('Review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
          child: Column(children: preview.entries.map((e) {
            final isLast = e.key == preview.keys.last;
            return Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                Flexible(child: Text(e.value, textAlign: TextAlign.end, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: e.key == 'Status' ? AppColors.accentEmerald : cs.onSurface))),
              ])),
              if (!isLast) Divider(height: 1, color: Theme.of(context).dividerColor),
            ]);
          }).toList()),
        ),
        const SizedBox(height: 22),
      ]),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────

class _OptionalDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final void Function(DateTime?) onChanged;
  const _OptionalDateField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: value ?? DateTime.now(), firstDate: DateTime(1950), lastDate: DateTime(2100));
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(value == null ? label : DateFormat('dd MMM yyyy').format(value!), style: TextStyle(fontSize: 15, color: value == null ? cs.onSurfaceVariant : cs.onSurface))),
          if (value != null)
            GestureDetector(onTap: () => onChanged(null), child: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant))
          else
            Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}

class _MultilineField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  const _MultilineField({required this.controller, required this.label, required this.hint, required this.icon});

  @override
  State<_MultilineField> createState() => _MultilineFieldState();
}

class _MultilineFieldState extends State<_MultilineField> {
  final _focus = FocusNode();
  bool _focused = false, _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    widget.controller.addListener(() { final h = widget.controller.text.isNotEmpty; if (h != _hasText) setState(() => _hasText = h); });
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showLabel = _focused || _hasText;
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: _focused ? AppColors.accentEmerald : Theme.of(context).dividerColor, width: _focused ? 1.5 : 1)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 14, top: 14), child: Icon(widget.icon, color: cs.onSurfaceVariant, size: 20)),
          Expanded(child: TextFormField(controller: widget.controller, focusNode: _focus, maxLines: 3, style: TextStyle(color: cs.onSurface, fontSize: 15),
            decoration: InputDecoration(hintText: showLabel ? widget.hint : widget.label, hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: showLabel ? 14 : 15), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: const EdgeInsets.fromLTRB(8, 14, 16, 14)))),
        ]),
      ),
      if (showLabel) Positioned(top: -9, left: 12, child: Container(color: cs.surfaceContainerHighest, padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(widget.label, style: TextStyle(color: _focused ? AppColors.accentEmerald : cs.onSurfaceVariant, fontSize: 12)))),
    ]);
  }
}
