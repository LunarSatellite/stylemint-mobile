/// The wire shapes `POST /v1/vendor/digital-twin/scenarios` returns today.
///
/// Taken from `SimulatedFigure` and `SimulatedRetailOutcome` in
/// `StyleMint.Modules.Intelligence/Service/RetailSimulationService/`. Every
/// figure is an OBJECT carrying `provenance: "Simulated"`; the field names are
/// the ones the old bare-decimal contract used, deliberately, so a client that
/// still reads them as numbers renders something visibly wrong rather than a
/// plausible fabricated one.
library;

/// One figure. Pass `null` for a field to model it being absent.
Map<String, dynamic> figureJson({
  Object? simulatedValue = 12.5,
  Object? provenance = 'Simulated',
  Object? unit = 'percent',
  Object? measureKey = 'synthetic.conversion_percent',
  Object? derivedFrom = 'demand_shock,inventory_loss',
}) => <String, dynamic>{
  'runId': '0f1d2c3b-4a59-4c6d-8e7f-a0b1c2d3e4f5',
  'simulatedValue': simulatedValue,
  'provenance': provenance,
  'unit': unit,
  'measureKey': measureKey,
  'derivedFrom': derivedFrom,
  'scenarioClass': 'Edge',
};

/// A whole run. Note what is *not* here: the three
/// `calibration…DriftPoints` figures the old contract carried are gone and
/// are not replaced by anything on this response.
Map<String, dynamic> scenarioJson({
  Object? conversion,
  Object? stockout,
  Object? onTime,
  Object? gmv,
}) => <String, dynamic>{
  'runId': '0f1d2c3b-4a59-4c6d-8e7f-a0b1c2d3e4f5',
  'name': 'Vendor what-if',
  'provenance': 'Simulated',
  'calibrationVersion': 'vendor:abc:rolling-30d:2026091912',
  // The conversion figure is the fixture default: 12.5, percent, Simulated.
  'conversionPercent': conversion ?? figureJson(),
  'stockoutPercent':
      stockout ??
      figureJson(simulatedValue: 8, measureKey: 'synthetic.stockout_percent'),
  'onTimePercent':
      onTime ??
      figureJson(
        simulatedValue: 91.25,
        measureKey: 'synthetic.on_time_percent',
      ),
  'grossMerchandiseValue':
      gmv ??
      figureJson(
        simulatedValue: 48210.5,
        unit: 'currency_unstated',
        measureKey: 'synthetic.gross_merchandise_value',
      ),
  'limitations': <String>['Every figure here was produced by a seeded model.'],
};
