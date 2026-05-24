import 'package:flutter/widgets.dart';
import 'package:wa/wa.dart';

import '../models.dart';

class ChatLog extends StatefulWidget {
  const ChatLog({super.key, required this.lines});

  final List<ChatLine> lines;

  @override
  State<ChatLog> createState() => _ChatLogState();
}

class _ChatLogState extends State<ChatLog> {
  final ScrollController _ctrl = ScrollController();
  double _scrollT = 0;
  static const double _bottomThreshold = 20;
  int _builtLineCount = -1;
  InlineSpan? _cachedSpan;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(ChatLog old) {
    super.didUpdateWidget(old);
    if (widget.lines.length == _builtLineCount) return;
    if (widget.lines.length > _builtLineCount && _builtLineCount >= 0 && !_atBottom()) {
      return;
    }
    _refreshSpan();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _refreshSpan() {
    _builtLineCount = widget.lines.length;
    _cachedSpan = TextSpan(
      children: [
        for (final l in widget.lines)
          TextSpan(
            text: '${l.text}\n',
            style: WAFonts.smallOn(l.tone).copyWith(height: (waPx(11) - 0.5) / 19.2),
          ),
      ],
    );
  }

  InlineSpan _buildSpan() {
    if (_cachedSpan == null) _refreshSpan();
    return _cachedSpan!;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _ctrl.position;
    final double t =
        pos.maxScrollExtent > 0 ? pos.pixels / pos.maxScrollExtent : 0;
    bool dirty = t != _scrollT;
    if (dirty) _scrollT = t;
    if (_atBottom() && _builtLineCount != widget.lines.length) {
      _refreshSpan();
      dirty = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    if (dirty) setState(() {});
  }

  void _jumpToT(double t) {
    if (!_ctrl.hasClients) return;
    _ctrl.jumpTo(t * _ctrl.position.maxScrollExtent);
  }

  bool _atBottom() {
    if (!_ctrl.hasClients) return true;
    final pos = _ctrl.position;
    return pos.pixels >= pos.maxScrollExtent - _bottomThreshold;
  }

  void _scrollToBottom() {
    if (!_ctrl.hasClients) return;
    _ctrl.jumpTo(_ctrl.position.maxScrollExtent);
  }

  double _viewportFraction() {
    if (!_ctrl.hasClients) return 1.0;
    final pos = _ctrl.position;
    final total = pos.maxScrollExtent + pos.viewportDimension;
    return total > 0 ? (pos.viewportDimension / total).clamp(0.0, 1.0) : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final vf = _viewportFraction();
    final bool overflows = vf < 1.0;
    final BorderSide borderSide =
        BorderSide(color: WAColors.grey, width: WAMetrics.borderWidth);
    return Container(
      decoration: BoxDecoration(
        color: WAColors.darkBlue,
        border: Border(
          top: borderSide,
          left: borderSide,
          bottom: borderSide,
          right: overflows ? BorderSide.none : borderSide,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DefaultSelectionStyle(
              selectionColor: WAColors.white,
              child: SelectableRegion(
                selectionControls: EmptyTextSelectionControls(),
                child: SingleChildScrollView(
                controller: _ctrl,
                padding: EdgeInsets.all(waPx(1)),
                child: Text.rich(_buildSpan()),
              ),
            ),
            ),
          ),
          if (overflows)
            WAScrollbar(
              axis: Axis.vertical,
              value: _scrollT,
              viewportFraction: vf,
              onChanged: _jumpToT,
            ),
        ],
      ),
    );
  }
}
