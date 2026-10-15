import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('released schema 14 data survives candidate open, write and reopen', () async {
    final temp = Directory.systemTemp.createTempSync('ppplayer_upgrade_');
    final file = File('${temp.path}/retained.sqlite');
    addTearDown(() => temp.deleteSync(recursive: true));
    final old = sqlite.sqlite3.open(file.path);
    final schema = File(
      'test/fixtures/release_3_0_2/schema.sql',
    ).readAsStringSync();
    for (final sql in schema.split(';').where((s) => s.trim().isNotEmpty)) {
      old.execute(sql);
    }
    old.execute('PRAGMA user_version = 14');
    old.execute(
      "INSERT INTO tracks (spotify_id,name,artist_id,artist_name,is_favorite,play_count,youtube_video_id) VALUES ('online','Retained 日本語','artist','Artist',1,7,'retained-video')",
    );
    old.execute(
      "INSERT INTO tracks (spotify_id,name,artist_id,artist_name) VALUES ('local','Missing original','local-artist','Local artist')",
    );
    old.execute("INSERT INTO playlists (id,name) VALUES (41,'Retained ñ')");
    old.execute(
      "INSERT INTO playlist_tracks (id,playlist_id,track_spotify_id,position) VALUES (101,41,'online',0),(102,41,'local',1),(103,41,'online',2)",
    );
    old.execute(
      "INSERT INTO artists (spotify_id,name,is_followed) VALUES ('artist','Artist',1)",
    );
    old.execute(
      "INSERT INTO albums (spotify_id,name,artist_id,artist_name,is_liked) VALUES ('album','Retained album','artist','Artist',1)",
    );
    old.execute(
      "INSERT INTO import_roots (id,mechanism,root_locator,display_path,added_at,media_scope) VALUES ('root','filePath','/missing/folder','/missing/folder',1,'both')",
    );
    old.execute(
      "INSERT INTO local_files (library_id,mechanism,locator,display_path,deduplication_key,last_scanned_at,import_root_locator) VALUES ('local','filePath','/missing/folder/song.mp3','/missing/folder/song.mp3','unique-local',1,'/missing/folder')",
    );
    old.execute(
      "INSERT INTO stream_playlists (id,title,source_kind,source_uri) VALUES (51,'Retained streams','url','https://example.invalid/list.m3u')",
    );
    old.execute(
      "INSERT INTO stream_channels (id,playlist_id,title,stream_url,is_favorite,position,live_status) VALUES (61,51,'Channel','https://example.invalid/live',1,0,1)",
    );
    final names = old
        .select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .map((r) => r['name'] as String)
        .toList();
    final retained = {
      for (final name in names)
        name: old
            .select('SELECT * FROM "$name" ORDER BY rowid')
            .map((r) => Map<String, Object?>.from(r))
            .toList(),
    };
    old.close();

    var db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      expect(db.schemaVersion, 14);
      for (final name in names) {
        final rows = await db
            .customSelect('SELECT * FROM "$name" ORDER BY rowid')
            .get();
        expect(
          rows.map((r) => r.data).toList(),
          retained[name],
          reason: '$name retained without loss',
        );
      }
      expect(
        (await db.select(db.playlistTracks).get()).map((r) => r.trackSpotifyId),
        ['online', 'local', 'online'],
      );
      expect(await db.getCachedYoutubeId('online'), 'retained-video');
      expect(
        (await db.customSelect('PRAGMA quick_check').getSingle())
            .data
            .values
            .single,
        'ok',
      );
      await db.customStatement(
        "INSERT INTO playlists (name) VALUES ('Candidate write')",
      );
    } finally {
      await db.close();
    }
    db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      expect((await db.select(db.playlists).get()).map((r) => r.name), [
        'Retained ñ',
        'Candidate write',
      ]);
      expect(
        (await db.select(db.tracks).get())
            .singleWhere((r) => r.spotifyId == 'online')
            .isFavorite,
        isTrue,
      );
      expect(
        (await db.select(db.localFiles).get()).single.locator,
        '/missing/folder/song.mp3',
      );
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .data
            .values
            .single,
        14,
      );
    } finally {
      await db.close();
    }
  });
}
