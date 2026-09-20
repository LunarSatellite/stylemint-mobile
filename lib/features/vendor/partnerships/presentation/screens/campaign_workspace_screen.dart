// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CampaignWorkspaceScreen extends ConsumerStatefulWidget {
  const CampaignWorkspaceScreen({required this.briefId, super.key});
  final String briefId;

  @override
  ConsumerState<CampaignWorkspaceScreen> createState() =>
      _CampaignWorkspaceScreenState();
}

class _CampaignWorkspaceScreenState
    extends ConsumerState<CampaignWorkspaceScreen> {
  Map<String, dynamic>? workspace;
  bool loading = true;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ref
          .read(apiClientProvider)
          .get('/v1/vendor/campaign-workspaces');
      final rows = (data as List<dynamic>).whereType<Map<String, dynamic>>();
      workspace = rows.cast<Map<String, dynamic>?>().firstWhere(
        (x) => x?['brandBriefId']?.toString() == widget.briefId,
        orElse: () => null,
      );
    } catch (_) {
      error = 'Campaign Studio is unavailable right now.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> create() async {
    final name = TextEditingController(text: 'Creator-led campaign');
    final budget = TextEditingController(text: '1000');
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121A24),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open campaign workspace',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Budget is capped in the backend and activation always requires a separate approval.',
              style: TextStyle(color: DesignTokens.textLight, height: 1.4),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Campaign name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budget,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Maximum budget (NPR)',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, {
                  'name': name.text,
                  'budget': budget.text,
                }),
                child: const Text('Create governed workspace'),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    await mutate(
      '',
      body: {
        'brandBriefId': widget.briefId,
        'name': result['name'],
        'budgetAmount': double.tryParse(result['budget'] ?? '') ?? 0,
        'budgetCurrency': 'NPR',
      },
    );
  }

  Future<void> configure() async {
    final reel = TextEditingController();
    final creator = TextEditingController();
    final source = TextEditingController();
    final caption = TextEditingController();
    final controls = TextEditingController();
    var channel = 'Instagram';
    var metric = 'clicks';
    var holdout = 10.0;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121A24),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bind creative + experiment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use real Reel and creator IDs. Control Reel IDs are required before measured lift can be reported.',
                  style: TextStyle(color: DesignTokens.textLight, height: 1.4),
                ),
                const SizedBox(height: 14),
                for (final item in [
                  (reel, 'Reel ID'),
                  (creator, 'Creator account ID'),
                  (source, 'Video URL (optional)'),
                  (caption, 'Caption'),
                  (controls, 'Control Reel IDs, comma separated'),
                ]) ...[
                  TextField(
                    controller: item.$1,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: item.$2),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: channel,
                        dropdownColor: const Color(0xFF182330),
                        decoration: const InputDecoration(labelText: 'Channel'),
                        items:
                            const ['Instagram', 'Facebook', 'TikTok', 'YouTube']
                                .map(
                                  (x) => DropdownMenuItem(
                                    value: x,
                                    child: Text(x),
                                  ),
                                )
                                .toList(),
                        onChanged: (x) => setSheetState(() => channel = x!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: metric,
                        dropdownColor: const Color(0xFF182330),
                        decoration: const InputDecoration(
                          labelText: 'Primary metric',
                        ),
                        items: const ['clicks', 'engagements', 'impressions']
                            .map(
                              (x) => DropdownMenuItem(value: x, child: Text(x)),
                            )
                            .toList(),
                        onChanged: (x) => setSheetState(() => metric = x!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Holdout ${holdout.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Slider(
                  value: holdout,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  onChanged: (x) => setSheetState(() => holdout = x),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, {
                      'reelId': reel.text.trim(),
                      'creatorAccountId': creator.text.trim(),
                      'sourceVideoUrl': source.text.trim(),
                      'caption': caption.text.trim(),
                      'controlReelIds': controls.text
                          .split(',')
                          .map((x) => x.trim())
                          .where((x) => x.isNotEmpty)
                          .toList(),
                      'channel': channel,
                      'metric': metric,
                      'holdout': holdout,
                    }),
                    child: const Text('Lock configuration'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    await mutate(
      '/${workspace!['id']}/configuration',
      put: true,
      body: {
        'creativeVariantsJson':
            '[{"reelId":"${result['reelId']}","creatorAccountId":"${result['creatorAccountId']}","sourceVideoUrl":"${result['sourceVideoUrl']}","caption":${_jsonString(result['caption'] as String)}}]',
        'channelsJson': '[{"platform":"${result['channel']}"}]',
        'experimentJson':
            '{"primaryMetric":"${result['metric']}","holdoutPercent":${result['holdout']},"controlReelIds":${_jsonArray(result['controlReelIds'] as List<String>)}}',
      },
    );
  }

  String _jsonString(String value) =>
      '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
  String _jsonArray(List<String> values) =>
      '[${values.map(_jsonString).join(',')}]';

  Future<void> mutate(
    String suffix, {
    Map<String, dynamic>? body,
    bool put = false,
  }) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final path = '/v1/vendor/campaign-workspaces$suffix';
      if (put) {
        await ref.read(apiClientProvider).put(path, data: body);
      } else {
        await ref.read(apiClientProvider).post(path, data: body);
      }
      await load();
    } catch (_) {
      if (mounted)
        setState(
          () => error =
              'The server refused this step. Check IDs, connection permissions, and campaign state.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DesignTokens.bgAppFoundation,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text('Campaign Studio'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
              children: [
                _hero(),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _notice(
                      error!,
                      Icons.error_outline,
                      const Color(0xFFFFB4AB),
                    ),
                  ),
                const SizedBox(height: 16),
                if (workspace == null) _empty() else _dashboard(),
              ],
            ),
          ),
  );

  Widget _hero() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [Color(0xFF143C35), Color(0xFF112333), Color(0xFF291B3D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [BoxShadow(color: Color(0x4424D3A8), blurRadius: 28)],
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome_rounded, color: Color(0xFF67F5C7), size: 34),
        SizedBox(height: 18),
        Text(
          'Creative command center',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Turn an approved brief into traceable creative, controlled distribution and measured incremental lift.',
          style: TextStyle(color: DesignTokens.textLight, height: 1.45),
        ),
      ],
    ),
  );

  Widget _empty() => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'No workspace yet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create one governed workspace for this brief. Every later step is auditable and reversible until activation.',
          style: TextStyle(color: DesignTokens.textLight, height: 1.4),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : create,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create workspace'),
          ),
        ),
      ],
    ),
  );

  Widget _dashboard() {
    final state = (workspace!['state'] as num?)?.toInt() ?? 0;
    final labels = [
      'Draft',
      'Ready for approval',
      'Approved',
      'Active',
      'Paused',
      'Completed',
      'Cancelled',
    ];
    final next = switch (state) {
      0 => ('Configure creative', configure),
      1 => ('Approve campaign', () => mutate('/${workspace!['id']}/approve')),
      2 => (
        'Activate through Reach',
        () => mutate('/${workspace!['id']}/activate'),
      ),
      3 => (
        'Refresh measured lift',
        () => mutate('/${workspace!['id']}/outcomes/refresh'),
      ),
      _ => ('Refresh workspace', load),
    };
    return Column(
      children: [
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workspace!['name']?.toString() ?? 'Campaign',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _pill(labels[state.clamp(0, labels.length - 1)]),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      'Budget',
                      '${workspace!['budgetCurrency']} ${workspace!['budgetAmount']}',
                    ),
                  ),
                  Expanded(
                    child: _stat(
                      'Spent',
                      '${workspace!['budgetCurrency']} ${workspace!['spentAmount']}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: (state / 5).clamp(0, 1),
                minHeight: 7,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: Colors.white12,
                color: const Color(0xFF67F5C7),
              ),
              const SizedBox(height: 10),
              Text(
                'Brief → Creative → Approval → Reach → Evidence',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .62),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (state >= 3)
          _notice(
            'Activation is backed by Reach publish job IDs. Lift refresh remains unavailable until both treatment and holdout metrics are ingested.',
            Icons.verified_user_outlined,
            const Color(0xFF67F5C7),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : next.$2,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(next.$1),
          ),
        ),
      ],
    );
  }

  Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF121A24),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white10),
    ),
    child: child,
  );
  Widget _notice(String text, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: .25)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: DesignTokens.textLight, height: 1.4),
          ),
        ),
      ],
    ),
  );
  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFF67F5C7).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF67F5C7),
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
    ),
  );
  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: DesignTokens.textMuted, fontSize: 12),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
