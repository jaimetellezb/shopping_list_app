# shopping_list_app
Flutter shopping list app with AdMob integration (banner and interstitial), Hive persistence, and modern UI.

## Getting Started

Este proyecto usa [Hive](https://docs.hivedb.dev/) para persistencia local.

### Cómo agregar un nuevo modelo Hive

1. Anota tu clase con `@HiveType` y cada campo con `@HiveField`.
2. Corre:
   ```sh
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   para generar los adapters.
3. Registra el adapter en `main.dart` antes de abrir cualquier caja:
   ```dart
   Hive.registerAdapter(MiModeloAdapter());
   ```

### Buenas prácticas

- Usa `put` y la clave del objeto para actualizar datos, no borres y vuelvas a llenar la caja.
- Siempre inicializa Hive y registra los adapters antes de usar cualquier caja.
- Si cambias la estructura de un modelo, incrementa el `typeId` y genera de nuevo los adapters.

---

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
