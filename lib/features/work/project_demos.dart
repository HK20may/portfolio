import 'package:flutter/widgets.dart';

import '../lab/monte_carlo/monte_carlo_sim.dart';
import '../lab/widgets/pathfinding_visualizer.dart';
import '../lab/widgets/sorting_visualizer.dart';
import 'demos/fraazo_demo.dart';
import 'demos/smart_meter_demo.dart';
import 'demos/zadinga_demo.dart';

/// Maps a project id to an embeddable, interactive demo widget.
class ProjectDemos {
  static final Map<String, WidgetBuilder> _demos = {
    'smart-energy': (_) => const SmartMeterDemo(),
    'zadinga': (_) => const ZadingaDemo(),
    'fraazo': (_) => const FraazoDemo(),
    'stock-prediction': (_) => const MonteCarloSim(compact: true),
    'sorting-visualizer': (_) => const SortingVisualizer(showHistory: true),
    'pathfinding': (_) => const PathfindingVisualizer(),
  };

  static bool has(String id) => _demos.containsKey(id);
  static Widget? build(BuildContext c, String id) => _demos[id]?.call(c);
}
