import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wa/wa.dart';

import 'api.dart';
import 'app.dart';
import 'screens/snooper_screen.dart';
import 'sprites.dart';
import 'state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  const originStr = String.fromEnvironment('SNOOPER_ORIGIN');
  final origin = originStr.isNotEmpty ? Uri.parse(originStr) : Uri.base;

  final api = SnooperApi(http.Client(), origin);
  final state = SnooperState(api, prefs);

  final queryNick = _nickFromUri();
  if (queryNick != null) {
    state.nick = queryNick;
  }

  await Sprites.load();

  // ignore: discarded_futures
  state.init();

  runApp(
    SnooperScope(
      notifier: state,
      child: WidgetsApp(
        color: WAColors.black,
        builder: (context, child) => WATheme(child: child!),
        initialRoute: '/',
        onGenerateRoute: (_) => PageRouteBuilder(
          pageBuilder: (context, _, __) => const SnooperScreen(),
        ),
      ),
    ),
  );
}

String? _nickFromUri() {
  final q = Uri.base.query;
  if (q.isEmpty ||
      q == 'utm_source=pwa&utm_medium=community&utm_campaign=launch') {
    return null;
  }
  return q;
}
