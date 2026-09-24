import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/picked_image.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/audience_target.dart';
import '../../domain/entities/push_notification.dart'
    show CommunicationStatus, OpenOnTapTarget;
import '../providers/announcements_provider.dart';
import '../widgets/audience_selector.dart';
import '../widgets/notification_labels.dart';
import '../widgets/schedule_section.dart';

class CreateAnnouncementPage extends ConsumerStatefulWidget {
  final Announcement? editAnnouncement;
  const CreateAnnouncementPage({super.key, this.editAnnouncement});

  @override
  ConsumerState<CreateAnnouncementPage> createState() =>
      _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState
    extends ConsumerState<CreateAnnouncementPage> {
  final _titleCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _ctaLabelCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();
  final _picker = ImagePicker();
  late final quill.QuillController _quillController;

  XFile? _bannerFile;
  String? _bannerUrl;
  bool _bannerUploading = false;
  String? _bannerError;

  AudienceTarget _audience = const AudienceTarget.allCompanies();
  OpenOnTapTarget _ctaTarget = OpenOnTapTarget.none;

  bool _isScheduled = false;
  DateTime _scheduleDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 9, minute: 0);

  bool _submitting = false;

  bool get _isEditing => widget.editAnnouncement != null;

  @override
  void initState() {
    super.initState();
    final a = widget.editAnnouncement;
    quill.Document doc;
    try {
      doc = a != null
          ? quill.Document.fromJson(jsonDecode(a.content) as List)
          : quill.Document();
    } catch (_) {
      doc = quill.Document();
    }
    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    if (a != null) {
      _titleCtrl.text = a.title;
      _shortDescCtrl.text = a.shortDescription;
      _ctaLabelCtrl.text = a.ctaLabel ?? '';
      _bannerUrl = a.bannerUrl;
      _audience = a.audience;
      _ctaTarget = a.ctaTarget;
      _routeCtrl.text = a.specificPageRoute ?? '';
      if (a.scheduledAt != null) {
        _isScheduled = true;
        _scheduleDate = a.scheduledAt!;
        _scheduleTime = TimeOfDay.fromDateTime(a.scheduledAt!);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _shortDescCtrl.dispose();
    _ctaLabelCtrl.dispose();
    _routeCtrl.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _bannerFile = file;
      _bannerUploading = true;
      _bannerError = null;
    });
    try {
      final url = await ref
          .read(uploadServiceProvider)
          .uploadImage(file, folder: 'announcements');
      if (!mounted) return;
      setState(() {
        _bannerUrl = url;
        _bannerUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bannerUploading = false;
        _bannerError = e.toString();
      });
    }
  }

  DateTime get _scheduledAt => DateTime(
    _scheduleDate.year,
    _scheduleDate.month,
    _scheduleDate.day,
    _scheduleTime.hour,
    _scheduleTime.minute,
  );

