import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:ppplayer/core/cache/catalog_cache_repository.dart';
import 'package:ppplayer/core/cache/cache_config.dart';

void main() {
  test('Riverpod SWR emission sequence', () async {
    final refresh = Completer<String>();
    final staleSeen = Completer<void>();
    final freshSeen = Completer<void>();
    final testStreamProvider = StreamProvider.autoDispose<CacheResult<String>>((
      ref,
    ) {
      final repo = ref.watch(catalogCacheRepositoryProvider);
      return repo.watchOrFetch<String>(
        key: 'swr_riverpod_test',
        resourceType: ResourceType.artist,
        fetch: () => refresh.future,
        decode: (json) => json,
        encode: (data) => data,
      );
    });
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // Insert stale data
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    await db
        .into(db.catalogCacheEntries)
        .insert(
          CatalogCacheEntriesCompanion.insert(
            key: 'swr_riverpod_test',
            payload: 'stale_data',
            fetchedAt: twoDaysAgo,
            lastAccessedAt: twoDaysAgo,
            payloadVersion: CacheConfig.catalogPayloadVersion,
            resourceType: ResourceType.artist.name,
          ),
        );

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final states = <AsyncValue<CacheResult<String>>>[];
    container.listen(testStreamProvider, (previous, next) {
      states.add(next);
      if (next.value?.data == 'stale_data' && !staleSeen.isCompleted) {
        staleSeen.complete();
      }
      if (next.value?.data == 'fresh_data' && !freshSeen.isCompleted) {
        freshSeen.complete();
      }
    }, fireImmediately: true);

    // Initial state is loading
    expect(states.length, 1);
    expect(states[0], isA<AsyncLoading>());

    // Observe stale data before allowing the refresh to finish.
    await staleSeen.future.timeout(const Duration(seconds: 5));
    refresh.complete('fresh_data');
    await freshSeen.future.timeout(const Duration(seconds: 5));

    // The sequence should be Loading -> Data(stale) -> Data(fresh)
    expect(states.length, 3);
    expect(states[1], isA<AsyncData>());
    expect(states[1].value!.data, 'stale_data');

    expect(states[2], isA<AsyncData>());
    expect(states[2].value!.data, 'fresh_data');
  });
}
