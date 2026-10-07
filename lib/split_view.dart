import 'package:flutter/material.dart';
import 'profile_model.dart';
import 'gecko_webview.dart';

class SplitView extends StatefulWidget {
  final List<Profile> profiles;

  const SplitView({super.key, required this.profiles});

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  final Map<int, GeckoWebViewController> _controllers = {};
  final Map<int, double> _zooms = {};
  final Map<int, bool> _desktop = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.profiles.length; i++) {
      _zooms[i] = 0.7;
      _desktop[i] = true;
    }
  }

  void _zoomIn(int i) {
    setState(() {
      _zooms[i] = ((_zooms[i] ?? 0.7) + 0.1).clamp(0.25, 1.5);
    });
    _controllers[i]?.setZoom(_zooms[i]!);
  }

  void _zoomOut(int i) {
    setState(() {
      _zooms[i] = ((_zooms[i] ?? 0.7) - 0.1).clamp(0.25, 1.5);
    });
    _controllers[i]?.setZoom(_zooms[i]!);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.profiles.length;
    if (n == 1) return _panel(0);
    if (n == 2) {
      return Column(
        children: [
          Expanded(child: _panel(0)),
          Expanded(child: _panel(1)),
        ],
      );
    }
    if (n == 3) {
      return Column(
        children: [
          Expanded(child: _panel(0)),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _panel(1)),
                Expanded(child: _panel(2)),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _panel(0)),
              Expanded(child: _panel(1)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _panel(2)),
              Expanded(child: _panel(3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panel(int index) {
    final p = widget.profiles[index];
    final zoom = _zooms[index] ?? 0.7;
    final desktop = _desktop[index] ?? true;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF10141D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1D2430)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: const BoxDecoration(
              color: Color(0xFF141924),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2233),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF253048)),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF9FB6DF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _iconBtn(Icons.text_decrease, () => _zoomOut(index), 'Zoom out'),
                _iconBtn(Icons.text_increase, () => _zoomIn(index), 'Zoom in'),
                _iconBtn(Icons.refresh, () => _controllers[index]?.reload(), 'Reload'),
                _iconBtn(Icons.chevron_left, () => _controllers[index]?.back(), 'Back'),
                _iconBtn(Icons.chevron_right, () => _controllers[index]?.forward(), 'Forward'),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
              child: GeckoWebView(
                url: p.url,
                userAgent: p.userAgent,
                zoom: zoom,
                desktopMode: desktop,
                onReady: (c) => _controllers[index] = c,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(icon, size: 15, color: const Color(0xFF8B95A7)),
        ),
      ),
    );
  }
}
