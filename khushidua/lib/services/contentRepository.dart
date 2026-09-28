import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/firebaseRef.dart';
import '../controllers/categoryController.dart';
import '../controllers/duaController.dart';
import '../helpers/contentVersion.dart';
import '../models/categoryModel.dart';
import '../models/duaModel.dart';
import '../models/subCategoryModel.dart';

/// Loads categories, subcategories and duas, from the device cache whenever
/// nothing has changed.
///
/// These used to be three realtime listeners opened on every launch and never
/// closed. The content only changes when an admin edits it, so instead a
/// single small manifest document (`SystemConfiguration/ContentVersion`) is
/// read first; if its version matches the one this device last loaded, all
/// three collections are served from Firestore's on-disk cache with no network
/// reads. The admin panel bumps the version on every content save.
class ContentRepository {
  ContentRepository._();
  static final ContentRepository instance = ContentRepository._();

  static const String manifestDocId = 'ContentVersion';
  static const String _kVersion = 'contentCacheVersion';
  static const String _kFetchedAt = 'contentCacheFetchedAt';

  /// Bounds how long a slow network can hold the launch before falling back
  /// to the cache.
  static const Duration _manifestTimeout = Duration(seconds: 5);

  Future<void>? _inFlight;

  /// Safe to call repeatedly; concurrent calls share one load.
  Future<void> load({bool forceServer = false}) {
    return _inFlight ??= _load(forceServer).whenComplete(() {
      _inFlight = null;
      // Also on failure, so the home grid never waits on a skeleton forever.
      Get.find<CategoryController>().setLoading(false);
    });
  }

  Future<void> _load(bool forceServer) async {
    final prefs = await SharedPreferences.getInstance();
    final localVersion = prefs.getInt(_kVersion);
    final fetchedAtMs = prefs.getInt(_kFetchedAt);
    final remoteVersion = await _readRemoteVersion();

    final source = forceServer
        ? ContentSource.server
        : decideContentSource(
            localVersion: localVersion,
            remoteVersion: remoteVersion,
            fetchedAt: fetchedAtMs == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(fetchedAtMs),
            now: DateTime.now(),
          );
    debugPrint(
      '📦 ContentRepository: local=$localVersion remote=$remoteVersion '
      '-> ${source.name}',
    );

    final loadedFromServer = await _loadAll(source);

    // Only record the version after a complete server load; a partial or
    // cache-only load must not mark this device as up to date.
    if (loadedFromServer) {
      await prefs.setInt(_kVersion, remoteVersion ?? 0);
      await prefs.setInt(_kFetchedAt, DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<int?> _readRemoteVersion() async {
    try {
      final snap = await sysConfigRef
          .doc(manifestDocId)
          .get(const GetOptions(source: Source.server))
          .timeout(_manifestTimeout);
      final version = snap.data()?['version'];
      if (version is int) return version;
      // No manifest yet: treat as version 0 so the device still records a
      // successful load and uses the cache until an admin creates one.
      return snap.exists ? null : 0;
    } catch (e) {
      debugPrint('📦 ContentRepository: manifest unavailable: $e');
      return null;
    }
  }

  /// Returns true only if every collection came from the server.
  Future<bool> _loadAll(ContentSource source) async {
    final results = await Future.wait([
      _fetch(categoryRef, source),
      _fetch(subCategoryRef, source),
      _fetch(duaRef, source),
    ]);

    final categories = Get.find<CategoryController>();
    categories.replaceCategories(
      results[0].docs.map((d) => CategoryModel.fromMap(d.data())).toList(),
    );
    categories.replaceSubCategories(
      results[1].docs.map((d) => SubCategoryModel.fromMap(d.data())).toList(),
    );
    Get.find<DuaController>().replaceDuas(
      results[2].docs.map((d) => DuaModel.fromMap(d.data())).toList(),
    );

    return results.every((r) => !r.metadata.isFromCache);
  }

  /// Reads from [source], falling back to the server when the cache is empty
  /// or unreadable — a cleared cache must not leave the app blank.
  Future<QuerySnapshot<Map<String, dynamic>>> _fetch(
    CollectionReference<Map<String, dynamic>> ref,
    ContentSource source,
  ) async {
    if (source == ContentSource.cache) {
      try {
        final cached = await ref.get(const GetOptions(source: Source.cache));
        if (cached.docs.isNotEmpty) return cached;
      } catch (e) {
        debugPrint('📦 ContentRepository: cache miss on ${ref.id}: $e');
      }
    }
    return ref.get(const GetOptions(source: Source.serverAndCache));
  }
}
