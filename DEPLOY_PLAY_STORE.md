# Deploy a Google Play Store — Flutter Checklist + Template

> **Propósito:** Documentación reusable para cualquier app Flutter.  
> Los textos en `[corchetes]` son marcadores para reemplazar con los datos de tu app.

### Esta app

| Campo | Valor |
|---|---|
| Application ID (Android) | `com.jaimetellezb.shopping_list` |
| Bundle ID (iOS) | `com.jaimetellezb.shoppingList` |
| App name | `La Compra` |
| Versión | `1.0.0+1` |
| Firebase | Analytics + Crashlytics configurados |
| AdMob App ID | `ca-app-pub-9005550345701656~5464523781` |
| Dominio autor | `com.jaimetellezb.*` |

---

## Requisitos previos globales

- [ ] Cuenta de desarrollador Google Play ($25 USD, pago único)
- [ ] [AdMob account](https://admob.google.com) (si usas anuncios)
- [ ] Política de privacidad publicada en URL pública (ver `PRIVACY_POLICY.md`)
- [ ] Icono de app en 512×512 y 1024×1024
- [ ] Screenshots: 2–8 por tipo de dispositivo (mínimo 640px, 16:9 o 9:16)
- [ ] Feature graphic: 1024×500 px (opcional pero recomendado)
- [ ] Descripción corta (80 caracteres) y larga (hasta 4000 caracteres)
- [ ] Categoría de app en Play Console

---

## 1. Application ID — cómo elegirlo

El `applicationId` (también llamado package name) es el **identificador único universal** de tu app.  
**No se puede cambiar después del primer release**, así que elige bien.

### Reglas de naming

```
Formato:  dominio_invertido + proyecto + funcionalidad
Ejemplo: com.miempresa.lista_compras
```

| Correcto ❌ | Correcto ✅ |
|---|---|
| `com.example.mi_app` | `com.micorp.mi_app` |
| `DefaultApp` | `com.micorp.lista_compras` |
| `Mi App` (espacios) | `com.micorp.app` |

### Convenciones recomendadas

```
Personal:   com.{tunombre}.{nombreApp}
Empresa:    com.{empresa}.{nombreApp}
Portafolio: com.{tunombre}.{categoria}.{nombreApp}
```

Ejemplos reales:
- `com.whatsapp`  
- `com.spotify.music`  
- `com.google.android.apps.maps`  
- `com.duolingo`

### Dónde se configura

**`android/app/build.gradle.kts`:**

```kotlin
android {
    namespace = "com.tudominio.lista_compras"
    defaultConfig {
        applicationId = "com.tudominio.lista_compras"
    }
}
```

> Ambos (`namespace` y `applicationId`) deben ser iguales. `namespace` se usa para el código R., `applicationId` es el identificador en Play Store.

---

## 2. Versión semántica

`pubspec.yaml`:

```yaml
version: 1.0.0+1
#         ^    ^
#  versionName | versionCode
```

| Campo | Regla | Ejemplo |
|---|---|---|
| `versionName` | Lo ve el usuario. Semántico: `major.minor.patch` | `1.0.0`, `2.3.1` |
| `versionCode` | Entero. Debe **incrementar** en cada release | `1`, `2`, `3`, `15` |

### Guía de versionado semántico

```
1.0.0  → Primer release estable
1.1.0  → Nueva funcionalidad (compatible hacia atrás)
1.1.1  → Bugfix
2.0.0  → Cambio grande que rompe compatibilidad
```

---

## 3. Generar keystore y release signing

Repetible para cualquier proyecto:

### 3.1 Crear keystore

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass shoppinglist \
  -keypass shoppinglist \
  -dname "CN=Jaime Tellez, OU=Development, O=jaimetellezb, L=Bogota, ST=Bogota, C=CO"
```

Te pedirá:
- Contraseña del keystore (guárdala)
- Contraseña de la key (puede ser igual)
- Nombre, unidad, organización, ciudad, estado, país

### 3.2 Crear `android/key.properties`

```properties
storePassword=tu_contraseña
keyPassword=tu_contraseña
keyAlias=upload
storeFile=upload-keystore.jks
```

### 3.3 `.gitignore`

Verifica que estos archivos sensibles están en `.gitignore`:

```
# Firebase
android/app/google-services.json
lib/firebase_options.dart
ios/Runner/GoogleService-Info.plist

# Keystore
*.jks
*.keystore
key.properties
```

### 3.4 Configurar `android/app/build.gradle.kts`

Antes del bloque `android { }`:

```kotlin
val keystoreProperties = java.util.Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) load(file.inputStream())
}
```

Dentro de `android { }`:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = keystoreProperties["storeFile"]?.let {
            rootProject.file(it)
        }
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            file("proguard-rules.pro")
        )
    }
}
```

