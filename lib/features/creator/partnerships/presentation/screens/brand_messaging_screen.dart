import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── Args ─────────────────────────────────────────────────────────────────────

class BrandMessagingArgs {
  const BrandMessagingArgs({
    required this.brandName,
    required this.rating,
    required this.category,
  });

  final String brandName;
  final double rating;
  final String category;
}

// ─── Chat item model ──────────────────────────────────────────────────────────

class _ChatItem {
  const _ChatItem.message({
    required this.text,
    required this.isSent,
    required this.time,
    this.isSeen = false,
  })  : isDateDivider = false,
        dividerLabel = null;

  const _ChatItem.divider(String label)
      : isDateDivider = true,
        dividerLabel = label,
        text = '',
        isSent = false,
        time = '',
        isSeen = false;

  final bool isDateDivider;
  final String? dividerLabel;
  final String text;
  final bool isSent;
  final String time;
  final bool isSeen;
}

// ─── Initial mock messages ────────────────────────────────────────────────────

final _initialMessages = <_ChatItem>[
  _ChatItem.message(
    text:
        "We'd love to explore a potential collaboration with Nike. Would you be open to a quick call this week?",
    isSent: false,
    time: '11:05',
  ),
  _ChatItem.message(
    text:
        "Oh wow, this is amazing! I've been a huge Nike fan for years, so this feels surreal. I'd absolutely love to chat!",
    isSent: true,
    time: '11:05',
    isSeen: true,
  ),
  _ChatItem.message(
    text:
        "I'm free Thursday or Friday afternoon — whichever works best for your team.",
    isSent: true,
    time: '11:05',
    isSeen: true,
  ),
  const _ChatItem.divider('Today'),
  _ChatItem.message(
    text:
        "Perfect! Let's lock in Friday at 2 PM. We'll send over a calendar invite shortly. Looking forward to connecting!",
    isSent: false,
    time: '11:05',
  ),
  _ChatItem.message(
    text: "Sounds great, I'll be there! Thanks so much for reaching out. 🙌",
    isSent: true,
    time: '11:05',
    isSeen: true,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class BrandMessagingScreen extends StatefulWidget {
  const BrandMessagingScreen({super.key, required this.args});

  final BrandMessagingArgs args;

  @override
  State<BrandMessagingScreen> createState() => _BrandMessagingScreenState();
}

class _BrandMessagingScreenState extends State<BrandMessagingScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final List<_ChatItem> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List<_ChatItem>.from(_initialMessages);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatItem.message(
        text: text,
        isSent: true,
        time: 'Now',
      ));
      _msgCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        unawaited(_scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16, vertical: DesignTokens.s16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final item = _messages[i];
                if (item.isDateDivider) {
                  return _DateDivider(label: item.dividerLabel!);
                }
                return _MessageBubble(msg: item);
              },
            ),
          ),
          _InputBar(controller: _msgCtrl, onSend: _send),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final args = widget.args;
    final lower = args.brandName.toLowerCase();
    final isNike = lower.contains('nike');
    final isSephora = lower.contains('sephora');

    return AppBar(
      backgroundColor: DesignTokens.bgAppFoundation,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: DesignTokens.textWhite,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Brand logo
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: isNike
                ? const Text(
                    '✓',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  )
                : isSephora
                    ? const Text(
                        'S',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        args.brandName.isNotEmpty
                            ? args.brandName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                args.brandName,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 13, color: DesignTokens.secondaryYellow),
                  const SizedBox(width: 3),
                  Text(
                    '${args.rating.toStringAsFixed(1)} · ${args.category}',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      color: DesignTokens.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final _ChatItem msg;

  @override
  Widget build(BuildContext context) {
    final isSent = msg.isSent;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Align(
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 252),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: isSent
                  ? DesignTokens.primaryGreen
                  : const Color(0xFF2C2C2E),
              borderRadius: isSent
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(4),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: DesignTokens.textWhite,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.time,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 11,
                        color: isSent
                            ? Colors.white.withOpacity(0.7)
                            : DesignTokens.textMuted,
                        height: 1.2,
                      ),
                    ),
                    if (isSent) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.done_all_rounded,
                        size: 13,
                        color: msg.isSeen
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            color: DesignTokens.textLight,
          ),
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16, DesignTokens.s12, DesignTokens.s16, DesignTokens.s16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF52525C)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            color: DesignTokens.textWhite,
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Placeholder',
                            hintStyle: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 14,
                              color: DesignTokens.textMuted,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => onSend(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: Color(0xFF71717B),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: DesignTokens.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF06190E),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
