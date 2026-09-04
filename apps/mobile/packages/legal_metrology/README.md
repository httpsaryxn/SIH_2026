# legal_metrology

On-device **Legal Metrology (Packaged Commodities) Rules, 2011** compliance
audit. Vendored into this app from
[`Rajguresiddhesh/ML-SIH-`](https://github.com/Rajguresiddhesh/ML-SIH-).

## What it does

* `lib/src/compliance/` — pure-Dart rulebook: Rule 6 mandatory declarations
  (name/address, generic name, net quantity, MRP + "inclusive of all taxes",
  month/year, consumer care, country of origin) + `B01`–`B06` bar-code / GS1
  integrity checks + GTIN validation + deterministic scoring. **No network, no
  ML runtime.**
* `lib/src/extraction/` — Google ML Kit wrappers: on-device bar-code decoding
  and Latin + Devanagari label OCR, plus a regex text-parser.
* `lib/src/data/` — resolves a GTIN to declarations from Open Food Facts /
  UPCItemDB / Wikidata / GS1 India, **only when a network is available**
  (`connectivity_plus` gate).

## API

```dart
import 'package:legal_metrology/legal_metrology.dart';

// From a bar code alone (deterministic, offline):
final report = await runBarcodeAudit('8901030928239');

// From an OCR-derived PackageData (+ optional bar code on the same photo):
final report = await runLabelAudit(pkg, barcode: scannedGtin);

report.score.finalScore;   // 0..1
report.score.starLabel;
report.diff.failed;        // List<RuleResult>
report.diff.inconclusive;  // "verify on the physical label"
report.recommendations;
```

In this app the pipeline is called from
`lib/core/services/legal_metrology_service.dart`, which maps a
`ComplianceReport` onto `compliance_status` / `compliance_issues` /
`detected_declarations`.

## Tests

```bash
cd apps/mobile/packages/legal_metrology
flutter test        # Python <-> Dart rulebook parity (assets/fixtures/rulebook_cases.json)
```

## Optional model assets

`assets/models/` can hold `symbol_detector.tflite` (YOLO packaging-symbol
detector) and `compliance_ebm.json` (EBM second opinion). Neither is required —
generate them with the scripts in the ML-SIH- repo's `tools/`.
