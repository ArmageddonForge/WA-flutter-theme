import 'dart:io';

void launchWaUri(Uri uri) {
  final url = uri.toString();
  if (Platform.isLinux) {
    Process.start('xdg-open', [url], mode: ProcessStartMode.inheritStdio);
  } else if (Platform.isWindows) {
    Process.start('cmd', ['/c', 'start', '', url], mode: ProcessStartMode.inheritStdio);
  } else if (Platform.isMacOS) {
    Process.start('open', [url], mode: ProcessStartMode.inheritStdio);
  }
}
