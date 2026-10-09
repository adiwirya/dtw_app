// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modifier_group_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(modifierGroupRepository)
final modifierGroupRepositoryProvider = ModifierGroupRepositoryProvider._();

final class ModifierGroupRepositoryProvider
    extends
        $FunctionalProvider<
          ModifierGroupRepository,
          ModifierGroupRepository,
          ModifierGroupRepository
        >
    with $Provider<ModifierGroupRepository> {
  ModifierGroupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modifierGroupRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modifierGroupRepositoryHash();

  @$internal
  @override
  $ProviderElement<ModifierGroupRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ModifierGroupRepository create(Ref ref) {
    return modifierGroupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModifierGroupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModifierGroupRepository>(value),
    );
  }
}

String _$modifierGroupRepositoryHash() =>
    r'84b406d55b1b468969a7dc80d4d55cb25adaf836';
