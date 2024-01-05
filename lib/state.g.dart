// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'3d84a7adffa419bf5e6b44e9e92716977bf00a2b';

/// See also [database].
@ProviderFor(database)
final databaseProvider = AutoDisposeFutureProvider<Database>.internal(
  database,
  name: r'databaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$databaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DatabaseRef = AutoDisposeFutureProviderRef<Database>;
String _$sheetMusicHash() => r'e1bd3260ddf0ebd98c5b851a4b5a9b057e6d8464';

/// See also [SheetMusic].
@ProviderFor(SheetMusic)
final sheetMusicProvider =
    AutoDisposeNotifierProvider<SheetMusic, SheetMusicState>.internal(
  SheetMusic.new,
  name: r'sheetMusicProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sheetMusicHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SheetMusic = AutoDisposeNotifier<SheetMusicState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
