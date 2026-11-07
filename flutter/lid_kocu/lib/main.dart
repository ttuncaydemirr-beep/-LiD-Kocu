import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  final state = await AppState.olustur();
  runApp(LidKocuApp(state: state));
}
