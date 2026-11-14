plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
    implementation("com.google.firebase:firebase-analytics")
}

android {
    namespace = "com.yeki.app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.yeki.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true  // Important
    }

    // Clé de signature définitive (même clé pour toutes les versions, pour
    // que chaque mise à jour s'installe par-dessus la précédente). Fournie
    // par l'environnement : en CI par les secrets GitHub (voir
    // .github/workflows/build.yml), en local par les mêmes variables.
    // Sans elle, repli sur la clé de debug (APK de test uniquement).
    val keystorePath = System.getenv("YEKI_KEYSTORE_PATH")
    val releaseSigning = if (keystorePath != null && file(keystorePath).exists()) {
        signingConfigs.create("release") {
            storeFile = file(keystorePath)
            storePassword = System.getenv("YEKI_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("YEKI_KEY_ALIAS") ?: "yeki"
            keyPassword = System.getenv("YEKI_KEY_PASSWORD") ?: System.getenv("YEKI_KEYSTORE_PASSWORD")
        }
    } else {
        null
    }

    buildTypes {
        release {
            signingConfig = releaseSigning ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}