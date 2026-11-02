import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tribe.tribe_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.tribe.tribe_app"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Load keystore properties
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val keyAliasProp = keystoreProperties["keyAlias"]
                val keyPasswordProp = keystoreProperties["keyPassword"]
                val storeFileProp = keystoreProperties["storeFile"]
                val storePasswordProp = keystoreProperties["storePassword"]
                
                if (keyAliasProp != null && keyPasswordProp != null && storeFileProp != null && storePasswordProp != null) {
                    keyAlias = keyAliasProp.toString()
                    keyPassword = keyPasswordProp.toString()
                    storeFile = file(storeFileProp.toString())
                    storePassword = storePasswordProp.toString()
                }
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        debug {
            // Debug uses default debug keystore, ignore key.properties
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

apply(plugin = "com.google.gms.google-services")
