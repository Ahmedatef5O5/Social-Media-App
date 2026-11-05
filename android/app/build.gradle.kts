import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val targetPlatformProp = project.findProperty("target-platform") as String?
val requestedAbis: Set<String> = targetPlatformProp
    ?.split(",")
    ?.mapNotNull {
        when (it.trim()) {
            "android-arm" -> "armeabi-v7a"
            "android-arm64" -> "arm64-v8a"
            "android-x86" -> "x86"
            "android-x64" -> "x86_64"
            else -> null
        }
    }
    ?.toSet()
    ?.takeIf { it.isNotEmpty() }
    ?: setOf("armeabi-v7a", "arm64-v8a", "x86_64")

val allKnownAbis = setOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
val excludedAbis = allKnownAbis - requestedAbis

android {
    namespace = "dev.ahmedatef.social_media_app"
    compileSdk = 36
    // ndkVersion = "27.0.12077973"
    ndkVersion = "28.2.13676358"
    
       compileOptions {

        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.ahmedatef.social_media_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        
        minSdk = 24
        // minSdk = flutter.minSdkVersion
        
        targetSdk = 36
        // targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    // 2. Add or update the `packaging` block inside `android {`
    packaging {
        jniLibs {
            // Compresses .so files inside the APK to achieve ~65-75 MB APK size on minSdk 24+
            useLegacyPackaging = true

            // Strictly exclude native libraries (.so) from non-targeted ABIs (WebRTC, LiveKit, DataStore)
            excludedAbis.forEach { abi ->
                excludes += "lib/$abi/**"
                excludes += "**/$abi/*.so"
            }
        }
    }

    buildTypes {
           getByName("release") {
           
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = false 
            isShrinkResources = false
            // isMinifyEnabled = true
            // isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }

        
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
    }
}


flutter {
    source = "../.."
}

configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.activity:activity-ktx:1.9.0")
        force("androidx.activity:activity:1.9.0")
    }
}
dependencies {
   coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
   implementation("androidx.appcompat:appcompat:1.7.0")
}