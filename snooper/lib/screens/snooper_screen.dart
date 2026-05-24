import 'package:flutter/widgets.dart';
import 'package:wa/wa.dart';

import '../app.dart';
import '../launch_uri.dart';
import '../models.dart';
import '../state.dart';
import '../widgets/chat_log.dart';
import '../widgets/games_table.dart';
import '../widgets/players_table.dart';
import 'host_dialog.dart';

class SnooperScreen extends StatefulWidget {
  const SnooperScreen({super.key});

  @override
  State<SnooperScreen> createState() => _SnooperScreenState();
}

class _SnooperScreenState extends State<SnooperScreen> {
  int _messageKey = 0;
  String _messageText = '';
  bool _drawerOpen = false;

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 720;

  void _joinGame(Game g) {
    final state = SnooperScope.of(context);
    final activeChannel = state.activeChannel!;
    final schemeId = state.byChannel[activeChannel]?.scheme ?? '';
    final uri = Uri.parse('wa://${g.ip}:${g.port}?scheme=$schemeId&id=${g.id}');
    launchWaUri(uri);
  }

  void _send() {
    final state = SnooperScope.of(context);
    state.resetPollBackoff();
    final message = _messageText.replaceAll(RegExp(r'\r\n|\n|\r'), ' ');
    if (message.isEmpty) return;
    final n = state.nick;
    if (n.isEmpty) { _showAlert('Please enter a nickname.'); return; }
    if (n.length < 3) { _showAlert('Your nickname is too short...'); return; }
    if (n.length > 15) { _showAlert('Your nickname is too long...'); return; }
    if (message.length > 200) { _showAlert('Your message is too long...'); return; }
    for (final c in n.runes) {
      final ok = (c >= 0x30 && c <= 0x39) ||
                 (c >= 0x41 && c <= 0x5A) ||
                 (c >= 0x61 && c <= 0x7A) ||
                 c == 0x2D || c == 0x5F || c == 0x60;
      if (!ok) { _showAlert('Your nickname contains invalid characters.'); return; }
    }
    state.sendMessage(message);
    _messageText = '';
    setState(() => _messageKey++);
  }

  void _addNick(String nick) {
    final message = _messageText;
    final pos = message.indexOf(': ');
    String newMessage;
    if (pos < 0) {
      newMessage = '$nick: $message';
    } else {
      final start = pos - nick.length < 0 ? 0 : pos - nick.length;
      if (message.substring(start, pos) != nick) {
        newMessage = '${message.substring(0, pos)}, $nick${message.substring(pos)}';
      } else {
        newMessage = message;
      }
    }
    _messageText = newMessage;
    setState(() => _messageKey++);
  }

