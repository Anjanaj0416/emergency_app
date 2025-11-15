plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase - COMMENTED OUT until Firebase is needed
    // id("com.google.gms.google-services")
}

android {
    namespace = "com.example.emergency_app"
    compileSdk = 36  // Updated to latest stable version
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID - matches your package name
        applicationId = "com.example.emergency_app"
        
        // Minimum SDK version (Android 5.0 - Lollipop)
        minSdk = flutter.minSdkVersion
        
        // Target SDK version (Android 14)
        targetSdk = 36
        
        // Version information
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex for Google Maps
        multiDexEnabled = true
    }

    buildTypes {
    getByName("release") {
        isMinifyEnabled = false
        isShrinkResources = false
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }

    getByName("debug") {
        isDebuggable = true
        isMinifyEnabled = false
        isShrinkResources = false
    }
}

    // Packaging options to avoid conflicts
    packagingOptions {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

flutter {
    source = "../.."
}

// ============================================
// DEPENDENCIES
// ============================================

dependencies {
    // Firebase dependencies COMMENTED OUT for now
    // implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    // implementation("com.google.firebase:firebase-messaging")
    
    // Google Play Services for Maps
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    
    // Google Play Services for Location
    implementation("com.google.android.gms:play-services-location:21.0.1")
    
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}