pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.10" apply false
    // Processes android/app/google-services.json into the FCM sender id and
    // API key the Firebase SDK reads at runtime. Declared here and applied
    // conditionally in app/build.gradle.kts, because that file is gitignored
    // as a secret and the plugin hard-fails when it is absent.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
