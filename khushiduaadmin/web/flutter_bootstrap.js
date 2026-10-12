{{flutter_js}}
{{flutter_build_config}}

// A template: `flutter build web` fills in the two lines above, so CanvasKit
// always matches the Flutter that built it. It exists to load the app
// without Flutter's service worker, which is deprecated and, in older
// builds, kept serving the previous panel's files (see index.html).
_flutter.loader.load();
