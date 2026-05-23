import 'package:flutter/widgets.dart';
import 'package:wa/wa.dart';

class WAStorybook extends StatefulWidget {
  const WAStorybook({super.key});

  @override
  State<WAStorybook> createState() => _WAStorybookState();
}

class _WAStorybookState extends State<WAStorybook> {
  int _selected = 0;

  late final List<_Story> _stories = [
    _Story('Button', _ButtonStory.new),
    _Story('Text edit', _TextEditStory.new),
    _Story('Checkbox', _CheckboxStory.new),
    _Story('Radio group', _RadioStory.new),
    _Story('Scrollbar', _ScrollbarStory.new),
    _Story('List box', _ListBoxStory.new),
    _Story('Dropdown', _DropdownStory.new),
    _Story('Group box', _GroupBoxStory.new),
    _Story('Labels', _LabelStory.new),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(waPx(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(
            stories: _stories,
            selected: _selected,
            onSelect: (i) => setState(() => _selected = i),
          ),
          SizedBox(width: waPx(8)),
          Expanded(child: _StoryFrame(story: _stories[_selected])),
        ],
      ),
    );
  }
}

class _Story {
  _Story(this.name, this.build);
  final String name;
  final Widget Function() build;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.stories,
    required this.selected,
    required this.onSelect,
  });

  final List<_Story> stories;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: waPx(90),
      child: WAGroupBox(
        title: 'Controls',
        child: WAListBox(
          items: stories.map((s) => s.name).toList(),
          selectedIndex: selected,
          onSelected: onSelect,
          height: waPx(180),
        ),
      ),
    );
  }
}

class _StoryFrame extends StatelessWidget {
  const _StoryFrame({required this.story});
  final _Story story;

  @override
  Widget build(BuildContext context) {
    return WAGroupBox(
      title: story.name,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(waPx(4)),
          child: story.build(),
        ),
      ),
    );
  }
}

/// Helper: a horizontal row of variants with small captions underneath.
class _Variants extends StatelessWidget {
  const _Variants(this.entries);
  final List<(String, Widget)> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: waPx(16),
      runSpacing: waPx(12),
      children: entries
          .map((e) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  e.$2,
                  SizedBox(height: waPx(2)),
                  WALabel(e.$1, tone: WALabelTone.muted),
                ],
              ))
          .toList(),
    );
  }
}

class _ButtonStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Variants([
      ('default', WAButton(caption: 'OK', onClick: () {})),
      ('long', WAButton(caption: 'Connect to host', onClick: () {})),
      ('disabled', WAButton(caption: 'Quit', onClick: () {}, enabled: false)),
    ]);
  }
}

class _TextEditStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Variants([
      ('default', SizedBox(width: waPx(120), child: const WATextEdit())),
      ('disabled',
          SizedBox(width: waPx(120), child: const WATextEdit(enabled: false))),
    ]);
  }
}

class _CheckboxStory extends StatefulWidget {
  @override
  State<_CheckboxStory> createState() => _CheckboxStoryState();
}

class _CheckboxStoryState extends State<_CheckboxStory> {
  bool _a = false;
  bool _b = true;
  bool? _c; // indeterminate (tri-state)

  @override
  Widget build(BuildContext context) {
    return _Variants([
      (
        'unchecked',
        WACheckbox(
          value: _a,
          onChanged: (v) => setState(() => _a = v),
          label: 'Sudden death',
        ),
      ),
      (
        'checked',
        WACheckbox(
          value: _b,
          onChanged: (v) => setState(() => _b = v),
          label: 'Worm select',
        ),
      ),
      (
        'indeterminate',
        WACheckbox(
          value: _c,
          onChanged: (v) => setState(() => _c = v),
          label: 'Mixed teams',
        ),
      ),
      (
        'disabled off',
        WACheckbox(
          value: false,
          onChanged: (_) {},
          label: 'Artillery',
          enabled: false,
        ),
      ),
      (
        'disabled on',
        WACheckbox(
          value: true,
          onChanged: (_) {},
          label: 'Indian rope',
          enabled: false,
        ),
      ),
    ]);
  }
}

class _RadioStory extends StatefulWidget {
  @override
  State<_RadioStory> createState() => _RadioStoryState();
}

