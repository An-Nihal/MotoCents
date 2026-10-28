# Flutter Proguard Rules
-dontwarn io.flutter.**

# Google ML Kit Text Recognition optional script models
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.vision.text.** { *; }

# Cryptography & SQLite
-dontwarn org.sqlite.**
-dontwarn com.google.crypto.tink.**