---

## 4. Configurar anuncios (AdMob) — template

### IDs reales

Reemplazar en `lib/ads/ad_manager.dart`:

```dart
static const String bannerAdUnitId = 'ca-app-pub-[ID]/[BANNER_ID]';
static const String interstitialAdUnitId = 'ca-app-pub-[ID]/[INTERSTITIAL_ID]';
```

### App ID en Android

`android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-[ID]~[APP_ID]"/>
```

### App ID en iOS

`ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-[ID]~[APP_ID]</string>
```

> Los IDs se obtienen en [AdMob](https://admob.google.com) → Apps → Agregar app.

---

## 5. Configurar Firebase (Analytics + Crashlytics)

### 5.1 Firebase ya incluido en el proyecto

Este proyecto ya tiene:
- `firebase_core`, `firebase_crashlytics`, `firebase_analytics` en `pubspec.yaml`
- Inicialización en `lib/main.dart` (con try-catch para desarrollo)
- Crashlytics configurado para errores fatales y no fatales
- Plugins de Gradle (`google-services` y `crashlytics`) en `android/settings.gradle.kts`
- Archivo `lib/firebase_options.dart` (template — regenerar)
- Archivo `android/app/google-services.json` (template — regenerar)

### 5.2 Configurar Firebase Console


1. Ir a https://console.firebase.google.com
2. "Create a project" (o usar uno existente)
3. Nombre: "shopping-list-app" (o el que quieras)
4. Google Analytics: habilitar
5. Registrar app Android con package name: com.jaimetellezb.shopping_list
6. Descargar google-services.json → copiar a android/app/
7. Registrar app iOS con bundle ID: com.jaimetellezb.shoppingList
8. Descargar GoogleService-Info.plist → copiar a `ios/Runner/GoogleService-Info.plist`
9. **(Obligatorio)** Arrastrar el archivo al proyecto en Xcode (Runner/ Runner) asegurándose de que esté en el target `Runner`

### 5.3 Regenerar Firebase Options (opcional)

`flutterfire configure` genera `lib/firebase_options.dart` automáticamente.
Ya existe un template funcional, pero puedes regenerarlo con:

```bash
flutterfire configure \
  --project=tu-proyecto-firebase \
  --android-package-name=com.jaimetellezb.shopping_list \
  --ios-bundle-id=com.jaimetellezb.shoppingList
```

> `flutterfire configure` pide `google-services.json` descargado del paso anterior.

### 5.4 Archivos sensibles (ya en .gitignore)

```
android/app/google-services.json
lib/firebase_options.dart
ios/Runner/GoogleService-Info.plist
*.jks
key.properties
```

---

## 6. Personalizar app — template

### Nombre

| Plataforma | Archivo | XML/plist |
|---|---|---|
| Android | `AndroidManifest.xml` | `android:label="[Nombre App]"` |
| iOS | `Info.plist` | `CFBundleDisplayName` y `CFBundleName` |

### Icono

Reemplazar en `android/app/src/main/res/mipmap-*/ic_launcher.png`:

| Density | Size |
|---|---|
| mdpi | 48×48 |
| hdpi | 72×72 |
| xhdpi | 96×96 |
| xxhdpi | 144×144 |
| xxxhdpi | 192×192 |
| Play Store | 512×512 |

> Herramientas: [Android Studio → Image Asset](https://developer.android.com/studio/write/image-asset) · [appicon.co](https://appicon.co) · [Canva](https://canva.com)

### minSdk

`android/app/build.gradle.kts`:

```kotlin
defaultConfig {
    minSdk = 24
}
```

> `google_mobile_ads` requiere mínimo 21. Flutter 3.38 default es 24.

---

## 7. Descripciones para Play Store — app actual

### App name
- Android label: `Shopping List`
- iOS display name: `Shopping List`

### Descripción corta (máx. 80 caracteres)

```
Shopping List — Create and manage your grocery lists easily
```

### Descripción larga (~1500 caracteres)

```
Tired of forgetting items at the supermarket? Shopping List helps you create and manage your grocery lists quickly and easily.

Main features:
✓ Create multiple shopping lists
✓ Add products with price and quantity
✓ Mark items as completed
✓ Track total spent and pending items
✓ Completed purchases history
✓ Customizable product categories
✓ Modern Material Design 3 interface
✓ Fully offline — your data stays on your device

Perfect for:
• Weekly grocery shopping
• Party and event planning
• Market shopping
• Home budget tracking

Download now and organize your shopping smartly.
```

---

## 8. Categoría y tags — recomendaciones

### Categoría principal

| App type | Categoría |
|---|---|
| Lista de compras | **Lifestyle** o **Productivity** |
| Juego | según género |
| Red social | Social |
| Utilidad | Tools |

### Tags sugeridos (hasta 5)

```
shopping list, lista de compras, groceries, supermercado, productividad
```

### Clasificación de contenido

| Tipo | Rating |
|---|---|
| Apps sin contenido sensible | **Everyone** |
| Apps con contenido generado por usuario | **Everyone 10+** |
| Apps con referencias a violencia/miedo | **Teen** o mayor |

---

## 9. Política de privacidad

Google Play exige una política de privacidad para apps que:
- Usan **AdMob** o cualquier forma de publicidad
- Recopilan datos personales
- Tienen login/registro

### Cómo publicarla

**Opción 1: GitHub Pages (gratis)**
```bash
# 1. Crear repo público: https://github.com/{usuario}/privacy-policies
# 2. Subir PRIVACY_POLICY.md ahí
# 3. Ir a Settings → Pages → Branch: main
# 4. URL: https://{usuario}.github.io/privacy-policies/nombre-app
```

**Opción 2: Google Drive (gratis)**
- Subir PDF → Compartir → "Anyone with link can view"

> Ver `PRIVACY_POLICY.md` en la raíz del proyecto con una política completa y genérica.

---

## 10. Build de release

```bash
# Limpiar
flutter clean
flutter pub get

# (opcional) regenerar código generado
flutter pub run build_runner build --delete-conflicting-outputs

# Análisis
flutter analyze

# Tests
flutter test

# Build AAB (recomendado)
flutter build appbundle --release

# o APK
flutter build apk --release
```

Output:
```
build/app/outputs/bundle/release/app-release.aab   (AAB ~40-50MB)
build/app/outputs/flutter-apk/app-release.apk       (APK ~30-40MB)
```

---

## 11. Probar release local

```bash
# Si generaste APK
flutter install --release

# Si generaste AAB (requiere bundletool)
java -jar bundletool.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app.apks \
  --ks=android/app/upload-keystore.jks \
  --ks-pass=pass:tu_contraseña

java -jar bundletool.jar install-apks --apks=app.apks
```

---

## 12. Checklist pre-subida a Google Play Console

### Ficha de Play Store
- [x] Application ID definido y único (`com.jaimetellezb.shopping_list`)
- [x] Nombre de la app visible: `La Compra` (Android / iOS)
- [ ] Descripción corta (≤80 caracteres)
- [ ] Descripción larga (≤4000 caracteres)
- [ ] Categoría seleccionada
- [ ] Tags (hasta 5)
- [ ] Icono 512×512 y 1024×1024
- [ ] Feature graphic 1024×500 (opcional)
- [ ] Screenshots (mínimo 2 por tipo de dispositivo)
- [x] URL de política de privacidad: `https://jaimetellezb.github.io/shopping_list_app/`
- [ ] Clasificación de contenido completada

### App bundle
- [x] `versionCode` incrementado respecto al release anterior
- [x] `versionName` actualizado
- [x] Build release firmado con keystore propio
- [x] `minifyEnabled = true` (ProGuard)
- [x] AdMob IDs reales (Android e iOS)
- [x] INTERNET permission agregada al AndroidManifest principal
- [ ] Release notes escritas (what's new)

### Pendientes iOS (Firebase)
- [ ] Descargar `GoogleService-Info.plist` de Firebase Console (bundle ID: `com.jaimetellezb.shoppingList`)
- [ ] Copiar a `ios/Runner/GoogleService-Info.plist`
- [ ] Revisar que no esté en `.gitignore` (o agregarlo manualmente en CI)

> Sin `GoogleService-Info.plist`, Firebase Crashlytics y Analytics NO funcionarán en iOS.

### Legal y distribución
- [ ] Precio definido (gratis o pago)
- [ ] Países de distribución seleccionados
- [ ] App Signing by Google Play habilitado (recomendado)

---

## 13. Proceso de despliegue paso a paso

```
 1. flutter clean
 2. flutter pub get
 3. flutter pub run build_runner build --delete-conflicting-outputs
 4. flutter analyze
 5. flutter test
 6. Actualizar pubspec.yaml → version
 7. flutter build appbundle --release
 8. Probar local: flutter install --release
 9. Ir a https://play.google.com/console
10. Production → Create new release
11. Subir app-release.aab
12. Completar "Release notes" (what's new)
13. Save → Review → Start rollout to Production
14. Esperar revisión de Google (minutos a horas)
15. ¡App en Play Store!
```

---

## 14. Post-deploy

- [ ] Verificar que la app aparece en Play Store
- [ ] Monitorear crashes (Firebase Crashlytics recomendado)
- [ ] Monitorear impresiones y clics en AdMob
- [ ] Responder reseñas de usuarios (primeros días clave)
- [ ] Planear próxima versión con feedback recibido

---

## 15. Resolución de problemas comunes

| Problema | Solución |
|---|---|
| `App not signed` | `key.properties` mal configurado o keystore no encontrado |
| `versionCode already exists` | No incrementaste `versionCode` en `pubspec.yaml` |
| `App rejected: ads policy` | Falta política de privacidad o enlace roto |
| `App rejected: no content rating` | Completar cuestionario de rating en Play Console |
| `Crash on release only` | Revisar ProGuard rules o errores de ofuscación |
| `Google Ads not showing` | Revisar que el App ID de AdMob esté correcto en AndroidManifest |

---

## 16. Template rápido para nueva app

Copia esto en cada nuevo proyecto y reemplaza los `[marcadores]`:

```yaml
# pubspec.yaml
name: [nombre_app]
version: 1.0.0+1
```

```kotlin
// android/settings.gradle.kts
id("com.google.gms.google-services") version "4.4.2" apply false
id("com.google.firebase.crashlytics") version "3.0.3" apply false

// android/app/build.gradle.kts
plugins {
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

namespace = "com.[tu-dominio].[nombre-app]"
defaultConfig {
    applicationId = "com.[tu-dominio].[nombre-app]"
    minSdk = 24
}
```

```xml
<!-- AndroidManifest.xml -->
<application android:label="[Nombre Visible App]">
```

```dart
// ad_manager.dart
static const String bannerAdUnitId = 'ca-app-pub-[ID]/[BANNER]';
static const String interstitialAdUnitId = 'ca-app-pub-[ID]/[INTERSTITIAL]';

// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

---

## Recursos

| Recurso | URL |
|---|---|
| Play Console | https://play.google.com/console |
| AdMob | https://admob.google.com |
| Flutter Android deploy docs | https://docs.flutter.dev/deployment/android |
| App Signing by Google Play | https://support.google.com/googleplay/android-developer/answer/9842756 |
| Políticas de datos | https://play.google.com/about/privacy-security-deception/user-data/ |
| Generar iconos | https://appicon.co |
| Generar feature graphic | https://www.canva.com (tamaño: 1024×500) |
