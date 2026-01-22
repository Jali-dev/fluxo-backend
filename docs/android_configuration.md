# Configuración Android - Fluxo (Senior Standard)

Configuración optimizada para Java 21, SDK 34 y máxima compatibilidad.

## 1. `android/settings.gradle.kts`
**Propósito**: Gestión centralizada de plugins y repositorios.
**Clave**: Versiones fijas y estables (AGP 8.5.0, Kotlin 2.0.0).

```kotlin
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.5.0" apply false
    id("org.jetbrains.kotlin.android") version "2.0.0" apply false
}

include(":app")
```

## 2. `android/app/build.gradle.kts`
**Propósito**: Configuración del módulo de aplicación.
**Clave**: `compileSdk 34`, `JavaVersion.VERSION_21`, y exclusión de metadatos duplicados.

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fluxo.fluxo"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        applicationId = "com.fluxo.fluxo"
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}
```

## 3. `android/gradle.properties`
**Propósito**: Flags de la JVM y propiedades de Gradle.
**Clave**: Ajustes de memoria (`-Xmx4G`) y desactivación de Jetifier.

```properties
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G -XX:+UseParallelGC
org.gradle.parallel=true
org.gradle.caching=true
android.useAndroidX=true
android.enableJetifier=false
kotlin.code.style=official
```

## 4. `android/app/proguard-rules.pro`
**Propósito**: Reglas de ofuscación y reducción de código (R8).
**Clave**: Reglas base para evitar problemas en modo Release.

```
# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Keep standard Flutter/Dart interaction
-keep class com.fluxo.fluxo.** { *; }
```
