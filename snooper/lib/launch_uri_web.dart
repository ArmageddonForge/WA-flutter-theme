import 'package:web/web.dart' as web;

void launchWaUri(Uri uri) {
  web.window.location.href = uri.toString();
}
