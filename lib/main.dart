import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // visibility_detector v0.4.0+2 batches callbacks with a 500 ms Timer.
  // On hot restart the timer fires against stale RenderObjects, causing
  // assertion errors in render_visibility_detector.dart and layer.dart.
  // Setting updateInterval to zero makes callbacks flush synchronously on
  // the next post-frame callback instead, so there are never stale refs.
  VisibilityDetectorController.instance.updateInterval = Duration.zero;

  runApp(const PortfolioApp());
}
