plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

kotlin {
    jvmToolchain(17)
}

android {
    ndkVersion = "27.0.12077973"
    namespace = "com.example.phan_loai_rac_qua_hinh_anh"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.phan_loai_rac_qua_hinh_anh"
        minSdk = 26
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        buildTypes {
            getByName("release") {
                isMinifyEnabled = false
                isShrinkResources = false
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
    flutter {
        source = "../.."
    }

    dependencies {
        implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
        implementation("com.google.firebase:firebase-auth")
        }
}
