# Rules for the R8 shrinker in release builds.
#
# flutter_local_notifications stores scheduled reminders as JSON through Gson
# and reads them back with a generic TypeToken. R8 strips generic signatures by
# default, which makes Gson throw "Missing type parameter." every time the
# plugin loads the list: on app update, on reboot, and whenever a reminder is
# scheduled. These rules follow the plugin README and Gson's own example.

## Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

## flutter_local_notifications
# Gson serializes the plugin's model classes by field name through reflection,
# so their names and members must survive shrinking and obfuscation.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
