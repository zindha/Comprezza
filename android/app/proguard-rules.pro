# Flutter's generated registrant and plugin adapters are referenced by the
# embedding/plugin system rather than direct application calls.
-keep class io.flutter.plugins.** { *; }

# Preserve Android entry points declared by the manifest.
-keep class com.dzynova.comprezza.MainActivity { *; }

# Keep Kotlin metadata required by platform plugin reflection.
-keep class kotlin.Metadata { *; }
