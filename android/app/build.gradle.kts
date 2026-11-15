import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Optional developer ACRCloud keys come from the git-ignored
// android/local.properties and are compiled into DEBUG builds only. Release
// builds never contain a key: users enter their own in Settings.
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun localProperty(key: String): String = localProperties.getProperty(key, "")

// Release signing comes from the git-ignored android/key.properties (see
// docs/RELEASING.md). Without it, release builds fall back to debug signing
// so contributors can still build them.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keyProperties.getProperty("storeFile")?.let { rootProject.file(it).exists() } == true

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

        // Spotify uses PKCE, so only the (non-secret) Client ID is needed.
        buildConfigField("String", "SPOTIFY_CLIENT_ID", "\"${localProperty("spotify.clientId")}\"")
    }

    sourceSets {
        getByName("main") {
            java.srcDir(if (hasAcrCloudSdk) "src/acrcloud/kotlin" else "src/noAcrcloud/kotlin")
        }
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            buildConfigField("String", "ACRCLOUD_HOST", "\"${localProperty("acrcloud.host")}\"")
            buildConfigField("String", "ACRCLOUD_ACCESS_KEY", "\"${localProperty("acrcloud.accessKey")}\"")
            buildConfigField("String", "ACRCLOUD_ACCESS_SECRET", "\"${localProperty("acrcloud.accessSecret")}\"")
        }
        release {
            // Never ship a recognition key; see AcrCloudCredentials.
            buildConfigField("String", "ACRCLOUD_HOST", "\"\"")
            buildConfigField("String", "ACRCLOUD_ACCESS_KEY", "\"\"")
            buildConfigField("String", "ACRCLOUD_ACCESS_SECRET", "\"\"")
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
            proguardFiles("proguard-rules.pro")
        }
    }
}

// The ACRCloud engine ships for 64-bit ARM only. Release APKs leave out the
// other ABIs, so 32-bit and x86 phones refuse to install them rather than
// installing an app that crashes or can't recognise anything. Debug builds
// keep every ABI, for emulators.
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.excludes.addAll(
            listOf("lib/armeabi-v7a/**", "lib/x86/**", "lib/x86_64/**"),
        )
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
