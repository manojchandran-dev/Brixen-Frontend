import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/picked_image.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/session_service.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/company_selector_field.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../masters/data/datasources/product_categories_remote_datasource.dart';
import '../../../masters/data/datasources/units_remote_datasource.dart';
import '../../../masters/domain/entities/master_item.dart';
import '../../domain/entities/product.dart';
import '../providers/products_provider.dart';

/// Optional gallery — the wizard's Step 4 caps it at this many photos.
const _maxGalleryImages = 3;

/// One gallery slot: a freshly-picked local photo that's mid-upload (or
/// failed), or an already-hosted URL (freshly uploaded, or restored from an
/// existing product's saved `gallery_urls` when editing). `Step4` only ever
/// sends [url] values — [file] is purely for local preview while uploading.
class _GalleryPhoto {
  final XFile? file;
  String? url;
  bool uploading;
  String? error;

  _GalleryPhoto.local(XFile this.file)
      : url = null,
        uploading = true,
        error = null;

  _GalleryPhoto.remote(String this.url)
      : file = null,
        uploading = false,
        error = null;

  /// What to show for this tile — the local file while uploading/on error
  /// (fastest, no network round-trip), otherwise the hosted URL.
  String get previewPath => file?.path ?? url!;
}

class CreateProductPage extends ConsumerStatefulWidget {
  final bool fromMasters;
  final Product? editProduct;
  const CreateProductPage({
    super.key,
    this.fromMasters = false,
    this.editProduct,
  });

  @override
  ConsumerState<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends ConsumerState<CreateProductPage> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _submitting = false;
  String? _productId;
  Company? _selectedCompany; // superAdmin only — companyAdmin/employee use Session.companyId

  // Step 1 — Basic Info
  final _nameCtrl = TextEditingController();
  bool _loadingCategories = true;
  List<MasterItem> _categories = [];
  MasterItem? _selectedCategory;
  String? _gender;
  String? _designPattern;

  // Step 2 — Attributes
  bool _loadingUnits = true;
  List<MasterItem> _units = [];
  MasterItem? _selectedUnit;
  final _colorCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();

  // Step 3 — Pricing
  final _costPriceCtrl = TextEditingController();
  final _retailPriceCtrl = TextEditingController();
  final _wholesalePriceCtrl = TextEditingController();

  // Step 4 — Gallery & Status
  final _picker = ImagePicker();
  List<_GalleryPhoto> _gallery = [];
  String _status = 'Active';

  bool get _isEditing => widget.editProduct != null;

  /// The company this product belongs to, for every write in this wizard.
  /// superAdmin-only — companyAdmin/employee writes are scoped by
  /// `Session.companyId` automatically. Editing uses the product's own
  /// owning company (not whatever the list-page browse filter happens to be
  /// set to); creating uses the company picked in this wizard's own field.
  String? get _effectiveCompanyId {
    if (!Session.isSuperAdmin) return null;
    return _isEditing ? widget.editProduct!.companyId : _selectedCompany?.id;
  }

  static const _genders = ['Men', 'Women', 'Unisex', 'Kids'];
  static const _designPatterns = [
    'Plain',
    'Solid',
    'Striped',
    'Checked',
    'Printed',
    'Embroidered',
    'Floral',
    'Other',
  ];
  static const _statuses = ['Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    final p = widget.editProduct;
    if (p != null) {
      _productId = p.id;
      _nameCtrl.text = p.productName;
      _gender = p.gender;
      _designPattern = p.designPattern;
      _colorCtrl.text = p.color ?? '';
      _sizeCtrl.text = p.size ?? '';
      _costPriceCtrl.text = p.costPrice == 0 ? '' : p.costPrice.toString();
      _retailPriceCtrl.text = p.retailPrice == 0
          ? ''
          : p.retailPrice.toString();
      _wholesalePriceCtrl.text = p.wholesalePrice == 0
          ? ''
          : p.wholesalePrice.toString();
      _gallery = p.galleryPaths.map((url) => _GalleryPhoto.remote(url)).toList();
      _status = p.status;
    }
    _loadCategories();
    _loadUnits();
  }

