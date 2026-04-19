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


android {
    namespace = "dev.ahmedatef.social_media_app"
    compileSdk = 36
    // compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
     sourceCompatibility = JavaVersion.VERSION_1_8 
        targetCompatibility = JavaVersion.VERSION_1_8 
       // sourceCompatibility = JavaVersion.VERSION_11
        // targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "1.8"
        // jvmTarget = JavaVersion.VERSION_17.toString()
        // jvmTarget = JavaVersion.VERSION_11.toString()
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

    buildTypes {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
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

flutter {
    source = "../.."
}

configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    
}