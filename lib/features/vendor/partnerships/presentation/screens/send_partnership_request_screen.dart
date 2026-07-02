import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor → Partnerships → "Send Partnership Requests". Backed by the real
/// `POST /v1/vendor/partnerships/invite`. Creator selection and commission
/// rate map directly onto the request body; the message is sent as a
/// best-effort extra field the documented contract doesn't include (product
/// decision — the backend most likely ignores it rather than rejects the
/// request). "Upload Document" has no transport at all on this endpoint —
/// there's no file/multipart field on the invite contract — so the picked
/// file stays local and is never actually sent anywhere.
class SendPartnershipRequestScreen extends ConsumerStatefulWidget {
  const SendPartnershipRequestScreen({super.key});

  @override
  ConsumerState<SendPartnershipRequestScreen> createState() =>
      _SendPartnershipRequestScreenState();
}

class _SendPartnershipRequestScreenState
    extends ConsumerState<SendPartnershipRequestScreen> {
  CreatorInvite? _selectedCreator;
  final _commissionCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  PlatformFile? _termsDocument;

  @override
  void dispose() {
    _commissionCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _termsDocument = result.files.first);
    }
  }

  Future<void> _selectCreator() async {
    final creator = await showModalBottomSheet<CreatorInvite>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CreatorPickerSheet(
        selectedCreatorId: _selectedCreator?.creatorAccountId,
      ),
    );
    if (creator != null) setState(() => _selectedCreator = creator);
  }

  bool get _canSubmit =>
      _selectedCreator != null && double.tryParse(_commissionCtrl.text) != null;

  static String _formatFollowers(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}m';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  void _submit() {
    final creator = _selectedCreator;
    final rate = double.tryParse(_commissionCtrl.text);
    if (creator == null || rate == null) return;
    ref.read(inviteCreatorNotifierProvider.notifier).invite(
      creatorProfileId: creator.creatorAccountId,
      commissionMinPercent: rate / 100,
      commissionMaxPercent: rate / 100,
      message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inviteState = ref.watch(inviteCreatorNotifierProvider);
    final isSubmitting = inviteState.maybeWhen(
      submitting: () => true,
      orElse: () => false,
    );

    ref.listen<InviteState>(inviteCreatorNotifierProvider, (_, next) {
      next.maybeWhen(
        success: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partnership request sent!')),
          );
          ref.read(inviteCreatorNotifierProvider.notifier).reset();
          Navigator.of(context).pop();
        },
        failure: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send partnership request.')),
          );
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Send Partnership Request', style: DesignTokens.oneLinerSemibold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _selectCreator,
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.s16),
                decoration: DesignTokens.cardDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: DesignTokens.bgAppBodyLight,
                      backgroundImage: _selectedCreator?.avatarUrl != null
                          ? NetworkImage(_selectedCreator!.avatarUrl!)
                          : null,
                      child: _selectedCreator?.avatarUrl == null
                          ? const Icon(Icons.person, color: DesignTokens.textMuted, size: 28)
                          : null,
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCreator?.label ?? 'Select Creator',
                            style: DesignTokens.mediumSemibold,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCreator != null
                                ? [
                                    if (_selectedCreator!.handle != null)
                                      '@${_selectedCreator!.handle}',
                                    if (_selectedCreator!.niches.isNotEmpty)
                                      _selectedCreator!.niches.join(', '),
                                  ].join(' • ')
                                : 'Search and select the creator you want send a partnership request',
                            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_selectedCreator != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: DesignTokens.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatFollowers(_selectedCreator!.followerCount ?? 0)} Followers',
                                  style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: DesignTokens.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            TextField(
              controller: _commissionCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: DesignTokens.oneLinerRegular,
              decoration: DesignTokens.inputDecoration(labelText: 'Proposed Commission Rate'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.s16),
            TextField(
              controller: _messageCtrl,
              maxLines: 6,
              style: DesignTokens.oneLinerRegular,
              decoration: DesignTokens.inputDecoration(labelText: 'Why this partnership message'),
            ),
            const SizedBox(height: DesignTokens.s20),
            Text('Partnership Terms', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s12),
            if (_termsDocument != null)
              _DocumentChip(
                document: _termsDocument!,
                onRemove: () => setState(() => _termsDocument = null),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickDocument,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DesignTokens.borderDefault),
                  minimumSize: const Size(double.infinity, DesignTokens.buttonHeight),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.upload_outlined, color: DesignTokens.textWhite),
                label: Text('Upload Document', style: DesignTokens.mediumSemibold),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s12,
            DesignTokens.s16,
            DesignTokens.s16,
          ),
          child: SizedBox(
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: _canSubmit && !isSubmitting ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                disabledBackgroundColor: DesignTokens.primaryGreen.withValues(alpha: 0.4),
                shape: const StadiumBorder(),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Send Invitation',
                          style: DesignTokens.smallRegular.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, color: Colors.black, size: 18),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Picked document chip ───────────────────────────────────────────────────