  Widget _buildChannelBar(SnooperState state) {
    return Container(
      decoration: BoxDecoration(
        color: WAColors.darkBlue,
        border: Border.all(color: WAColors.grey, width: WAMetrics.borderWidth),
      ),
      padding: EdgeInsets.symmetric(vertical: waPx(1.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final ch in state.channels)
            _ChannelTab(
              name: ch,
              selected: ch == state.activeChannel,
              onTap: () => state.setActiveChannel(ch),
            ),
        ],
      ),
    );
  }

  void _showAlert(String text) {
    showWADialog(
      context: context,
      builder: (ctx) => WADialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            SizedBox(height: waPx(8)),
            WAButton(caption: 'OK', onClick: () => Navigator.of(ctx).pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildSendRow(SnooperState state, bool mobile) {
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const WALabel('Your name:', tone: WALabelTone.accent),
          SizedBox(height: waPx(2)),
          WATextEdit(
            initialText: state.nick,
            maxLength: 15,
            textStyle: WAFonts.small,
            onChanged: (v) => state.setNick(v),
          ),
          SizedBox(height: WAMetrics.gap),
          const WALabel('Message:', tone: WALabelTone.accent),
          SizedBox(height: waPx(2)),
          WATextEdit(
            key: ValueKey(_messageKey),
            initialText: _messageText,
            maxLength: 200,
            multiline: true,
            textStyle: WAFonts.small,
            onChanged: (v) => _messageText = v,
            onSubmitted: (_) => _send(),
          ),
          SizedBox(height: WAMetrics.gap),
          WAButton(caption: 'Send', onClick: _send),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: waPx(85),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const WALabel('Your name:', tone: WALabelTone.accent),
              SizedBox(height: waPx(2)),
              WATextEdit(
                initialText: state.nick,
                maxLength: 15,
                textStyle: WAFonts.small,
                onChanged: (v) => state.setNick(v),
              ),
            ],
          ),
        ),
        SizedBox(width: WAMetrics.gap * 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const WALabel('Message:', tone: WALabelTone.accent),
              SizedBox(height: waPx(2)),
              WATextEdit(
                key: ValueKey(_messageKey),
                initialText: _messageText,
                maxLength: 200,
                textStyle: WAFonts.small,
                onChanged: (v) => _messageText = v,
                onSubmitted: (_) => _send(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(SnooperState state) {
    final activeChannel = state.activeChannel!;
    return Container(
      decoration: BoxDecoration(
        gradient: WAColors.backgroundGradient,
        border: Border(
          right: BorderSide(color: WAColors.grey, width: waPx(1)),
        ),
      ),
      padding: EdgeInsets.all(waPx(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WALabel('Channels', tone: WALabelTone.accent),
          SizedBox(height: WAMetrics.gap),
          Wrap(
            children: [
              for (final ch in state.channels)
                _ChannelTab(
                  name: ch,
                  selected: ch == activeChannel,
                  onTap: () {
                    state.setActiveChannel(ch);
                    setState(() => _drawerOpen = false);
                  },
                ),
            ],
          ),
          SizedBox(height: WAMetrics.gap * 2),
          const WALabel('Players', tone: WALabelTone.accent),
          SizedBox(height: WAMetrics.gap),
          Expanded(
            child: PlayersTable(
              players: state.byChannel[activeChannel]?.players ?? const [],
              onNickActivated: (nick) {
                _addNick(nick);
                setState(() => _drawerOpen = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = SnooperScope.of(context);

    if (state.activeChannel == null) {
      return const SizedBox.shrink();
    }

    final activeChannel = state.activeChannel!;
    final channelState = state.byChannel[activeChannel];
    final players = channelState?.players ?? const [];
    final games = channelState?.games ?? const [];
    final messages = channelState?.messages ?? const [];
    final mobile = _isMobile(context);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => state.resetPollBackoff(),
      onPointerHover: (_) => state.resetPollBackoff(),
      child: Padding(
        padding: EdgeInsets.all(waPx(5)),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mobile) ...[
                            WAButton(
                              caption: '☰ Menu',
                              onClick: () =>
                                  setState(() => _drawerOpen = true),
                            ),
                            SizedBox(width: WAMetrics.gap * 2),
                          ],
                          const WALabel('Games', tone: WALabelTone.accent),
                          const Spacer(),
                          if (!mobile) _buildChannelBar(state),
                        ],
                      ),
                      SizedBox(height: WAMetrics.gap),
                      Expanded(
                        flex: 2,
                        child: GamesTable(
                          games: games,
                          onGameActivated: _joinGame,
                        ),
                      ),
                      SizedBox(height: WAMetrics.gap),
                      const WALabel('Messages', tone: WALabelTone.accent),
                      SizedBox(height: WAMetrics.gap),
                      Expanded(
                        flex: 3,
                        child: ChatLog(lines: messages),
                      ),
                      SizedBox(height: WAMetrics.gap),
                      _buildSendRow(state, mobile),
                    ],
                  ),
                ),
                if (!mobile) ...[
                  SizedBox(width: WAMetrics.gap * 2),
                  SizedBox(
                    width: waPx(150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const WALabel('Players', tone: WALabelTone.accent),
                            const Spacer(),
                            if (channelState?.canHost == true)
                              WAButton(
                                caption: 'Host',
                                onClick: () => showHostDialog(context),
                              ),
                          ],
                        ),
                        SizedBox(height: WAMetrics.gap),
                        Expanded(
                          child: PlayersTable(
                            players: players,
                            onNickActivated: _addNick,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            // Mobile drawer overlay
            if (mobile && _drawerOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _drawerOpen = false),
                  child: Container(color: const Color(0x80000000)),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 266,
                child: _buildDrawer(state),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChannelTab extends StatefulWidget {
  const _ChannelTab({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ChannelTab> createState() => _ChannelTabState();
}

class _ChannelTabState extends State<_ChannelTab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: CustomPaint(
          foregroundPainter: _hover ? _DottedRectPainter(WAColors.grey) : null,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: waPx(2.5),
              vertical: waPx(1),
            ),
            color: _hover && !widget.selected ? WAColors.selectionRed : null,
            child: Text(
              '#${widget.name}',
              style: WAFonts.smallOn(
                widget.selected ? WAColors.yellow : WAColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DottedRectPainter extends CustomPainter {
  _DottedRectPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = color;
    final double d = waPx(1);
    for (double x = 0; x + d <= size.width; x += d * 2) {
      canvas.drawRect(Rect.fromLTWH(x, 0, d, d), p);
      canvas.drawRect(Rect.fromLTWH(x, size.height - d, d, d), p);
    }
    for (double y = 0; y + d <= size.height; y += d * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, d, d), p);
      canvas.drawRect(Rect.fromLTWH(size.width - d, y, d, d), p);
    }
  }

  @override
  bool shouldRepaint(_DottedRectPainter old) => old.color != color;
}