  /// superAdmin sees only the selected company's product categories — a
  /// category belongs to one company, so listing every company's categories
  /// together would let a product get tagged with a category it can't
  /// actually use. companyAdmin/employee are already scoped server-side to
  /// their own company (`CompanyScopeInterceptor` attaches `Session.companyId`
  /// regardless of the explicit `companyId` here being null), so this only
  /// changes behavior for superAdmin.
  Future<void> _loadCategories() async {
    if (Session.isSuperAdmin && _effectiveCompanyId == null) {
      // No company chosen yet (create flow) — nothing to scope the list to.
      setState(() {
        _categories = [];
        _selectedCategory = null;
        _loadingCategories = false;
      });
      return;
    }
    setState(() => _loadingCategories = true);
    try {
      final list = await productCategoriesRemoteDatasource.getAll(
        companyId: _effectiveCompanyId,
      );
      if (!mounted) return;
      setState(() {
        _categories = list.where((c) => c.isActive).toList();
        _loadingCategories = false;
        final id = _isEditing ? widget.editProduct!.categoryId : _selectedCategory?.id;
        _selectedCategory = id == null
            ? null
            : _categories.where((c) => c.id == id).firstOrNull;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categories = [];
        _loadingCategories = false;
      });
    }
  }

  /// superAdmin sees only the selected company's units — same reasoning as
  /// [_loadCategories]: a unit belongs to one company, so this only changes
  /// behavior for superAdmin (companyAdmin/employee stay scoped server-side).
  Future<void> _loadUnits() async {
    if (Session.isSuperAdmin && _effectiveCompanyId == null) {
      setState(() {
        _units = [];
        _selectedUnit = null;
        _loadingUnits = false;
      });
      return;
    }
    setState(() => _loadingUnits = true);
    try {
      final list = await unitsRemoteDatasource.getAll(companyId: _effectiveCompanyId);
      if (!mounted) return;
      setState(() {
        _units = list;
        _loadingUnits = false;
        final id = _isEditing ? widget.editProduct!.unitId : _selectedUnit?.id;
        _selectedUnit = id == null ? null : _units.where((u) => u.id == id).firstOrNull;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _units = [];
        _loadingUnits = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _colorCtrl.dispose();
    _sizeCtrl.dispose();
    _costPriceCtrl.dispose();
    _retailPriceCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    super.dispose();
  }

  GlobalKey<FormState> get _currentFormKey =>
      [_step1Key, _step2Key, _step3Key, _step4Key][_currentStep];

  void _back() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _pickGalleryImages() async {
    final remaining = _maxGalleryImages - _gallery.length;
    if (remaining <= 0) return;
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    final accepted = files.take(remaining).toList();
    final photos = accepted.map((f) => _GalleryPhoto.local(f)).toList();
    setState(() => _gallery = [..._gallery, ...photos]);
    for (final photo in photos) {
      _uploadPhoto(photo);
    }
    if (files.length > accepted.length && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only $_maxGalleryImages photos allowed — added the first $remaining.'),
          backgroundColor: AppColors.dangerFill,
        ),
      );
    }
  }

  Future<void> _pickFromCamera() async {
    if (_gallery.length >= _maxGalleryImages) return;
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) return;
    final photo = _GalleryPhoto.local(file);
    setState(() => _gallery = [..._gallery, photo]);
    _uploadPhoto(photo);
  }