class _RadioStoryState extends State<_RadioStory> {
  String _value = 'medium';

  @override
  Widget build(BuildContext context) {
    void set(String v) => setState(() => _value = v);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WALabel('Worm energy', tone: WALabelTone.muted),
        SizedBox(height: waPx(4)),
        WARadio<String>(
          value: 'low',
          groupValue: _value,
          onChanged: set,
          label: 'Low',
        ),
        SizedBox(height: waPx(2)),
        WARadio<String>(
          value: 'medium',
          groupValue: _value,
          onChanged: set,
          label: 'Medium',
        ),
        SizedBox(height: waPx(2)),
        WARadio<String>(
          value: 'high',
          groupValue: _value,
          onChanged: set,
          label: 'High',
        ),
        SizedBox(height: waPx(2)),
        WARadio<String>(
          value: 'disabled',
          groupValue: _value,
          onChanged: set,
          label: 'Disabled option',
          enabled: false,
        ),
      ],
    );
  }
}

class _ScrollbarStory extends StatefulWidget {
  @override
  State<_ScrollbarStory> createState() => _ScrollbarStoryState();
}

class _ScrollbarStoryState extends State<_ScrollbarStory> {
  double _continuous = 0.4;
  double _stepped = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WALabel('Continuous', tone: WALabelTone.muted),
        SizedBox(height: waPx(2)),
        SizedBox(
          width: waPx(160),
          child: WAScrollbar(
            value: _continuous,
            onChanged: (v) => setState(() => _continuous = v),
          ),
        ),
        SizedBox(height: waPx(10)),
        const WALabel('Stepped 0-10', tone: WALabelTone.muted),
        SizedBox(height: waPx(2)),
        SizedBox(
          width: waPx(160),
          child: WAScrollbar(
            value: _stepped,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => setState(() => _stepped = v),
          ),
        ),
        SizedBox(height: waPx(10)),
        const WALabel('Disabled', tone: WALabelTone.muted),
        SizedBox(height: waPx(2)),
        SizedBox(
          width: waPx(160),
          child: WAScrollbar(
            value: 0.7,
            onChanged: (_) {},
            enabled: false,
          ),
        ),
      ],
    );
  }
}

class _ListBoxStory extends StatefulWidget {
  @override
  State<_ListBoxStory> createState() => _ListBoxStoryState();
}

class _ListBoxStoryState extends State<_ListBoxStory> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    return WAListBox(
      width: waPx(160),
      height: waPx(100),
      items: const [
        'Boggy B',
        'Mad Cow',
        'Major Sigh',
        'Spadge',
        'Charles',
        'Pondlife',
        'Mr Tickle',
        'Crumb',
      ],
      selectedIndex: _index,
      onSelected: (i) => setState(() => _index = i),
    );
  }
}

class _DropdownStory extends StatefulWidget {
  @override
  State<_DropdownStory> createState() => _DropdownStoryState();
}

class _DropdownStoryState extends State<_DropdownStory> {
  int _scheme = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const WALabel('Scheme', tone: WALabelTone.muted),
        SizedBox(height: waPx(2)),
        SizedBox(
          width: waPx(140),
          child: WADropdown(
            items: const [
              'Intermediate',
              'Beginner',
              'Pro',
              'Artillery',
              'Blood Sport',
              'Sudden Sneak',
            ],
            selectedIndex: _scheme,
            onSelected: (i) => setState(() => _scheme = i),
          ),
        ),
      ],
    );
  }
}

class _GroupBoxStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: waPx(220),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WAGroupBox(
            title: 'Game options',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WACheckbox(value: true, onChanged: (_) {}, label: 'Sudden death'),
                SizedBox(height: waPx(2)),
                WACheckbox(value: false, onChanged: (_) {}, label: 'Artillery'),
              ],
            ),
          ),
          SizedBox(height: waPx(10)),
          const WAGroupBox(
            child: WALabel('Untitled group', tone: WALabelTone.muted),
          ),
        ],
      ),
    );
  }
}

class _LabelStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WALabel('Normal white text'),
        WALabel('Muted grey text', tone: WALabelTone.muted),
        WALabel('Yellow accent', tone: WALabelTone.accent),
      ],
    );
  }
}
