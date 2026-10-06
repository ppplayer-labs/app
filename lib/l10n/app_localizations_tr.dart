// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'ALBÜMLER';

  @override
  String get api => 'API';

  @override
  String get artists => 'SANATÇILAR';

  @override
  String get artwork => 'KAPAK';

  @override
  String get appVersion => 'Uygulama sürümü';

  @override
  String get artist => 'Sanatçı';

  @override
  String get artistsYouFollow => 'Takip ettiğin sanatçılar';

  @override
  String get autoplay => 'Otomatik oynat';

  @override
  String get becauseYouListenedTo => 'Şunu dinlediğin için:';

  @override
  String get browseAll => 'Tümüne göz at';

  @override
  String get cancel => 'İptal';

  @override
  String get clearAppCache => 'Uygulama Önbelleğini Temizle?';

  @override
  String get clearCache => 'Önbelleği Temizle';

  @override
  String get clearHistory => 'Geçmişi Temizle?';

  @override
  String get clearRecentlyPlayed => 'Son Çalınanları Temizle';

  @override
  String get contentMarket => 'İçerik Pazarı';

  @override
  String get continueListening => 'Dinlemeye Devam Et';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Video oynatımına küçük bir pencerede devam et';

  @override
  String get create => 'Oluştur';

  @override
  String get createAPlaylistToGetStarted =>
      'Başlamak için bir çalma listesi oluşturun';

  @override
  String currentSelectedcountry(Object country) {
    return 'Mevcut: $country';
  }

  @override
  String get deletePlaylist => 'Çalma Listesini Sil';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Pazarlar yüklenirken hata oluştu: $err';
  }

  @override
  String error(Object error) {
    return 'Hata: $error';
  }

  @override
  String explore(Object genre) {
    return 'Keşfet: $genre';
  }

  @override
  String get fansAlsoLike => 'HAYRANLAR BUNLARI DA BEĞENDİ';

  @override
  String featuringTouppercase(Object artist) {
    return 'EŞLİK EDEN: $artist';
  }

  @override
  String get featuredPlaylists => 'Öne Çıkan Çalma Listeleri';

  @override
  String get followArtistsToSeeThemHere =>
      'Sanatçıları takip ederek burada görün';

  @override
  String get followStationsToSeeThemHere =>
      'İstasyonları takip ederek burada görün';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Veri tasarrufu için yalnızca ses akışını zorla';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Alan açar ve bir sonraki yüklemede verileri yenilemeye zorlar';

  @override
  String get fromYourFavorites => 'Favorilerinden';

  @override
  String get goBack => 'Geri Dön';

  @override
  String inspiredByName(Object name) {
    return '$name sanatçısından ilham alındı';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Kuyruk bittiğinde benzer parçaları çalmaya devam et';

  @override
  String get library => 'Kitaplık';

  @override
  String get likeAlbumsToSeeThemHere => 'Albümleri beğenerek burada görün';

  @override
  String get likedSongs => 'Beğenilen Şarkılar';

  @override
  String get lowDataMode => 'Düşük Veri Modu';

  @override
  String get madeForYou => 'Senin İçin Hazırlandı';

  @override
  String moreLikeName(Object name) {
    return '$name benzerleri';
  }

  @override
  String get moreOptions => 'Daha fazla seçenek';

  @override
  String get nameYourMasterpiece => 'Şaheserine bir isim ver...';

  @override
  String get newPlaylist => 'Yeni Çalma Listesi';

  @override
  String get newReleases => 'Yeni Çıkanlar';

  @override
  String get next => 'Sonraki';

  @override
  String get noAlbumsFound => 'Albüm bulunamadı';

  @override
  String get noArtistsFollowed => 'Takip edilen sanatçı yok';

  @override
  String get noArtistsFound => 'Sanatçı bulunamadı';

  @override
  String get noLikedAlbums => 'Beğenilen albüm yok';

  @override
  String get noPlaylistsFound => 'Çalma listesi bulunamadı';

  @override
  String get noPlaylistsYet => 'Henüz çalma listesi yok';

  @override
  String get noResultsFound => 'Sonuç bulunamadı';

  @override
  String get noStationsFollowed => 'Takip edilen istasyon yok';

  @override
  String get noTrackPlaying => 'Çalan parça yok';

  @override
  String get noTracksFound => 'Parça bulunamadı';

  @override
  String get playlists => 'ÇALMA LİSTELERİ';

  @override
  String get popular => 'POPÜLER';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Dinleme geçmişini kalıcı olarak kaldır';

  @override
  String get pictureinpicturePip => 'Resim İçinde Resim (PiP)';

  @override
  String get popularAlbums => 'Popüler Albümler';

  @override
  String get popularArtists => 'Popüler Sanatçılar';

  @override
  String get popularGenres => 'Popüler Türler';

  @override
  String get popularSongs => 'Popüler Şarkılar';

  @override
  String get popularTracks => 'Popüler Parçalar';

  @override
  String get popularHitsRightNow => 'Şu Anki Popüler Hit\'ler';

  @override
  String get previous => 'Önceki';

  @override
  String get queue => 'KUYRUK';

  @override
  String get recentSearches => 'Son aramalar';

  @override
  String get recommendedForYou => 'Senin İçin Önerilenler';

  @override
  String get scraping => 'Veri kazınıyor';

  @override
  String get search => 'Ara';

  @override
  String get searchInAlbum => 'Albümde ara...';

  @override
  String get searchInLibrary => 'Kitaplıkta ara...';

  @override
  String get searchInPlaylist => 'Çalma listesinde ara...';

  @override
  String get searchLikedSongs => 'Beğenilen şarkılarda ara...';

  @override
  String get searchPopularSongs => 'Popüler şarkılarda ara...';

  @override
  String get selectMarket => 'Pazar Seç';

  @override
  String get settings => 'Ayarlar';

  @override
  String get showVideoPlayer => 'Video Oynatıcıyı Göster';

  @override
  String get shuffle => 'Karışık Çal';

  @override
  String get spotifyCredentials => 'Spotify Kimlik Bilgileri';

  @override
  String get suggestedStations => 'Önerilen İstasyonlar';

  @override
  String get tracks => 'PARÇALAR';

  @override
  String get trending => 'Trend Olanlar';

  @override
  String get tryAgain => 'Tekrar Dene';

  @override
  String get tryADifferentSearchTerm => 'Farklı bir arama terimi deneyin';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Mümkün olduğunda YouTube oynatıcısını kullan';

  @override
  String get video => 'VİDEO';

  @override
  String get whatDoYouWantToListenTo => 'Ne dinlemek istersin?';

  @override
  String get youtubeCredentials => 'YouTube Kimlik Bilgileri';

  @override
  String get yourLibrary => 'Kitaplığın';

  @override
  String get playerscreenviewswitch => 'oynatıcı_ekranı_görünüm_değiştiricisi';

  @override
  String get addToPlaylist => 'Çalma Listesine Ekle';

  @override
  String get addToQueue => 'Kuyruğa Ekle';

  @override
  String get copyId => 'ID\'yi Kopyala';

  @override
  String get copyLink => 'Bağlantıyı Kopyala';

  @override
  String get discover => 'Keşfet';

  @override
  String get enterYourName => 'İsmini gir';

  @override
  String get favorites => 'Favoriler';

  @override
  String get goToAlbum => 'Albüme Git';

  @override
  String get goToArtist => 'Sanatçıya Git';

  @override
  String get goToArtistRadio => 'Sanatçı Radyosuna Git';

  @override
  String get goToPlaylist => 'Çalma Listesine Git';

  @override
  String get goToSongRadio => 'Şarkı Radyosuna Git';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get myAwesomePlaylist => 'Harika Çalma Listem';

  @override
  String get myPlaylist => 'Çalma Listem';

  @override
  String get newPlaylist1 => 'Yeni Çalma Listesi';

  @override
  String get play => 'Çal';

  @override
  String get playStation => 'İstasyonu Çal';

  @override
  String get playNext => 'Sonrakini Çal';

  @override
  String get playlist => 'Çalma Listesi';

  @override
  String get playlistName => 'Çalma Listesi Adı';

  @override
  String get playlists1 => 'Çalma Listeleri';

  @override
  String get queue1 => 'Kuyruk';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueUpNext => 'Up next';

  @override
  String get recentlyPlayed => 'Son Çalınanlar';

  @override
  String get removeFromQueue => 'Kuyruktan Kaldır';

  @override
  String get retry => 'Yeniden Dene';

  @override
  String get searchMusicArtistsAlbums => 'Müzik, sanatçı, albüm ara...';

  @override
  String get share => 'Paylaş';

  @override
  String featuringArtist(String artistName) {
    return 'EŞLİK EDEN: $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Mevcut: $country';
  }

  @override
  String get queueTooltip => 'Kuyruk';

  @override
  String get searchHint => 'Müzik, sanatçı, albüm ara...';

  @override
  String get language => 'Dil';

  @override
  String get systemDefault => 'Sistem Varsayılanı';

  @override
  String get songsTab => 'Şarkılar';

  @override
  String get foldersTab => 'Klasörler';

  @override
  String get artistsTab => 'Sanatçılar';

  @override
  String get albumsTab => 'Albümler';

  @override
  String get genresTab => 'Türler';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Oynatma Hızı';

  @override
  String get addMusic => 'Müzik Ekle';

  @override
  String get addFiles => 'Dosya Ekle';

  @override
  String get addFolder => 'Klasör Ekle';

  @override
  String get rescanLibrary => 'Kitaplığı Yeniden Tara';

  @override
  String get sortTitle => 'Başlığa Göre Sırala';

  @override
  String get sortArtist => 'Sanatçıya Göre Sırala';

  @override
  String get sortAlbum => 'Albüme Göre Sırala';

  @override
  String get sortDuration => 'Süreye Göre Sırala';

  @override
  String get sortDateAdded => 'Eklenme Tarihine Göre Sırala';

  @override
  String get sortBy => 'Sıralama ölçütü';

  @override
  String get trackInformation => 'Parça Bilgisi';

  @override
  String get removeFromLibrary => 'Kitaplıktan Kaldır';

  @override
  String get showInFolder => 'Klasörde Göster';

  @override
  String get unknownArtist => 'Bilinmeyen Sanatçı';

  @override
  String get unknownAlbum => 'Bilinmeyen Albüm';

  @override
  String get importedFiles => 'İçe Aktarılan Dosyalar';

  @override
  String get playFolder => 'Klasörü Çal';

  @override
  String get shuffleFolder => 'Klasörü Karışık Çal';

  @override
  String get playAll => 'Tümünü Çal';

  @override
  String get includeSubfolders => 'Alt klasörleri dahil et';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parça',
      one: '1 parça',
      zero: '0 parça',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Yerel Şarkı Yok';

  @override
  String get searchLocalMusic => 'Yerel müzik ara...';

  @override
  String get viewAsList => 'Liste olarak görüntüle';

  @override
  String get viewAsGrid => 'Izgara olarak görüntüle';

  @override
  String get trackInfoPath => 'Yol';

  @override
  String get trackInfoFormat => 'Format';

  @override
  String get trackInfoDuration => 'Süre';

  @override
  String get aboutDescription => 'Ücretsiz, açık kaynaklı bir medya oynatıcı.';

  @override
  String get aboutApp => 'PPPlayer Hakkında';

  @override
  String get appTagline => 'Senin müziğin. Senin tarzın.';

  @override
  String get exploreApp => 'PPPlayer\'ı Keşfet';

  @override
  String get viewSource => 'Kaynak kodu görüntüle';

  @override
  String get seeWhatsNew => 'Yenilikler';

  @override
  String get getHelp => 'Yardım al';

  @override
  String versionInfo(Object version, Object build) {
    return 'Sürüm $version (Derleme $build)';
  }

  @override
  String get createdBy => 'Lucas Coelho tarafından oluşturuldu';

  @override
  String get website => 'Web Sitesi';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Sürüm Notları';

  @override
  String get support => 'Destek';

  @override
  String get license => 'Lisans';

  @override
  String get acknowledgments => 'Teşekkürler';

  @override
  String get close => 'Kapat';

  @override
  String copyright(Object year) {
    return '© $year PPPlayer';
  }

  @override
  String get goodMorning => 'Günaydın';

  @override
  String get goodAfternoon => 'İyi Öğleden Sonralar';

  @override
  String get goodEvening => 'İyi Akşamlar';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Müziğin seni bekliyor';

  @override
  String dailyMix(Object number) {
    return 'Günlük Karışım $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries => 'Favorilerin ve Yeni Keşiflerin';

  @override
  String get discoverWeekly => 'Haftalık Keşif';

  @override
  String get releaseRadar => 'Yeni Çıkanlar Radarı';

  @override
  String get newMusicJustForYou => 'Senin İçin Yeni Müzik';

  @override
  String get chillMix => 'Sakin Karışım';

  @override
  String get relaxAndUnwind => 'Rahatla ve Gevşe';

  @override
  String get focusMix => 'Odaklanma Karışımı';

  @override
  String get deepFocusAndProductivity => 'Derin Odaklanma ve Verimlilik';

  @override
  String artistRadio(Object artist) {
    return '$artist Radyosu';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre Radyosu';
  }

  @override
  String get filterAll => 'Tümü';

  @override
  String get filterPlaylists => 'Çalma Listeleri';

  @override
  String get filterArtists => 'Sanatçılar';

  @override
  String get filterAlbums => 'Albümler';

  @override
  String get filterStations => 'İstasyonlar';

  @override
  String get filterStreams => 'Yayınlar';

  @override
  String get localMusicCard => 'Yerel Müzik';

  @override
  String get createPlaylistButton => 'Çalma Listesi Oluştur';

  @override
  String get radioStations => 'Radyo İstasyonları';

  @override
  String get discoverMusic => 'Müzik Keşfet';

  @override
  String get importLocalMusic => 'Yerel Müzik İçe Aktar';

  @override
  String get importAudioFiles => 'Ses Dosyalarını İçe Aktar';

  @override
  String get importFolder => 'Klasör İçe Aktar';

  @override
  String get importFolderSubtitle => 'Klasörü İçe Aktarma Altyazısı';

  @override
  String get importPlaylist => 'Oynatma listesini içe aktar';

  @override
  String get importPlaylistSubtitle => '.m3u veya .m3u8 dosyası içe aktar';

  @override
  String get exportPlaylist => 'Oynatma listesini dışa aktar';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Desteklenmeyen format veya bozuk dosya';

  @override
  String get playbackErrorFileInaccessible =>
      'Dosyaya erişilemiyor veya bulunamadı';

  @override
  String get localVideosCard => 'Yerel Videolar';

  @override
  String get noLocalVideos => 'Video bulunamadı';

  @override
  String get searchLocalVideos => 'Yerel videoları ara';

  @override
  String get addVideos => 'Video ekle';

  @override
  String get subtitles => 'Altyazılar';

  @override
  String get audioTracks => 'Ses Parçaları';

  @override
  String get loadSubtitleFile => 'Altyazı dosyası yükle...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Altyazı yüklenirken hata oluştu: $error';
  }

  @override
  String get off => 'Kapalı';

  @override
  String get playOn => 'Şurada çal';

  @override
  String get thisDevice => 'Bu cihaz';

  @override
  String get availableDevices => 'Kullanılabilir cihazlar';

  @override
  String get searchingDevices => 'Cihazlar aranıyor…';

  @override
  String get refresh => 'Yenile';

  @override
  String get connecting => 'Bağlanıyor…';

  @override
  String connectingTo(String name) {
    return '$name cihazına bağlanıyor…';
  }

  @override
  String get connected => 'Bağlandı';

  @override
  String get unsupportedOutput => 'Bu kaynak bu çıkışta oynatılamaz.';

  @override
  String get airPlayAudioOutput => 'AirPlay ve ses çıkışı';

  @override
  String get returnForAirPlay => 'AirPlay kullanmak için bu cihazda oynatın.';

  @override
  String get openSoundSettings => 'Bir çıkış seçmek için Ses ayarlarını açın.';

  @override
  String get soundSettingsError => 'Ses ayarları açılamadı.';

  @override
  String get systemOutput => 'Sistem çıkışı';

  @override
  String playingOn(String name) {
    return '$name cihazında çalıyor';
  }

  @override
  String get chooseAirPlay =>
      'Hoparlör veya TV seçmek için AirPlay düğmesine dokunun.';

  @override
  String get airPlayDevice => 'AirPlay cihazı';

  @override
  String get playOnIphone => 'Bu iPhone’da çal';

  @override
  String get chooseIphone =>
      'Aşağıdaki AirPlay düğmesini kullanarak bu iPhone’u seçin.';

  @override
  String get profile => 'Profil';

  @override
  String get preferences => 'Tercihler';

  @override
  String get themeColor => 'Tema rengi';

  @override
  String get yourMusic => 'Müziğiniz';

  @override
  String get apiCredentials => 'API kimlik bilgileri';

  @override
  String get dataStorage => 'Veri ve depolama';

  @override
  String get editProfileHelp => 'Adınızı ve avatarınızı ayarlayın';

  @override
  String get customProvider => 'Özel sağlayıcı';

  @override
  String get defaultProvider => 'PPPlayer varsayılanı';

  @override
  String get proExperience => 'Pro deneyimi etkin';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get pause => 'Duraklat';

  @override
  String get repeat => 'Tekrarla';

  @override
  String get mute => 'Sesi kapat';

  @override
  String get unmute => 'Sesi aç';

  @override
  String get fitVideo => 'Sığdır';

  @override
  String get fillVideo => 'Doldur';

  @override
  String get fullscreen => 'Tam ekran';

  @override
  String get exitFullscreen => 'Tam ekrandan çık';

  @override
  String get volume => 'Ses düzeyi';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get clear => 'Temizle';

  @override
  String get follow => 'Takip et';

  @override
  String get unfollow => 'Takibi bırak';

  @override
  String get following => 'Takip ediliyor';

  @override
  String get showAll => 'Tümünü göster';

  @override
  String get appearance => 'Görünüm';

  @override
  String get subtitleSize => 'Boyut';

  @override
  String get subtitleBackground => 'Arka plan';

  @override
  String get earlier => 'Daha erken';

  @override
  String get later => 'Daha geç';

  @override
  String get reset => 'Sıfırla';

  @override
  String subtitleDelay(String seconds) {
    return 'Gecikme: $seconds sn';
  }

  @override
  String get morePlaybackControls => 'Diğer oynatma kontrolleri';

  @override
  String get hideVideo => 'Videoyu gizle';

  @override
  String get showVideo => 'Videoyu göster';

  @override
  String get closeQueue => 'Kuyruğu kapat';

  @override
  String get enabled => 'Açık';

  @override
  String get openFile => 'Dosya aç…';

  @override
  String get openFolder => 'Klasör aç…';

  @override
  String get openUrl => 'URL aç…';

  @override
  String get fileMenu => 'Dosya';

  @override
  String get viewMenu => 'Görünüm';

  @override
  String get windowMenu => 'Pencere';

  @override
  String get saveChanges => 'Değişiklikleri kaydet';

  @override
  String get themeAvatarColor => 'Tema ve avatar rengi';

  @override
  String get networkStreams => 'Ağ akışları';

  @override
  String get networkStream => 'Ağ akışı';

  @override
  String get openNetworkStream => 'Ağ akışı aç';

  @override
  String get editPlaylist => 'Çalma listesini düzenle';

  @override
  String get editStreamItem => 'Akış öğesini düzenle';

  @override
  String get streamUrl => 'Akış URL’si';

  @override
  String get platformType => 'Platform / tür';

  @override
  String get optionalTitle => 'Başlık (isteğe bağlı)';

  @override
  String get optionalImageUrl => 'Görsel URL’si (isteğe bağlı)';

  @override
  String get myStream => 'Akışım';

  @override
  String get saveToLibrary => 'Kitaplığa kaydet';

  @override
  String get justPlay => 'Yalnızca oynat';

  @override
  String get autoDetect => 'Otomatik algıla';

  @override
  String get apiKeyRequired => 'API anahtarı gerekli';

  @override
  String get customApiKey => 'Özel API anahtarı kullan';

  @override
  String get clientId => 'İstemci kimliği';

  @override
  String get clientSecret => 'İstemci sırrı';

  @override
  String get saveCredentials => 'Kimlik bilgilerini kaydet';

  @override
  String get searchStrategy => 'Arama stratejisi';

  @override
  String get credentialsLocalOnly =>
      'Bu cihazda güvenle saklanır. Asla PPPlayer’a gönderilmez.';

  @override
  String get scrapingHelp =>
      'API anahtarı veya kota gerekmez. Daha yavaş veya daha az güvenilir olabilir.';

  @override
  String get streamHelp =>
      'HTTP(S) URL’si veya M3U çalma listesi bağlantısı girin.';

  @override
  String get deletePlaylistConfirm =>
      'Bu çalma listesi kalıcı olarak silinsin mi?';

  @override
  String get clearCacheConfirm =>
      'Önbellek silinsin mi? Kitaplık ve favoriler değişmez.';

  @override
  String get clearHistoryConfirm =>
      'Dinleme geçmişiniz kalıcı olarak silinsin mi?';

  @override
  String get addedToQueue => 'Kuyruğa eklendi';

  @override
  String get addedVideo => 'Video eklendi';

  @override
  String addedChannels(String count) {
    return 'Eklenen kanallar: $count';
  }

  @override
  String get removedFromPlaylist => 'Çalma listesinden kaldırıldı';

  @override
  String get exportCancelled => 'Dışa aktarma iptal edildi';

  @override
  String exportComplete(String count) {
    return 'Liste dışa aktarıldı. Atlanan öğeler: $count';
  }

  @override
  String get playlistExported => 'Liste dışa aktarıldı';

  @override
  String get live => 'Canlı';

  @override
  String get sponsored => 'Sponsorlu';

  @override
  String get removeFromPlaylist => 'Çalma listesinden kaldır';

  @override
  String get likedSongsHelp => 'Şarkıları kaydedin, burada görünsünler';

  @override
  String get apiSingleVideoHint =>
      'Çalma listesini içe aktarmadan bu videoyu ekleyebilirsiniz.';

  @override
  String get linkCopied => 'Bağlantı kopyalandı';

  @override
  String get willPlayNext => 'Sırada oynatılacak';

  @override
  String get checkItOut => 'İncele';

  @override
  String get loadFailed => 'İçerik yüklenemedi. Lütfen tekrar deneyin.';
}
