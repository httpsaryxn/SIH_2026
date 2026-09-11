# ProGuard / R8 rules for LabelLens Mobile

# Suppress missing optional language recognizer warnings in ML Kit Text Recognition
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
