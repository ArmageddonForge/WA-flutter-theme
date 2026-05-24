import 'package:flutter/widgets.dart';
import 'package:wa/wa.dart';

import '../app.dart';
import '../launch_uri.dart';
import '../state.dart';

Future<void> showHostDialog(BuildContext context) {
  return showWADialog(
    context: context,
    builder: (ctx) => const _HostDialog(),
  );
}

class _HostDialog extends StatefulWidget {
  const _HostDialog();

  @override
  State<_HostDialog> createState() => _HostDialogState();
}

class _HostDialogState extends State<_HostDialog> {
  String _schemeId = '47';
  String _name = '';
  String _password = '';
  bool _handlingError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = SnooperScope.of(context);
    if (state.hostError != null && !_handlingError) {
      _handlingError = true;
      final error = state.hostError!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showWADialog(
          context: context,
          builder: (ctx) => WADialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error),
                SizedBox(height: waPx(8)),
                WAButton(
                  caption: 'OK',
                  onClick: () {
                    Navigator.of(ctx).pop();
                    SnooperScope.of(context).resetHostDialog();
                    setState(() => _handlingError = false);
                  },
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = SnooperScope.of(context);
    if (state.hostLoading) return _buildLoading();
    if (state.hostResultUrl != null) return _buildResult(state);
    return _buildForm(state);
  }

  Widget _buildForm(SnooperState state) {
    final entries = state.schemes.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    final idx = entries.indexWhere((e) => e.key == _schemeId);
    final effectiveIdx = idx >= 0 ? idx : 0;

    return WADialog(
      width: waPx(323),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: waPx(91), child: const WALabel('Name')),
              SizedBox(width: WAMetrics.gap),
              Expanded(
                child: WATextEdit(
                  initialText: _name,
                  maxLength: 39,
                  onChanged: (v) => _name = v,
                  onSubmitted: (_) => _submit(state, entries),
                ),
              ),
            ],
          ),
          SizedBox(height: waPx(14)),
          Row(
            children: [
              SizedBox(width: waPx(91), child: const WALabel('Scheme')),
              SizedBox(width: WAMetrics.gap),
              Expanded(
                child: entries.isEmpty
                    ? const SizedBox.shrink()
                    : WADropdown(
                        items: entries.map((e) => e.value).toList(),
                        selectedIndex: effectiveIdx,
                        onSelected: (i) =>
                            setState(() => _schemeId = entries[i].key),
                      ),
              ),
            ],
          ),
          SizedBox(height: waPx(14)),
          Row(
            children: [
              SizedBox(width: waPx(91), child: const WALabel('Password')),
              SizedBox(width: WAMetrics.gap),
              Expanded(
                child: WATextEdit(
                  initialText: _password,
                  maxLength: 16,
                  obscureText: true,
                  onChanged: (v) => _password = v,
                  onSubmitted: (_) => _submit(state, entries),
                ),
              ),
            ],
          ),
          SizedBox(height: waPx(8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              WAButton(
                caption: 'OK',
                onClick: () => _submit(state, entries),
              ),
              WAButton(caption: 'Cancel', onClick: _cancel),
            ],
          ),
        ],
      ),
    );
  }

  void _submit(
    SnooperState state,
    List<MapEntry<String, String>> entries,
  ) {
    if (_name.isEmpty) return;
    final idx = entries.indexWhere((e) => e.key == _schemeId);
    final schemeId =
        idx >= 0 ? _schemeId : (entries.isNotEmpty ? entries[0].key : '');
    state.hostGame(name: _name, schemeId: schemeId, password: _password);
  }

  void _cancel() {
    SnooperScope.of(context).resetHostDialog();
    Navigator.of(context).pop();
  }

  Widget _buildLoading() {
    return WADialog(
      width: waPx(323),
      child: const Center(
        child: WALabel('Please wait... working...'),
      ),
    );
  }

  Widget _buildResult(SnooperState state) {
    return WADialog(
      width: waPx(323),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          WAButton(
            caption: 'Join your game',
            onClick: () => launchWaUri(Uri.parse(state.hostResultUrl!)),
          ),
          SizedBox(height: waPx(8)),
          const WALabel(
            'Your game will be hosted as soon as you join.',
            tone: WALabelTone.muted,
          ),
          SizedBox(height: waPx(8)),
          WAButton(
            caption: 'Close',
            onClick: () {
              SnooperScope.of(context).resetHostDialog();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
