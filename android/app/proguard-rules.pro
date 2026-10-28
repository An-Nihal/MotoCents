# Flutter Proguard Rules
-dontwarn io.flutter.**
-keep class io.flutter.plugin.** { *; }

# Google ML Kit & Play Services Keep Rules
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Cryptography & SQLite
-dontwarn org.sqlite.**
-dontwarn com.google.crypto.tink.**
-dontwarn sun.misc.Unsafe
