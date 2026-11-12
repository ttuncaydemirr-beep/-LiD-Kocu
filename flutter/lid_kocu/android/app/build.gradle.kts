import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") apply false
}

// ---------------------------------------------------------------- Firebase (android/app/google-services.json)
// Dosya henüz yok: Firebase Console'dan indirilip buraya konunca (veya CI'da GOOGLE_SERVICES_JSON gizli değeriyle)
// eklenti uygulanır. Dosya yokken derleme Firebase'siz sürer; uygulama çökmez, Analytics/Remote Config sessizce kapalıdır.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// ---------------------------------------------------------------- AdMob uygulama kimliği (tek yer)
// Değer lib/services/reklam_ayar.dart içindeki `admobUygulamaKimligi` satırından okunur ve AndroidManifest'e
// ${admobUygulamaKimligi} olarak yazılır. Kullanıcı AdMob kimliğini verince reklam_ayar.dart'ta değiştir.
// Boşsa Google'ın TEST uygulama kimliği kalır (reklam SDK'sı kimliksiz açılışta çöker; test kimliği bunu önler).
val admobTestUygulamaKimligi = "ca-app-pub-3940256099942544~3347511713"
val admobUygulamaKimligi: String = run {
    val f = file("../../lib/services/reklam_ayar.dart")
    val m = if (f.exists()) Regex("admobUygulamaKimligi\\s*=\\s*'([^']*)'").find(f.readText()) else null
    val v = m?.groupValues?.get(1)?.trim().orEmpty()
    v.ifEmpty { admobTestUygulamaKimligi }
}

// ---------------------------------------------------------------- Sürüm imzalama (android/key.properties)
// Anahtar deposu bu projede OLUŞTURULMAZ ve depoya konmaz. android/key.properties.example dosyasını
// key.properties olarak kopyalayıp doldurun (README.md "İmzalama"). Dosya yoksa release derlemesi DEBUG anahtarıyla
// imzalanır: `flutter run --release` çalışır, ancak bu paket Play Console'a YÜKLENEMEZ.
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val hasReleaseKey = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !keyProps.getProperty(it).isNullOrBlank() }

android {
    namespace = "com.lidkocu.app"
    // Google Play hedef API şartı: yeni uygulamalar ve güncellemeler API 36 (Android 16) hedeflemeli.
    compileSdk = 36

    // Yayın derlemesindeki "lintVital" denetimi, eklenti kaynaklarında (in_app_purchase_android)
    // lint aracının kendi hatasıyla (NoSuchMethodError, JavaDocParser) çöküyor. Kod hatası değil;
    // denetim yayın derlemesinde kapatılır. Lint gerekirse ayrıca `./gradlew lint` ile çalıştırılır.
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.lidkocu.app"
        minSdk = 24
        targetSdk = 36
        // Sürüm pubspec.yaml'dan gelir: "version: 1.0.0+2" → versionName 1.0.0, versionCode 2.
        // Play'e her yüklemede pubspec'teki +N artırılmalı (aynı versionCode ikinci kez yüklenemez).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobUygulamaKimligi"] = admobUygulamaKimligi
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = if (hasReleaseKey) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
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
