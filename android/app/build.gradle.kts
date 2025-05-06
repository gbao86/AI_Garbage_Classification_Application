plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    ndkVersion = "28.1.13356709"
    namespace = "com.example.phan_loai_rac_qua_hinh_anh"
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
        applicationId = "com.example.phan_loai_rac_qua_hinh_anh"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        buildTypes {
            release {
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