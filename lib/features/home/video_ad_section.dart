import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/store_config.dart';

/// Plays the admin-configured video ad. Every time this widget mounts (i.e.
/// every time the home page swaps the hero carousel out for the ad) it
/// starts a fresh, muted playback — a viewer's unmute from a previous play
/// never carries over. If [loopContinuously] is true (no banners configured
/// to fall back to), it keeps replaying, muted at the start of every loop,
/// instead of ever handing control back to the caller.
class VideoAdSection extends StatefulWidget {
  const VideoAdSection({
    super.key,
    required this.config,
    this.loopContinuously = false,
    this.onCtaTap,
  });

  final VideoAdConfig config;
  final bool loopContinuously;
  final VoidCallback? onCtaTap;

  @override
  State<VideoAdSection> createState() => _VideoAdSectionState();
}

class _VideoAdSectionState extends State<VideoAdSection> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = IanovaApiConfig.imageUrl(widget.config.src);
    if (url.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.setVolume(0);
      controller.addListener(_onTick);
      await controller.play();
      setState(() => _ready = true);
    } catch (_) {
      // Bad/unreachable video file — fail quietly, section just won't show.
    }
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final value = controller.value;
    final atEnd = value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 200);

    if (atEnd && !value.isPlaying) {
      // Loop it ourselves (instead of controller.setLooping(true)) so every
      // replay restarts muted, matching the "resets automatically" rule.
      controller.seekTo(Duration.zero);
      controller.setVolume(0);
      if (mounted) setState(() => _muted = true);
      controller.play();
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    final next = !_muted;
    controller.setVolume(next ? 0 : 1);
    setState(() => _muted = next);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.config.isActive) return const SizedBox.shrink();

    final controller = _controller;
    final aspect = (_ready && controller != null && controller.value.aspectRatio > 0)
        ? controller.value.aspectRatio
        : 16 / 9;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IanovaSpacing.xl,
        0,
        IanovaSpacing.xl,
        IanovaSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(IanovaSpacing.radiusXLarge),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: aspect,
              child: Container(
                color: Colors.black,
                child: (_ready && controller != null)
                    ? VideoPlayer(controller)
                    : const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: _Pill(label: 'Ad', dark: true),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (widget.config.hasLink && widget.onCtaTap != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: FilledButton(
                  onPressed: widget.onCtaTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: IanovaColors.warning,
                    foregroundColor: IanovaColors.primary,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Shop now'),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: dark ? Colors.white : IanovaColors.primary,
        ),
      ),
    );
  }
}