  /// Uploads one picked photo via `POST /uploads` and fills in its hosted
  /// URL — fired immediately when the photo is added, so by the time the
  /// user reaches "Save Changes" every tile is either already uploaded or
  /// still visibly in progress (submission is blocked while any is).
  Future<void> _uploadPhoto(_GalleryPhoto photo) async {
    try {
      final url = await ref.read(uploadServiceProvider).uploadImage(
            photo.file!,
            folder: 'products',
          );
      if (!mounted || !_gallery.contains(photo)) return;
      setState(() {
        photo.url = url;
        photo.uploading = false;
      });
    } catch (e) {
      if (!mounted || !_gallery.contains(photo)) return;
      setState(() {
        photo.uploading = false;
        photo.error = e.toString();
      });
    }
  }

  void _retryUpload(int index) {
    final photo = _gallery[index];
    setState(() {
      photo.uploading = true;
      photo.error = null;
    });
    _uploadPhoto(photo);
  }

  void _removeGalleryImage(int index) {
    setState(() => _gallery = [..._gallery]..removeAt(index));
  }

  void _showGallerySourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Product Photos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromCamera();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickGalleryImages();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Each step is persisted to its own wizard endpoint as soon as the user
  // advances past it — mirrors the Employees/Companies registration flow.
  Future<void> _handleNext() async {
    if (!_currentFormKey.currentState!.validate()) return;
    if (_currentStep == 0 && (_gender == null || _gender!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a gender'),
          backgroundColor: AppColors.dangerFill,
        ),
      );
      return;
    }
    if (_currentStep == 0 && !_isEditing && Session.isSuperAdmin && _selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company'),
          backgroundColor: AppColors.dangerFill,
        ),
      );
      return;
    }
    if (_currentStep == 3 && _gallery.any((p) => p.uploading)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for photos to finish uploading'),
          backgroundColor: AppColors.dangerFill,
        ),
      );
      return;
    }
    if (_currentStep == 3 && _gallery.any((p) => p.error != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remove or retry the photo(s) that failed to upload'),
          backgroundColor: AppColors.dangerFill,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final notifier = ref.read(productsProvider.notifier);
    try {
      switch (_currentStep) {
        case 0:
          if (_isEditing) {
            final merged = widget.editProduct!.copyWith(
              productName: _nameCtrl.text.trim(),
              categoryId: _selectedCategory?.id,
              category: _selectedCategory?.name ?? '',
              gender: _gender,
              designPattern: _designPattern,
            );
            await notifier.updateProduct(merged, companyId: _effectiveCompanyId);
            _productId = widget.editProduct!.id;
          } else {
            final basic = Product(
              id: '',
              productCode: '',
              productName: _nameCtrl.text.trim(),
              categoryId: _selectedCategory?.id,
              category: _selectedCategory?.name ?? '',
              gender: _gender ?? '',
              designPattern: _designPattern,
              costPrice: 0,
              retailPrice: 0,
              wholesalePrice: 0,
              createdAt: DateTime.now(),
            );
            final created = await notifier.createStep1(
              basic,
              companyId: (Session.isSuperAdmin ? _selectedCompany!.id : Session.companyId)!,
            );
            _productId = created.id;
          }
          setState(() => _currentStep = 1);
        case 1:
          final attrs = Product(
            id: _productId!,
            productCode: '',
            productName: '',
            category: '',
            gender: '',
            unitId: _selectedUnit?.id,
            color: _colorCtrl.text.trim().isEmpty
                ? null
                : _colorCtrl.text.trim(),
            size: _sizeCtrl.text.trim().isEmpty
                ? null
                : _sizeCtrl.text.trim(),
            costPrice: 0,
            retailPrice: 0,
            wholesalePrice: 0,
            createdAt: DateTime.now(),
          );
          await notifier.updateStep2(_productId!, attrs, companyId: _effectiveCompanyId);
          setState(() => _currentStep = 2);
        case 2:
          final pricing = Product(
            id: _productId!,
            productCode: '',
            productName: '',
            category: '',
            gender: '',
            costPrice: double.tryParse(_costPriceCtrl.text) ?? 0,
            retailPrice: double.tryParse(_retailPriceCtrl.text) ?? 0,
            wholesalePrice: double.tryParse(_wholesalePriceCtrl.text) ?? 0,
            createdAt: DateTime.now(),
          );
          await notifier.updateStep3(_productId!, pricing, companyId: _effectiveCompanyId);
          setState(() => _currentStep = 3);
        case 3:
          final galleryAndStatus = Product(
            id: _productId!,
            productCode: '',
            productName: '',
            category: '',
            gender: '',
            costPrice: 0,
            retailPrice: 0,
            wholesalePrice: 0,
            galleryPaths: _gallery.map((p) => p.url).whereType<String>().toList(),
            status: _status,
            createdAt: DateTime.now(),
          );
          await notifier.updateStep4(_productId!, galleryAndStatus, companyId: _effectiveCompanyId);
          if (!mounted) return;
          if (widget.fromMasters) {
            context.pop();
          } else {
            context.go(AppRouter.products);
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.dangerFill,
          ),
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
          onTap: () {
            if (_currentStep == 0) {
              widget.fromMasters
                  ? context.pop()
                  : context.go(AppRouter.products);
            } else {
              _back();
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.silverGradient : null,
              color: isDark ? null : AppColors.brand,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppColors.shadows([
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: isDark ? AppColors.black : AppColors.white,
            ),
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
                      onTap: () => context.pop(),
                      child: Text(
                        'Menu',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Products',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      _isEditing ? 'Edit' : 'Create',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                _isEditing ? 'Edit Product' : 'New Product',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            Text(
              'Step ${_currentStep + 1} of 4 — ${['Basic Info', 'Attributes', 'Pricing', 'Gallery & Status'][_currentStep]}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(
            currentStep: _currentStep,
            labels: const ['Basic', 'Attrs', 'Pricing', 'Gallery'],
            accentColor: AppColors.brand,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: _buildStep(),
              ),
            ),
          ),
          _NavBar(
            currentStep: _currentStep,
            submitting: _submitting,
            isEditing: _isEditing,
            onBack: _back,
            onContinue: _handleNext,
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _Step1(
          formKey: _step1Key,
          nameCtrl: _nameCtrl,
          loadingCategories: _loadingCategories,
          categories: _categories,
          selectedCategory: _selectedCategory,
          onCategoryChanged: (v) => setState(() => _selectedCategory = v),
          gender: _gender,
          genders: _genders,
          designPattern: _designPattern,
          designPatterns: _designPatterns,
          onGenderChanged: (v) => setState(() => _gender = v),
          onDesignPatternChanged: (v) => setState(() => _designPattern = v),
          showCompanyField: !_isEditing && Session.isSuperAdmin,
          selectedCompany: _selectedCompany,
          onCompanyChanged: (c) {
            setState(() => _selectedCompany = c);
            _loadCategories();
            _loadUnits();
          },
        );
      case 1:
        return _Step2(
          formKey: _step2Key,
          loadingUnits: _loadingUnits,
          units: _units,
          selectedUnit: _selectedUnit,
          onUnitChanged: (v) => setState(() => _selectedUnit = v),
          colorCtrl: _colorCtrl,
          sizeCtrl: _sizeCtrl,
        );
      case 2:
        return _Step3(
          formKey: _step3Key,
          costPriceCtrl: _costPriceCtrl,
          retailPriceCtrl: _retailPriceCtrl,
          wholesalePriceCtrl: _wholesalePriceCtrl,
        );
      default:
        return _Step4(
          formKey: _step4Key,
          gallery: _gallery,
          onPickImages: _showGallerySourceSheet,
          onRemoveImage: _removeGalleryImage,
          onRetryImage: _retryUpload,
          status: _status,
          statuses: _statuses,
          onStatusChanged: (v) => setState(() => _status = v ?? _status),
          preview: {
            'Product': _nameCtrl.text.trim().isEmpty
                ? '—'
                : _nameCtrl.text.trim(),
            'Category': _selectedCategory?.name ?? '—',
            'Cost Price':
                '₹${_costPriceCtrl.text.isEmpty ? '0.00' : _costPriceCtrl.text}',
            'Retail Price':
                '₹${_retailPriceCtrl.text.isEmpty ? '0.00' : _retailPriceCtrl.text}',
            'Wholesale Price':
                '₹${_wholesalePriceCtrl.text.isEmpty ? '0.00' : _wholesalePriceCtrl.text}',
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
  const _StepIndicator({
    required this.currentStep,
    required this.labels,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(labels.length, (i) {
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
                                color: i <= currentStep
                                    ? accentColor
                                    : Theme.of(context).dividerColor,
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (done || active)
                                  ? accentColor
                                  : cs.surfaceContainerHighest,
                              border: Border.all(
                                color: (done || active)
                                    ? accentColor
                                    : Theme.of(context).dividerColor,
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: done
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? Colors.white
                                            : cs.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                          ),
                          if (i < labels.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i < currentStep
                                    ? accentColor
                                    : Theme.of(context).dividerColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
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

// ── Nav Bar ────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int currentStep;
  final bool submitting, isEditing;
  final VoidCallback onBack, onContinue;
  const _NavBar({
    required this.currentStep,
    required this.submitting,
    required this.isEditing,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          if (currentStep > 0) ...[
            Expanded(
              child: BrixenButton(
                label: 'Back',
                isOutlined: true,
                onPressed: onBack,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: BrixenButton(
              label: currentStep == 3
                  ? (isEditing ? 'Save Changes' : 'Create Product')
                  : 'Continue',
              isLoading: submitting,
              onPressed: submitting ? null : onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Basic Info ─────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final bool loadingCategories;
  final List<MasterItem> categories;
  final MasterItem? selectedCategory;
  final void Function(MasterItem?) onCategoryChanged;
  final String? gender;
  final List<String> genders;
  final String? designPattern;
  final List<String> designPatterns;
  final void Function(String?) onGenderChanged, onDesignPatternChanged;
  final bool showCompanyField;
  final Company? selectedCompany;
  final void Function(Company?) onCompanyChanged;

  const _Step1({
    required this.formKey,
    required this.nameCtrl,
    required this.loadingCategories,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.gender,
    required this.genders,
    required this.designPattern,
    required this.designPatterns,
    required this.onGenderChanged,
    required this.onDesignPatternChanged,
    required this.showCompanyField,
    required this.selectedCompany,
    required this.onCompanyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          if (showCompanyField) ...[
            CompanySelectorField(value: selectedCompany, onChanged: onCompanyChanged),
            const SizedBox(height: 22),
          ],
          BrixenTextField(
            label: 'Product Name *',
            hint: 'Enter product name',
            controller: nameCtrl,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.checkroom_rounded),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 22),
          BrixenDropdown<MasterItem>(
            hint: loadingCategories
                ? 'Loading categories…'
                : (categories.isEmpty
                      ? (showCompanyField && selectedCompany == null
                            ? 'Select a company first'
                            : 'No categories yet')
                      : 'Category *'),
            value: categories.contains(selectedCategory)
                ? selectedCategory
                : null,
            items: categories,
            labelOf: (c) => c.name,
            icon: Icons.category_outlined,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 22),
          BrixenDropdown<String>(
            hint: 'Gender *',
            value: gender,
            items: genders,
            labelOf: (s) => s,
            icon: Icons.wc_rounded,
            onChanged: onGenderChanged,
          ),
          const SizedBox(height: 22),
          BrixenDropdown<String>(
            hint: 'Design / Pattern',
            value: designPattern,
            items: designPatterns,
            labelOf: (s) => s,
            icon: Icons.texture_rounded,
            onChanged: onDesignPatternChanged,
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// ── Step 2: Attributes & Unit ──────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool loadingUnits;
  final List<MasterItem> units;
  final MasterItem? selectedUnit;
  final void Function(MasterItem?) onUnitChanged;
  final TextEditingController colorCtrl, sizeCtrl;

  const _Step2({
    required this.formKey,
    required this.loadingUnits,
    required this.units,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.colorCtrl,
    required this.sizeCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          BrixenDropdown<MasterItem>(
            hint: loadingUnits
                ? 'Loading units…'
                : (units.isEmpty ? 'No units yet' : 'Select unit'),
            value: units.contains(selectedUnit) ? selectedUnit : null,
            items: units,
            labelOf: (u) => u.name,
            icon: Icons.straighten_rounded,
            onChanged: onUnitChanged,
          ),
          const SizedBox(height: 22),
          BrixenTextField(
            label: 'Color',
            hint: 'e.g. Navy Blue',
            controller: colorCtrl,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.palette_outlined),
          ),
          const SizedBox(height: 22),
          BrixenTextField(
            label: 'Size',
            hint: 'e.g. M, L, 32, 34',
            controller: sizeCtrl,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.straighten_outlined),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// ── Step 3: Pricing ────────────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController costPriceCtrl,
      retailPriceCtrl,
      wholesalePriceCtrl;

  const _Step3({
    required this.formKey,
    required this.costPriceCtrl,
    required this.retailPriceCtrl,
    required this.wholesalePriceCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          BrixenTextField(
            label: 'Cost Price *',
            hint: '0.00',
            controller: costPriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 22),
          BrixenTextField(
            label: 'Retail Price *',
            hint: '0.00',
            controller: retailPriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.storefront_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 22),
          BrixenTextField(
            label: 'Wholesale Price *',
            hint: '0.00',
            controller: wholesalePriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.local_shipping_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// ── Step 4: Gallery, Status & Review ───────────────────────────────────────

class _Step4 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<_GalleryPhoto> gallery;
  final VoidCallback onPickImages;
  final void Function(int) onRemoveImage;
  final void Function(int) onRetryImage;
  final String status;
  final List<String> statuses;
  final void Function(String?) onStatusChanged;
  final Map<String, String> preview;

  const _Step4({
    required this.formKey,
    required this.gallery,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onRetryImage,
    required this.status,
    required this.statuses,
    required this.onStatusChanged,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          Text(
            'Product Gallery',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Optional — up to $_maxGalleryImages photos',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 10),
          _GalleryGrid(
            gallery: gallery,
            onAdd: onPickImages,
            onRemove: onRemoveImage,
            onRetry: onRetryImage,
          ),
          const SizedBox(height: 22),
          BrixenDropdown<String>(
            hint: 'Status',
            value: status,
            items: statuses,
            labelOf: (s) => s,
            icon: Icons.toggle_on_outlined,
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 28),
          Text(
            'Review',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest
                  : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: preview.entries.map((e) {
                final isLast = e.key == preview.keys.last;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: e.key == 'Retail Price'
                                  ? AppColors.positive
                                  : cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────

class _GalleryGrid extends StatelessWidget {
  final List<_GalleryPhoto> gallery;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final void Function(int) onRetry;
  const _GalleryGrid({
    required this.gallery,
    required this.onAdd,
    required this.onRemove,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showAddTile = gallery.length < _maxGalleryImages;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gallery.length + (showAddTile ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        if (i == gallery.length) {
          return GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? AppColors.silver : AppColors.brand)
                      .withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.add_a_photo_outlined,
                size: 26,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          );
        }
        final photo = gallery[i];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: photo.error != null ? 0.4 : 1,
                child: pickedImage(
                  photo.previewPath,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            if (photo.uploading)
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  ),
                ),
              ),
            if (photo.error != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => onRetry(i),
                  child: const Center(
                    child: Icon(Icons.refresh_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isDark ? AppColors.silver : AppColors.brand,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
