import java.util.Properties

// Load local.properties for flutter versions
val localProperties = Properties().apply {
    val localFile = rootProject.file("local.properties")
    if (localFile.exists()) {
        load(localFile.inputStream())
    }
}

val flutterVersionCode: String = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName: String = localProperties.getProperty("flutter.versionName") ?: "1.0"

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Firebase plugin
}

android {
    namespace = "com.example.eventra"  // ✅ Must match Firebase package name
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.eventra"  // ✅ Must match google-services.json
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            // Debug signing for now (change later for Play Store release)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM (keeps all Firebase versions aligned)
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // Core Firebase SDKs
    implementation("com.google.firebase:firebase-analytics")  // Analytics
    implementation("com.google.firebase:firebase-auth")       // Authentication
    implementation("com.google.firebase:firebase-firestore")  // Firestore database
    implementation("com.google.firebase:firebase-storage")    // Cloud Storage
    // Add more if needed...
}