  Future<void> _submit({required bool asDraft}) async {
    if (_titleCtrl.text.trim().isEmpty || _shortDescCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and short description are required'),
          backgroundColor: AppColors.dangerFill,
        ),
      );
      return;
    }
    if (_ctaTarget == OpenOnTapTarget.specificPage &&
        _routeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the page route for the button'),
          backgroundColor: AppColors.dangerFill,
        ),
      );
      return;
    }
    if (_bannerUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the banner to finish uploading'),
          backgroundColor: AppColors.dangerFill,
        ),
      );
      return;
    }
    if (_bannerError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Remove or retry the banner image that failed to upload',
          ),
          backgroundColor: AppColors.dangerFill,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final status = asDraft
          ? CommunicationStatus.draft
          : _isScheduled
          ? CommunicationStatus.scheduled
          : CommunicationStatus.published;

      final announcement = Announcement(
        id: widget.editAnnouncement?.id ?? '',
        title: _titleCtrl.text.trim(),
        shortDescription: _shortDescCtrl.text.trim(),
        content: jsonEncode(_quillController.document.toDelta().toJson()),
        bannerUrl: _bannerUrl,
        audience: _audience,
        ctaLabel: _ctaLabelCtrl.text.trim().isEmpty
            ? null
            : _ctaLabelCtrl.text.trim(),
        ctaTarget: _ctaTarget,
        specificPageRoute: _ctaTarget == OpenOnTapTarget.specificPage
            ? _routeCtrl.text.trim()
            : null,
        status: status,
        publishedAt: status == CommunicationStatus.published
            ? DateTime.now()
            : null,
        scheduledAt: _isScheduled ? _scheduledAt : null,
        createdAt: widget.editAnnouncement?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await ref.read(announcementsProvider.notifier).edit(announcement);
      } else {
        await ref.read(announcementsProvider.notifier).create(announcement);
      }
      if (!mounted) return;
      context.pop();
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Announcement' : 'Create Announcement',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _SectionLabel('Basic Information'),
            const SizedBox(height: 10),
            BrixenTextField(
              label: 'Announcement Title *',
              hint: 'Enter announcement title',
              controller: _titleCtrl,
            ),
            const SizedBox(height: 16),
            BrixenTextField(
              label: 'Short Description *',
              hint: 'A one-line summary shown in lists and previews',
              controller: _shortDescCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Full Content *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  quill.QuillSimpleToolbar(controller: _quillController),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  SizedBox(
                    height: 220,
                    child: quill.QuillEditor.basic(
                      controller: _quillController,
                      config: const quill.QuillEditorConfig(
                        padding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _SectionLabel('Announcement Banner'),
            const SizedBox(height: 10),
            _BannerPicker(
              bannerPath: _bannerFile?.path ?? _bannerUrl,
              uploading: _bannerUploading,
              error: _bannerError,
              onPick: _pickBanner,
              onRetry: _pickBanner,
              onRemove: () => setState(() {
                _bannerFile = null;
                _bannerUrl = null;
                _bannerError = null;
              }),
            ),
            const SizedBox(height: 26),
            _SectionLabel('Audience'),
            const SizedBox(height: 10),
            AudienceSelector(
              value: _audience,
              onChanged: (v) => setState(() => _audience = v),
            ),
            const SizedBox(height: 26),
            _SectionLabel('Call to Action'),
            const SizedBox(height: 10),
            BrixenTextField(
              label: 'Button Label',
              hint: 'e.g. Explore Payroll',
              controller: _ctaLabelCtrl,
            ),
            const SizedBox(height: 12),
            BrixenDropdown<OpenOnTapTarget>(
              hint: 'No Action',
              value: _ctaTarget,
              items: kCtaTargets,
              labelOf: openOnTapLabel,
              icon: Icons.touch_app_outlined,
              onChanged: (v) =>
                  setState(() => _ctaTarget = v ?? OpenOnTapTarget.none),
            ),
            if (_ctaTarget == OpenOnTapTarget.specificPage) ...[
              const SizedBox(height: 12),
              BrixenTextField(
                label: 'Page route *',
                hint: 'e.g. /billing',
                controller: _routeCtrl,
              ),
            ],
            const SizedBox(height: 26),
            _SectionLabel('Publication'),
            const SizedBox(height: 10),
            ScheduleSection(
              isScheduled: _isScheduled,
              onModeChanged: (v) => setState(() => _isScheduled = v),
              date: _scheduleDate,
              onDateChanged: (v) => setState(() => _scheduleDate = v),
              time: _scheduleTime,
              onTimeChanged: (v) => setState(() => _scheduleTime = v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ]),
          ),
          child: Row(
            children: [
              Expanded(
                child: BrixenButton(
                  label: 'Save Draft',
                  isOutlined: true,
                  onPressed: _submitting ? null : () => _submit(asDraft: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: BrixenButton(
                  label: _isScheduled ? 'Schedule' : 'Publish',
                  isLoading: _submitting,
                  onPressed: _submitting ? null : () => _submit(asDraft: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// Single-image banner upload — same immediate-upload-on-pick pattern as
/// Products' gallery, sized to the spec's recommended 2:1 ratio.
class _BannerPicker extends StatelessWidget {
  final String? bannerPath;
  final bool uploading;
  final String? error;
  final VoidCallback onPick;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  const _BannerPicker({
    required this.bannerPath,
    required this.uploading,
    required this.error,
    required this.onPick,
    required this.onRetry,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (bannerPath == null) {
      return GestureDetector(
        onTap: onPick,
        child: Container(
          width: double.infinity,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 30,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload Banner',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'JPG, PNG, WebP · Recommended 2:1',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 2,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Opacity(
              opacity: error != null ? 0.4 : 1,
              child: pickedImage(
                bannerPath!,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          if (uploading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          if (error != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: onRetry,
                child: const Center(
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _RoundIconButton(icon: Icons.swap_horiz_rounded, onTap: onPick),
                const SizedBox(width: 6),
                _RoundIconButton(icon: Icons.close_rounded, onTap: onRemove),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: Colors.white),
      ),
    );
  }
}
