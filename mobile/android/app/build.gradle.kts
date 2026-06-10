import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun readGoogleMapsApiKey(): String {
    val secretsFile = rootProject.file("secrets.properties")
    if (!secretsFile.exists()) {
        return "YOUR_GOOGLE_MAPS_ANDROID_API_KEY"
    }
    val props = Properties()
    secretsFile.inputStream().use { props.load(it) }
    return props.getProperty("GOOGLE_MAPS_API_KEY")?.trim().orEmpty()
        .ifEmpty { "YOUR_GOOGLE_MAPS_ANDROID_API_KEY" }
}

android {
    namespace = "com.bkr.bkr_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        manifestPlaceholders["googleMapsApiKey"] = readGoogleMapsApiKey()
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bkr.bkr_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
