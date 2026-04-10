plugins {

    id("com.android.application")

    id("org.jetbrains.kotlin.android")

    id("dev.flutter.flutter-gradle-plugin")

    id("com.google.gms.google-services")

}

android {

    namespace = "com.molafzo.user"

    compileSdk = 36

    defaultConfig {

        applicationId = "com.molafzo.user"

        minSdk = flutter.minSdkVersion

        targetSdk = 36

        versionCode = flutter.versionCode

        versionName = flutter.versionName

    }

    compileOptions {

        sourceCompatibility = JavaVersion.VERSION_11

        targetCompatibility = JavaVersion.VERSION_11

        isCoreLibraryDesugaringEnabled = true

    }

    kotlinOptions {

        jvmTarget = "11"

    }

    buildTypes {

        release {

            signingConfig = signingConfigs.getByName("debug")

        }

    }

}

dependencies {

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

}

flutter {

    source = "../.."

}
