part of firebase_core_dart;

class FirebaseAppDart extends FirebaseAppPlatform {
  FirebaseAppDart._(this._core, String name, FirebaseOptions options)
      : super(name, options);

  FirebaseCoreDart _core;

  bool _isAutomaticDataCollectionEnabled = false;

  @override
  Future<void> delete() async {
    _core._apps.remove(name);
  }

  @override
  bool get isAutomaticDataCollectionEnabled =>
      _isAutomaticDataCollectionEnabled;

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) {
    _isAutomaticDataCollectionEnabled = enabled;
    return Future.value();
  }

  /// Sets whether automatic resource management is enabled or disabled.
  /// This has no affect on Da.
  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) {
    return Future.value();
  }
}