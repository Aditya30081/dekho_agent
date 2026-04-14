-keep class io.flutter.app.** { *; }
 -keep class io.flutter.plugin.** { *; }
 -keep class io.flutter.util.** { *; }
 -keep class io.flutter.view.** { *; }
 -keep class io.flutter.** { *; }
 -keep class io.flutter.** { *; }
 -keep class com.hyphenate.** {*;}
 -dontwarn  com.hyphenate.**
 -dontwarn io.flutter.**
 -keep class com.google.firebase.** { *; }
 -dontwarn com.google.firebase.**
 -keep class com.google.firebase.** { *; }
 -keep class com.google.android.gms.** { *; }
 -dontwarn com.google.firebase.**

####################################
# AGORA RTC (Video / Audio / P2P)
####################################
-keep class io.agora.** { *; }
-keep class com.agora.** { *; }
-keep class io.agora.rtc.** { *; }

# WebRTC (used internally by Agora)
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

####################################
# AGORA CHAT SDK
####################################
-keep class io.agora.chat.** { *; }
-keep class io.agora.rtm.** { *; }

####################################
# Native JNI methods (IMPORTANT)
####################################
-keepclassmembers class * {
    native <methods>;
}

####################################
# Callback / Listener methods
####################################
-keepclassmembers class * {
    void on*(...);
}

####################################
# FLUTTER CORE
####################################
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

####################################
# IMAGE PICKER
####################################
-dontwarn io.flutter.plugins.imagepicker.**

####################################
# PERMISSION HANDLER
####################################
-dontwarn com.baseflow.permissionhandler.**

####################################
# FLUTTER LOCAL NOTIFICATIONS
####################################
-keep class com.dexterous.flutterlocalnotifications.** { *; }

####################################
# SHARED PREFERENCES
####################################
-dontwarn io.flutter.plugins.sharedpreferences.**

####################################
# DEVICE INFO PLUS
####################################
-dontwarn dev.fluttercommunity.plus.device_info.**

####################################
# HTTP PACKAGE
####################################
-dontwarn okhttp3.**
-dontwarn okio.**

####################################
# FIREBASE CORE + AUTH + FIRESTORE
####################################
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

####################################
# GSON (used internally by Agora/Firebase)
####################################
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

####################################
# AUDIO PLAYERS
####################################
-dontwarn xyz.luan.audioplayers.**

####################################
# CARD SWIPER
####################################
-dontwarn com.flutter.cardswiper.**

####################################
# ANDROIDX (SAFE)
####################################
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**

####################################
# ANNOTATIONS
####################################
-keepattributes *Annotation*