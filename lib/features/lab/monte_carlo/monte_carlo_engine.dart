import 'dart:math';

class MonteCarloParams {
  const MonteCarloParams({
    required this.s0,
    required this.muAnnual,
    required this.sigmaAnnual,
    required this.days,
    required this.sims,
    required this.pathsToReturn,
    this.seed,
  });
  final double s0, muAnnual, sigmaAnnual;
  final int days, sims, pathsToReturn;
  final int? seed;
}

class MonteCarloResult {
  const MonteCarloResult({
    required this.samplePaths,
    required this.meanPath,
    required this.finalPrices,
    required this.mean,
    required this.median,
    required this.p5,
    required this.p95,
    required this.probProfit,
  });
  final List<List<double>> samplePaths;
  final List<double> meanPath;
  final List<double> finalPrices;
  final double mean, median, p5, p95, probProfit;
}

MonteCarloResult runMonteCarlo(MonteCarloParams p) {
  final rng = Random(p.seed ?? DateTime.now().microsecondsSinceEpoch);
  const dt = 1 / 252.0;
  final drift = (p.muAnnual - 0.5 * p.sigmaAnnual * p.sigmaAnnual) * dt;
  final vol = p.sigmaAnnual * sqrt(dt);
  final steps = p.days;

  final finals = List<double>.filled(p.sims, 0);
  final meanPath = List<double>.filled(steps + 1, 0);
  final sample = <List<double>>[];

  for (var i = 0; i < p.sims; i++) {
    var s = p.s0;
    final keep = i < p.pathsToReturn;
    final path = keep ? (List<double>.filled(steps + 1, 0)..[0] = s) : null;
    meanPath[0] += s;
    for (var t = 1; t <= steps; t++) {
      final z = _gaussian(rng);
      s = s * exp(drift + vol * z);
      if (keep) path![t] = s;
      meanPath[t] += s;
    }
    finals[i] = s;
    if (keep) sample.add(path!);
  }
  for (var t = 0; t <= steps; t++) {
    meanPath[t] /= p.sims;
  }

  final sorted = [...finals]..sort();
  double pct(double q) => sorted[(q * (sorted.length - 1)).round()];
  final mean = finals.reduce((a, b) => a + b) / finals.length;
  final profit = finals.where((x) => x > p.s0).length / finals.length;

  return MonteCarloResult(
    samplePaths: sample,
    meanPath: meanPath,
    finalPrices: finals,
    mean: mean,
    median: pct(0.5),
    p5: pct(0.05),
    p95: pct(0.95),
    probProfit: profit,
  );
}

double _gaussian(Random r) {
  final u1 = 1 - r.nextDouble();
  final u2 = r.nextDouble();
  return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
}
