# Flutter ProGuard Rules

# Add rules for androidx.window to fix R8 build errors
-dontwarn androidx.window.**
-keep class androidx.window.** { *; }
-dontwarn androidx.window.sidecar.**
-keep class androidx.window.sidecar.** { *; }
