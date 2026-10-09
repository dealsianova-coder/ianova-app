import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_models.dart';
import 'seller_service.dart';

class SellerInboxView extends StatefulWidget {
  const SellerInboxView({
    super.key,
    required this.session,
    required this.service,
    required this.onStatus,
    required this.onExpired,
  });

  final SellerSession session;
  final SellerService service;
  final ValueChanged<String> onStatus;
  final VoidCallback onExpired;

  @override
  State<SellerInboxView> createState() => _SellerInboxViewState();
}

class _SellerInboxViewState extends State<SellerInboxView> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  SellerThread? _thread;
  String? _error;
  bool _isSending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _apply(SellerThread thread) {
    final previous = _thread?.messages.length ?? 0;

    setState(() {
      _thread = thread;
      _error = null;
    });

    widget.onStatus(thread.status);

    if (thread.messages.length != previous) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final thread = await widget.service.fetchThread(widget.session.token);

      if (!mounted) return;

      _apply(thread);
    } on SellerApplyException catch (error) {
      if (!mounted) return;

      if (error.sessionExpired) {
        widget.onExpired();
        return;
      }

      if (!silent) {
        setState(() => _error = error.message);
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);

    try {
      final thread = await widget.service.sendMessage(
        widget.session.token,
        text,
      );

      if (!mounted) return;

      _controller.clear();
      _apply(thread);
    } on SellerApplyException catch (error) {
      if (!mounted) return;

      if (error.sessionExpired) {
        widget.onExpired();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  ({String label, String note, Color color}) _statusInfo(String status) {
    switch (status) {
      case 'approved':
        return (
          label: 'Approved',
          note: 'You can now sell on IANOVA. Manage your products in the '
              'seller area on the website.',
          color: IanovaColors.success,
        );
      case 'rejected':
        return (
          label: 'Not approved',
          note: 'Your application was not approved. Message us below if you '
              'would like us to take another look.',
          color: IanovaColors.danger,
        );
      case 'suspended':
        return (
          label: 'Suspended',
          note: 'Your seller account is paused. Message us below to find out '
              'more.',
          color: IanovaColors.danger,
        );
      default:
        return (
          label: 'Under review',
          note: 'We are reviewing your application. Replies from our team '
              'appear below.',
          color: IanovaColors.warning,
        );
    }
  }

  String _time(DateTime? value) {
    if (value == null) {
      return '';
    }

    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');

    return '${value.day}/${value.month} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    final status = thread?.status ?? widget.session.status;
    final info = _statusInfo(status);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(
            IanovaSpacing.lg,
            IanovaSpacing.sm,
            IanovaSpacing.lg,
            IanovaSpacing.sm,
          ),
          padding: const EdgeInsets.all(IanovaSpacing.lg),
          decoration: BoxDecoration(
            color: IanovaColors.soft,
            borderRadius: BorderRadius.circular(IanovaSpacing.radiusLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      thread?.businessName.isNotEmpty == true
                          ? thread!.businessName
                          : widget.session.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: info.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      info.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                info.note,
                style: const TextStyle(
                  color: IanovaColors.secondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _buildMessages(thread),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              IanovaSpacing.lg,
              IanovaSpacing.sm,
              IanovaSpacing.lg,
              IanovaSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Message the IANOVA team',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: IanovaSpacing.sm),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSending ? null : _send,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: IanovaColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          IanovaSpacing.radiusMedium,
                        ),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessages(SellerThread? thread) {
    if (thread == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(IanovaSpacing.xl),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: IanovaColors.secondary),
                    ),
                  ),
          ),
        ],
      );
    }

    if (thread.messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'No messages yet.',
              style: TextStyle(color: IanovaColors.secondary),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: IanovaSpacing.lg,
        vertical: IanovaSpacing.sm,
      ),
      itemCount: thread.messages.length,
      itemBuilder: (context, index) {
        final message = thread.messages[index];
        final fromAdmin = message.fromAdmin;

        return Align(
          alignment: fromAdmin ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: fromAdmin ? IanovaColors.soft : IanovaColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fromAdmin)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(
                      'IANOVA team',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: IanovaColors.secondary,
                      ),
                    ),
                  ),
                Text(
                  message.body,
                  style: TextStyle(
                    color: fromAdmin ? IanovaColors.primary : Colors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _time(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: fromAdmin
                        ? IanovaColors.muted
                        : Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
