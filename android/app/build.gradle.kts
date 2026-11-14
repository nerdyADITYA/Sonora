import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ACRCloud credentials come from the git-ignored android/local.properties.
// They are compiled into the APK, which is acceptable only for personal
// builds. See docs/RECOGNITION_FEASIBILITY.md.
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun localProperty(key: String): String = localProperties.getProperty(key, "")

// The ACRCloud SDK is proprietary and not committed. When the JAR is missing
// the app still builds, using a stub engine that reports PROVIDER_UNAVAILABLE.
val acrCloudSdkJars = fileTree("libs") { include("acrcloud-universal-sdk-*.jar") }
val hasAcrCloudSdk = !acrCloudSdkJars.isEmpty

android {
    namespace = "dev.sonora.sonora"
    // Android 17 (API 37). See docs/DEVELOPMENT.md for the SDK policy.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "dev.sonora.sonora"
        minSdk = flutter.minSdkVersion // 24: the lowest Flutter supports
        // Raised to 37 after Android 17 behaviour testing on device.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        buildConfigField("String", "ACRCLOUD_HOST", "\"${localProperty("acrcloud.host")}\"")
        buildConfigField("String", "ACRCLOUD_ACCESS_KEY", "\"${localProperty("acrcloud.accessKey")}\"")
        buildConfigField("String", "ACRCLOUD_ACCESS_SECRET", "\"${localProperty("acrcloud.accessSecret")}\"")
    }

    sourceSets {
        getByName("main") {
            java.srcDir(if (hasAcrCloudSdk) "src/acrcloud/kotlin" else "src/noAcrcloud/kotlin")
        }
    }

    buildTypes {
        release {
            // Debug signing until a release keystore is set up (Phase 8). Never commit keystores.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles("proguard-rules.pro")
        }
    }
}

dependencies {
    if (hasAcrCloudSdk) implementation(acrCloudSdkJars)

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:runner:1.7.0")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
