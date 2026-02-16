# TensorFlow Lite (Prevent R8 from deleting TFLite classes)
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# TensorFlow Lite GPU Delegate (Fixes your specific error)
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Flutter Wrapper
-keep class com.tflite_flutter.** { *; }

# Keep FL Chart (Prevent chart crash)
-keep class fl_chart.** { *; }
-dontwarn fl_chart.**

# Keep Flutter Animate
-keep class flutter_animate.** { *; }