// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'ALBUM';

  @override
  String get api => 'API';

  @override
  String get artists => 'ARTIS';

  @override
  String get artwork => 'SAMPUL';

  @override
  String get appVersion => 'Versi aplikasi';

  @override
  String get artist => 'Artis';

  @override
  String get artistsYouFollow => 'Artis yang Anda ikuti';

  @override
  String get autoplay => 'Putar Otomatis';

  @override
  String get becauseYouListenedTo => 'Karena Anda mendengarkan';

  @override
  String get browseAll => 'Jelajahi semua';

  @override
  String get cancel => 'Batal';

  @override
  String get clearAppCache => 'Hapus Cache Aplikasi?';

  @override
  String get clearCache => 'Hapus Cache';

  @override
  String get clearHistory => 'Hapus Riwayat?';

  @override
  String get clearRecentlyPlayed => 'Hapus yang Baru Diputar';

  @override
  String get contentMarket => 'Pasar Konten';

  @override
  String get continueListening => 'Lanjutkan Mendengarkan';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Lanjutkan pemutaran video di jendela kecil';

  @override
  String get create => 'Buat';

  @override
  String get createAPlaylistToGetStarted => 'Buat playlist untuk memulai';

  @override
  String currentSelectedcountry(Object country) {
    return 'Saat ini: $country';
  }

  @override
  String get deletePlaylist => 'Hapus Playlist';

  @override
  String get editProfile => 'Edit Profil';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Kesalahan memuat pasar: $err';
  }

  @override
  String error(Object error) {
    return 'Kesalahan: $error';
  }

  @override
  String explore(Object genre) {
    return 'Jelajahi $genre';
  }

  @override
  String get fansAlsoLike => 'PENGGEMAR JUGA MENYUKAI';

  @override
  String featuringTouppercase(Object artist) {
    return 'MENAMPILKAN $artist';
  }

  @override
  String get featuredPlaylists => 'Playlist Unggulan';

  @override
  String get followArtistsToSeeThemHere =>
      'Ikuti artis untuk melihat mereka di sini';

  @override
  String get followStationsToSeeThemHere =>
      'Ikuti stasiun untuk melihat mereka di sini';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Paksa streaming audio saja untuk menghemat data';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Membebaskan ruang dan memaksa pemuatan data baru';

  @override
  String get fromYourFavorites => 'Dari favorit Anda';

  @override
  String get goBack => 'Kembali';

  @override
  String inspiredByName(Object name) {
    return 'Terinspirasi oleh $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Terus putar lagu serupa saat antrean berakhir';

  @override
  String get library => 'Koleksi';

  @override
  String get likeAlbumsToSeeThemHere => 'Sukai album untuk melihatnya di sini';

  @override
  String get likedSongs => 'Lagu yang Disukai';

  @override
  String get lowDataMode => 'Mode Hemat Data';

  @override
  String get madeForYou => 'Dibuat Untuk Anda';

  @override
  String moreLikeName(Object name) {
    return 'Lebih mirip $name';
  }

  @override
  String get moreOptions => 'Opsi lainnya';

  @override
  String get nameYourMasterpiece => 'Beri nama mahakarya Anda...';

  @override
  String get newPlaylist => 'Playlist Baru';

  @override
  String get newReleases => 'Rilisan Baru';

  @override
  String get next => 'Berikutnya';

  @override
  String get noAlbumsFound => 'Album tidak ditemukan';

  @override
  String get noArtistsFollowed => 'Tidak ada artis yang diikuti';

  @override
  String get noArtistsFound => 'Artis tidak ditemukan';

  @override
  String get noLikedAlbums => 'Tidak ada album yang disukai';

  @override
  String get noPlaylistsFound => 'Playlist tidak ditemukan';

  @override
  String get noPlaylistsYet => 'Belum ada playlist';

  @override
  String get noResultsFound => 'Hasil tidak ditemukan';

  @override
  String get noStationsFollowed => 'Tidak ada stasiun yang diikuti';

  @override
  String get noTrackPlaying => 'Tidak ada lagu yang diputar';

  @override
  String get noTracksFound => 'Lagu tidak ditemukan';

  @override
  String get playlists => 'PLAYLIST';

  @override
  String get popular => 'POPULER';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Hapus riwayat mendengarkan secara permanen';

  @override
  String get pictureinpicturePip => 'Gambar-dalam-Gambar (PiP)';

  @override
  String get popularAlbums => 'Album Populer';

  @override
  String get popularArtists => 'Artis Populer';

  @override
  String get popularGenres => 'Genre Populer';

  @override
  String get popularSongs => 'Lagu Populer';

  @override
  String get popularTracks => 'Lagu Populer';

  @override
  String get popularHitsRightNow => 'Lagu hit populer saat ini';

  @override
  String get previous => 'Sebelumnya';

  @override
  String get queue => 'ANTREAN';

  @override
  String get recentSearches => 'Pencarian terbaru';

  @override
  String get recommendedForYou => 'Direkomendasikan untuk Anda';

  @override
  String get scraping => 'Mengikis';

  @override
  String get search => 'Cari';

  @override
  String get searchInAlbum => 'Cari dalam album...';

  @override
  String get searchInLibrary => 'Cari dalam koleksi...';

  @override
  String get searchInPlaylist => 'Cari dalam playlist';

  @override
  String get searchLikedSongs => 'Cari lagu yang disukai...';

  @override
  String get searchPopularSongs => 'Cari lagu populer...';

  @override
  String get selectMarket => 'Pilih Pasar';

  @override
  String get settings => 'Pengaturan';

  @override
  String get showVideoPlayer => 'Tampilkan Pemutar Video';

  @override
  String get shuffle => 'Acak';

  @override
  String get spotifyCredentials => 'Kredensial Spotify';

  @override
  String get suggestedStations => 'Stasiun yang Disarankan';

  @override
  String get tracks => 'LAGU';

  @override
  String get trending => 'Sedang Tren';

  @override
  String get tryAgain => 'Coba Lagi';

  @override
  String get tryADifferentSearchTerm => 'Coba istilah pencarian yang berbeda';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Gunakan pemutar YouTube jika tersedia';

  @override
  String get video => 'VIDEO';

  @override
  String get whatDoYouWantToListenTo => 'Apa yang ingin Anda dengarkan?';

  @override
  String get youtubeCredentials => 'Kredensial YouTube';

  @override
  String get yourLibrary => 'Koleksi Anda';

  @override
  String get playerscreenviewswitch => 'beralih_tampilan_layar_pemain';

  @override
  String get addToPlaylist => 'Tambahkan ke playlist';

  @override
  String get addToQueue => 'Tambahkan ke antrean';

  @override
  String get copyId => 'Salin ID';

  @override
  String get copyLink => 'Salin tautan';

  @override
  String get discover => 'Temukan';

  @override
  String get enterYourName => 'Masukkan nama Anda';

  @override
  String get favorites => 'Favorit';

  @override
  String get goToAlbum => 'Buka album';

  @override
  String get goToArtist => 'Buka artis';

  @override
  String get goToArtistRadio => 'Buka radio artis';

  @override
  String get goToPlaylist => 'Buka playlist';

  @override
  String get goToSongRadio => 'Buka radio lagu';

  @override
  String get home => 'Beranda';

  @override
  String get myAwesomePlaylist => 'Playlist Luar Biasa Saya';

  @override
  String get myPlaylist => 'Playlist Saya';

  @override
  String get newPlaylist1 => 'Playlist baru';

  @override
  String get play => 'Putar';

  @override
  String get playStation => 'Putar Stasiun';

  @override
  String get playNext => 'Putar selanjutnya';

  @override
  String get playlist => 'Daftar Putar';

  @override
  String get playlistName => 'Nama Playlist';

  @override
  String get playlists1 => 'Playlist';

  @override
  String get queue1 => 'Antrean';

  @override
  String get recentlyPlayed => 'Baru Diputar';

  @override
  String get removeFromQueue => 'Hapus dari antrean';

  @override
  String get retry => 'Coba lagi';

  @override
  String get searchMusicArtistsAlbums => 'Cari musik, artis, album...';

  @override
  String get share => 'Bagikan';

  @override
  String featuringArtist(String artistName) {
    return 'MENAMPILKAN $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Saat ini: $country';
  }

  @override
  String get queueTooltip => 'Antrean';

  @override
  String get searchHint => 'Cari musik, artis, album...';

  @override
  String get language => 'Bahasa';

  @override
  String get systemDefault => 'Default Sistem';

  @override
  String get songsTab => 'Lagu';

  @override
  String get foldersTab => 'Folder';

  @override
  String get artistsTab => 'Artis';

  @override
  String get albumsTab => 'Album';

  @override
  String get genresTab => 'Genre';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Kecepatan Pemutaran';

  @override
  String get addMusic => 'Tambahkan Musik';

  @override
  String get addFiles => 'Tambahkan File';

  @override
  String get addFolder => 'Tambahkan Folder';

  @override
  String get rescanLibrary => 'Pindai Ulang Pustaka';

  @override
  String get sortTitle => 'Urutkan berdasarkan Judul';

  @override
  String get sortArtist => 'Urutkan berdasarkan Artis';

  @override
  String get sortAlbum => 'Urutkan berdasarkan Album';

  @override
  String get sortDuration => 'Urutkan berdasarkan Durasi';

  @override
  String get sortDateAdded => 'Urutkan berdasarkan Tanggal';

  @override
  String get sortBy => 'Urutkan berdasarkan';

  @override
  String get trackInformation => 'Informasi Trek';

  @override
  String get removeFromLibrary => 'Hapus dari Pustaka';

  @override
  String get showInFolder => 'Tampilkan di Folder';

  @override
  String get unknownArtist => 'Artis Tidak Dikenal';

  @override
  String get unknownAlbum => 'Album Tidak Dikenal';

  @override
  String get importedFiles => 'File yang Diimpor';

  @override
  String get playFolder => 'Putar Folder';

  @override
  String get shuffleFolder => 'Acak Folder';

  @override
  String get playAll => 'Putar Semua';

  @override
  String get includeSubfolders => 'Sertakan Subfolder';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trek',
      one: '1 trek',
      zero: '0 trek',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Tidak ada lagu lokal yang ditemukan';

  @override
  String get searchLocalMusic => 'Cari musik lokal...';

  @override
  String get viewAsList => 'Tampilkan sebagai Daftar';

  @override
  String get viewAsGrid => 'Tampilkan sebagai Grid';

  @override
  String get trackInfoPath => 'Jalur';

  @override
  String get trackInfoFormat => 'Format';

  @override
  String get trackInfoDuration => 'Durasi';

  @override
  String get aboutDescription => 'Pemutar media sumber terbuka dan gratis.';

  @override
  String get aboutApp => 'Tentang PPPlayer';

  @override
  String get appTagline => 'Musik Anda. Cara Anda.';

  @override
  String get exploreApp => 'Jelajahi PPPlayer';

  @override
  String get viewSource => 'Lihat sumber';

  @override
  String get seeWhatsNew => 'Lihat yang baru';

  @override
  String get getHelp => 'Dapatkan bantuan';

  @override
  String versionInfo(Object version, Object build) {
    return 'Versi $version (Build $build)';
  }

  @override
  String get createdBy => 'Dibuat oleh Lucas Coelho';

  @override
  String get website => 'Situs Web';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Catatan Rilis';

  @override
  String get support => 'Dukungan';

  @override
  String get license => 'Lisensi';

  @override
  String get acknowledgments => 'Penghargaan';

  @override
  String get close => 'Tutup';

  @override
  String copyright(Object year) {
    return '© $year Kontributor PPPlayer';
  }

  @override
  String get goodMorning => 'Selamat pagi';

  @override
  String get goodAfternoon => 'Selamat siang';

  @override
  String get goodEvening => 'Selamat malam';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Musikmu sedang menunggumu.';

  @override
  String dailyMix(Object number) {
    return 'Mix Harian $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries => 'Favoritmu\ndan penemuan baru';

  @override
  String get discoverWeekly => 'Discover Weekly';

  @override
  String get releaseRadar => 'Release Radar';

  @override
  String get newMusicJustForYou => 'Musik baru\nhanya untukmu';

  @override
  String get chillMix => 'Chill Mix';

  @override
  String get relaxAndUnwind => 'Santai dan nikmati';

  @override
  String get focusMix => 'Focus Mix';

  @override
  String get deepFocusAndProductivity => 'Fokus mendalam\ndan produktivitas';

  @override
  String artistRadio(Object artist) {
    return 'Radio $artist';
  }

  @override
  String genreRadio(Object genre) {
    return 'Radio $genre';
  }

  @override
  String get filterAll => 'Semua';

  @override
  String get filterPlaylists => 'Daftar Putar';

  @override
  String get filterArtists => 'Artis';

  @override
  String get filterAlbums => 'Album';

  @override
  String get filterStations => 'Stasiun';

  @override
  String get filterStreams => 'Aliran';

  @override
  String get localMusicCard => 'Musik Lokal';

  @override
  String get createPlaylistButton => 'Buat Daftar Putar';

  @override
  String get radioStations => 'Stasiun Radio';

  @override
  String get discoverMusic => 'Temukan Musik';

  @override
  String get importLocalMusic => 'Impor Musik Lokal';

  @override
  String get importAudioFiles => 'Impor File Audio';

  @override
  String get importFolder => 'Impor Folder';

  @override
  String get importFolderSubtitle => 'Pilih folder yang berisi file audio';

  @override
  String get importPlaylist => 'Impor daftar putar';

  @override
  String get importPlaylistSubtitle => 'Impor file .m3u atau .m3u8';

  @override
  String get exportPlaylist => 'Ekspor daftar putar';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Format tidak didukung atau file rusak';

  @override
  String get playbackErrorFileInaccessible =>
      'File tidak dapat diakses atau tidak ditemukan';

  @override
  String get localVideosCard => 'Video Lokal';

  @override
  String get noLocalVideos => 'Tidak ada video ditemukan';

  @override
  String get searchLocalVideos => 'Cari video lokal';

  @override
  String get addVideos => 'Tambah video';

  @override
  String get subtitles => 'Subtitle';

  @override
  String get audioTracks => 'Trek Audio';

  @override
  String get loadSubtitleFile => 'Muat file subtitle...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Terjadi kesalahan saat memuat subtitle: $error';
  }

  @override
  String get off => 'Mati';

  @override
  String get playOn => 'Putar di';

  @override
  String get thisDevice => 'Perangkat ini';

  @override
  String get availableDevices => 'Perangkat tersedia';

  @override
  String get searchingDevices => 'Mencari perangkat…';

  @override
  String get refresh => 'Segarkan';

  @override
  String get connecting => 'Menghubungkan…';

  @override
  String connectingTo(String name) {
    return 'Menghubungkan ke $name…';
  }

  @override
  String get connected => 'Terhubung';

  @override
  String get unsupportedOutput =>
      'Sumber ini tidak dapat diputar pada keluaran ini.';

  @override
  String get airPlayAudioOutput => 'AirPlay dan keluaran audio';

  @override
  String get returnForAirPlay =>
      'Putar di perangkat ini untuk menggunakan AirPlay.';

  @override
  String get openSoundSettings =>
      'Buka pengaturan Suara untuk memilih keluaran.';

  @override
  String get soundSettingsError => 'Tidak dapat membuka pengaturan Suara.';

  @override
  String get systemOutput => 'Keluaran sistem';

  @override
  String playingOn(String name) {
    return 'Memutar di $name';
  }

  @override
  String get chooseAirPlay =>
      'Ketuk tombol AirPlay untuk memilih speaker atau TV.';

  @override
  String get airPlayDevice => 'Perangkat AirPlay';

  @override
  String get playOnIphone => 'Putar di iPhone ini';

  @override
  String get chooseIphone =>
      'Pilih iPhone ini menggunakan tombol AirPlay di bawah.';

  @override
  String get profile => 'Profil';

  @override
  String get preferences => 'Preferensi';

  @override
  String get themeColor => 'Warna tema';

  @override
  String get yourMusic => 'Musik Anda';

  @override
  String get apiCredentials => 'Kredensial API';

  @override
  String get dataStorage => 'Data dan penyimpanan';

  @override
  String get editProfileHelp => 'Atur nama dan avatar Anda';

  @override
  String get customProvider => 'Penyedia khusus';

  @override
  String get defaultProvider => 'Bawaan PPPlayer';

  @override
  String get proExperience => 'Pengalaman Pro aktif';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Memuat…';

  @override
  String get unknown => 'Tidak diketahui';

  @override
  String get pause => 'Jeda';

  @override
  String get repeat => 'Ulangi';

  @override
  String get mute => 'Bisukan';

  @override
  String get unmute => 'Aktifkan suara';

  @override
  String get fitVideo => 'Sesuaikan';

  @override
  String get fillVideo => 'Isi';

  @override
  String get fullscreen => 'Layar penuh';

  @override
  String get exitFullscreen => 'Keluar layar penuh';

  @override
  String get volume => 'Volume';

  @override
  String get save => 'Simpan';

  @override
  String get delete => 'Hapus';

  @override
  String get clear => 'Bersihkan';

  @override
  String get follow => 'Ikuti';

  @override
  String get unfollow => 'Berhenti mengikuti';

  @override
  String get following => 'Mengikuti';

  @override
  String get showAll => 'Tampilkan semua';

  @override
  String get appearance => 'Tampilan';

  @override
  String get subtitleSize => 'Ukuran';

  @override
  String get subtitleBackground => 'Latar belakang';

  @override
  String get earlier => 'Lebih awal';

  @override
  String get later => 'Lebih lambat';

  @override
  String get reset => 'Atur ulang';

  @override
  String subtitleDelay(String seconds) {
    return 'Jeda waktu: $seconds dtk';
  }

  @override
  String get morePlaybackControls => 'Kontrol pemutaran lainnya';

  @override
  String get hideVideo => 'Sembunyikan video';

  @override
  String get showVideo => 'Tampilkan video';

  @override
  String get closeQueue => 'Tutup antrean';

  @override
  String get enabled => 'Aktif';

  @override
  String get openFile => 'Buka file…';

  @override
  String get openFolder => 'Buka folder…';

  @override
  String get openUrl => 'Buka URL…';

  @override
  String get fileMenu => 'File';

  @override
  String get viewMenu => 'Tampilan';

  @override
  String get windowMenu => 'Jendela';

  @override
  String get saveChanges => 'Simpan perubahan';

  @override
  String get themeAvatarColor => 'Warna tema dan avatar';

  @override
  String get networkStreams => 'Stream jaringan';

  @override
  String get networkStream => 'Stream jaringan';

  @override
  String get openNetworkStream => 'Buka stream jaringan';

  @override
  String get editPlaylist => 'Edit playlist';

  @override
  String get editStreamItem => 'Edit item stream';

  @override
  String get streamUrl => 'URL stream';

  @override
  String get platformType => 'Platform / jenis';

  @override
  String get optionalTitle => 'Judul (opsional)';

  @override
  String get optionalImageUrl => 'URL gambar (opsional)';

  @override
  String get myStream => 'Stream saya';

  @override
  String get saveToLibrary => 'Simpan ke pustaka';

  @override
  String get justPlay => 'Putar saja';

  @override
  String get autoDetect => 'Deteksi otomatis';

  @override
  String get apiKeyRequired => 'Kunci API diperlukan';

  @override
  String get customApiKey => 'Gunakan kunci API sendiri';

  @override
  String get clientId => 'ID klien';

  @override
  String get clientSecret => 'Rahasia klien';

  @override
  String get saveCredentials => 'Simpan kredensial';

  @override
  String get searchStrategy => 'Strategi pencarian';

  @override
  String get credentialsLocalOnly =>
      'Disimpan dengan aman di perangkat ini. Tidak pernah dikirim ke PPPlayer.';

  @override
  String get scrapingHelp =>
      'Tidak perlu kunci API atau kuota. Mungkin lebih lambat atau kurang andal.';

  @override
  String get streamHelp => 'Masukkan URL HTTP(S) atau tautan playlist M3U.';

  @override
  String get deletePlaylistConfirm => 'Hapus playlist ini secara permanen?';

  @override
  String get clearCacheConfirm =>
      'Hapus data cache? Pustaka dan favorit tetap tidak berubah.';

  @override
  String get clearHistoryConfirm =>
      'Hapus riwayat mendengarkan secara permanen?';

  @override
  String get addedToQueue => 'Ditambahkan ke antrean';

  @override
  String get addedVideo => 'Video ditambahkan';

  @override
  String addedChannels(String count) {
    return 'Saluran ditambahkan: $count';
  }

  @override
  String get removedFromPlaylist => 'Dihapus dari playlist';

  @override
  String get exportCancelled => 'Ekspor dibatalkan';

  @override
  String exportComplete(String count) {
    return 'Playlist diekspor. Item dilewati: $count';
  }

  @override
  String get playlistExported => 'Playlist diekspor';

  @override
  String get live => 'Langsung';

  @override
  String get sponsored => 'Bersponsor';

  @override
  String get removeFromPlaylist => 'Hapus dari playlist';

  @override
  String get likedSongsHelp => 'Simpan lagu untuk melihatnya di sini';

  @override
  String get apiSingleVideoHint =>
      'Anda dapat menambahkan video ini tanpa mengimpor playlist.';

  @override
  String get linkCopied => 'Tautan disalin';

  @override
  String get willPlayNext => 'Akan diputar berikutnya';

  @override
  String get checkItOut => 'Lihat';

  @override
  String get loadFailed => 'Konten tidak dapat dimuat. Silakan coba lagi.';
}