class _DocumentChip extends StatelessWidget {
  const _DocumentChip({required this.document, required this.onRemove});

  final PlatformFile document;
  final VoidCallback onRemove;

  String get _sizeLabel {
    final mb = document.size / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
    final kb = document.size / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: const Icon(Icons.description_outlined, color: DesignTokens.textWhite, size: 20),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: DesignTokens.mediumSemibold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(_sizeLabel, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: DesignTokens.textMuted),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// ─── Creator picker sheet ───────────────────────────────────────────────────

class _CreatorPickerSheet extends ConsumerStatefulWidget {
  const _CreatorPickerSheet({this.selectedCreatorId});

  final String? selectedCreatorId;

  @override
  ConsumerState<_CreatorPickerSheet> createState() => _CreatorPickerSheetState();
}

class _CreatorPickerSheetState extends ConsumerState<_CreatorPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creatorSearchNotifierProvider.notifier).searchCreators();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creatorSearchNotifierProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: DesignTokens.s8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Search & Select Creator', style: DesignTokens.mediumSemibold),
                  IconButton(
                    icon: const Icon(Icons.close, color: DesignTokens.textWhite),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s8,
              ),
              child: TextField(
                controller: _searchCtrl,
                style: DesignTokens.oneLinerRegular,
                decoration: DesignTokens.inputDecoration(
                  hintText: 'Search Creator Name or Handle',
                  suffixIcon: const Icon(Icons.search, color: DesignTokens.inputFieldPlaceholder),
                ),
                onChanged: (val) =>
                    ref.read(creatorSearchNotifierProvider.notifier).searchCreators(query: val),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Expanded(
              child: state.when(
                initial: _loader,
                loadInProgress: _loader,
                loadSuccess: (creators) => creators.isEmpty
                    ? Center(
                        child: Text(
                          'No creators found.',
                          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
                        itemCount: creators.length,
                        separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s4),
                        itemBuilder: (_, i) {
                          final c = creators[i];
                          final isSelected = c.creatorAccountId == widget.selectedCreatorId;
                          final niche = c.niches.isNotEmpty ? c.niches.join(', ') : null;
                          return _CreatorPickerRow(
                            creator: c,
                            niche: niche,
                            isSelected: isSelected,
                            onTap: () => Navigator.of(context).pop(c),
                          );
                        },
                      ),
                loadFailure: (_) => Center(
                  child: Text(
                    'Failed to load creators.',
                    style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _CreatorPickerRow extends StatelessWidget {
  const _CreatorPickerRow({
    required this.creator,
    required this.niche,
    required this.isSelected,
    required this.onTap,
  });

  final CreatorInvite creator;
  final String? niche;
  final bool isSelected;
  final VoidCallback onTap;

  String _formatFollowers(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}m';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF0E3A22) : Colors.transparent,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: DesignTokens.bgAppBodyLight,
                backgroundImage: creator.avatarUrl != null
                    ? NetworkImage(creator.avatarUrl!)
                    : null,
                child: creator.avatarUrl == null
                    ? const Icon(Icons.person, color: DesignTokens.textMuted)
                    : null,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.label,
                      style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.textWhite),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (creator.handle != null) '@${creator.handle}',
                        if (niche != null) niche,
                      ].join(' • '),
                      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: DesignTokens.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatFollowers(creator.followerCount ?? 0)} Followers',
                          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.check_circle, color: DesignTokens.primaryGreen, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
