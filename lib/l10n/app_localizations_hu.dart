// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'ALBUMOK';

  @override
  String get api => 'API';

  @override
  String get artists => 'ELŐADÓK';

  @override
  String get artwork => 'BORÍTÓ';

  @override
  String get appVersion => 'Alkalmazás verziója';

  @override
  String get artist => 'Előadó';

  @override
  String get artistsYouFollow => 'Követett előadók';

  @override
  String get autoplay => 'Automatikus lejátszás';

  @override
  String get becauseYouListenedTo => 'Mivel ezt hallgattad';

  @override
  String get browseAll => 'Összes böngészése';

  @override
  String get cancel => 'Mégse';

  @override
  String get clearAppCache => 'Törli az alkalmazás gyorsítótárát?';

  @override
  String get clearCache => 'Gyorsítótár törlése';

  @override
  String get clearHistory => 'Törli az előzményeket?';

  @override
  String get clearRecentlyPlayed => 'Nemrég játszottak törlése';

  @override
  String get contentMarket => 'Tartalompiac';

  @override
  String get continueListening => 'Hallgatás folytatása';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Videolejátszás folytatása kis ablakban';

  @override
  String get create => 'Létrehozás';

  @override
  String get createAPlaylistToGetStarted =>
      'Kezdésként hozzon létre egy lejátszási listát';

  @override
  String currentSelectedcountry(Object country) {
    return 'Jelenlegi: $country';
  }

  @override
  String get deletePlaylist => 'Lejátszási lista törlése';

  @override
  String get editProfile => 'Profil szerkesztése';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Hiba a piacok betöltésekor: $err';
  }

  @override
  String error(Object error) {
    return 'Hiba: $error';
  }

  @override
  String explore(Object genre) {
    return '$genre felfedezése';
  }

  @override
  String get fansAlsoLike => 'A RAJONGÓK EZEKET IS KEDVELIK';

  @override
  String featuringTouppercase(Object artist) {
    return 'KÖZREMŰKÖDIK: $artist';
  }

  @override
  String get featuredPlaylists => 'Kiemelt lejátszási listák';

  @override
  String get followArtistsToSeeThemHere =>
      'Kövess előadókat, hogy itt lásd őket';

  @override
  String get followStationsToSeeThemHere =>
      'Kövess állomásokat, hogy itt lásd őket';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Csak hang alapú streamek kényszerítése adatmentéshez';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Helyet szabadít fel, és friss adatokat kényszerít a következő betöltéskor';

  @override
  String get fromYourFavorites => 'A kedvenceid közül';

  @override
  String get goBack => 'Vissza';

  @override
  String inspiredByName(Object name) {
    return 'A(z) $name ihlette';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Hasonló zeneszámok lejátszása a várólista végén';

  @override
  String get library => 'Könyvtár';

  @override
  String get likeAlbumsToSeeThemHere => 'Kedvelj albumokat, hogy itt lásd őket';

  @override
  String get likedSongs => 'Kedvelt dalok';

  @override
  String get lowDataMode => 'Alacsony adatforgalmú mód';

  @override
  String get madeForYou => 'Neked készült';

  @override
  String moreLikeName(Object name) {
    return 'Továbbiak, mint $name';
  }

  @override
  String get moreOptions => 'További beállítások';

  @override
  String get nameYourMasterpiece => 'Nevezd el a mesterműved...';

  @override
  String get newPlaylist => 'Új lejátszási lista';

  @override
  String get newReleases => 'Új megjelenések';

  @override
  String get next => 'Következő';

  @override
  String get noAlbumsFound => 'Nem találhatók albumok';

  @override
  String get noArtistsFollowed => 'Nincsenek követett előadók';

  @override
  String get noArtistsFound => 'Nem találhatók előadók';

  @override
  String get noLikedAlbums => 'Nincsenek kedvelt albumok';

  @override
  String get noPlaylistsFound => 'Nem találhatók lejátszási listák';

  @override
  String get noPlaylistsYet => 'Még nincsenek lejátszási listák';

  @override
  String get noResultsFound => 'Nincs találat';

  @override
  String get noStationsFollowed => 'Nincsenek követett állomások';

  @override
  String get noTrackPlaying => 'Nincs lejátszott zeneszám';

  @override
  String get noTracksFound => 'Nem találhatók zeneszámok';

  @override
  String get playlists => 'LEJÁTSZÁSI LISTÁK';

  @override
  String get popular => 'NÉPSZERŰ';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Lejátszási előzmények végleges eltávolítása';

  @override
  String get pictureinpicturePip => 'Kép a képben (PiP)';

  @override
  String get popularAlbums => 'Népszerű albumok';

  @override
  String get popularArtists => 'Népszerű előadók';

  @override
  String get popularGenres => 'Népszerű műfajok';

  @override
  String get popularSongs => 'Népszerű dalok';

  @override
  String get popularTracks => 'Népszerű zeneszámok';

  @override
  String get popularHitsRightNow => 'Jelenlegi népszerű slágerek';

  @override
  String get previous => 'Előző';

  @override
  String get queue => 'VÁRÓLISTA';

  @override
  String get recentSearches => 'Legutóbbi keresések';

  @override
  String get recommendedForYou => 'Neked ajánlott';

  @override
  String get scraping => 'Adatgyűjtés';

  @override
  String get search => 'Keresés';

  @override
  String get searchInAlbum => 'Keresés az albumban...';

  @override
  String get searchInLibrary => 'Keresés a könyvtárban...';

  @override
  String get searchInPlaylist => 'Keresés a lejátszási listában';

  @override
  String get searchLikedSongs => 'Keresés a kedvelt dalok között...';

  @override
  String get searchPopularSongs => 'Keresés a népszerű dalok között...';

  @override
  String get selectMarket => 'Piac kiválasztása';

  @override
  String get settings => 'Beállítások';

  @override
  String get showVideoPlayer => 'Videolejátszó megjelenítése';

  @override
  String get shuffle => 'Keverés';

  @override
  String get spotifyCredentials => 'Spotify hitelesítő adatok';

  @override
  String get suggestedStations => 'Javasolt állomások';

  @override
  String get tracks => 'ZENESZÁMOK';

  @override
  String get trending => 'Felkapott';

  @override
  String get tryAgain => 'Újrapróbálkozás';

  @override
  String get tryADifferentSearchTerm =>
      'Próbáljon meg egy másik keresőkifejezést';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'YouTube-lejátszó használata, ha elérhető';

  @override
  String get video => 'VIDEÓ';

  @override
  String get whatDoYouWantToListenTo => 'Mit szeretnél hallgatni?';

  @override
  String get youtubeCredentials => 'YouTube hitelesítő adatok';

  @override
  String get yourLibrary => 'Saját könyvtár';

  @override
  String get playerscreenviewswitch => 'lejatszo_kepernyo_nezet_valto';

  @override
  String get addToPlaylist => 'Hozzáadás lejátszási listához';

  @override
  String get addToQueue => 'Hozzáadás a várólistához';

  @override
  String get copyId => 'Azonosító másolása';

  @override
  String get copyLink => 'Hivatkozás másolása';

  @override
  String get discover => 'Felfedezés';

  @override
  String get enterYourName => 'Írja be a nevét';

  @override
  String get favorites => 'Kedvencek';

  @override
  String get goToAlbum => 'Ugrás az albumhoz';

  @override
  String get goToArtist => 'Ugrás az előadóhoz';

  @override
  String get goToArtistRadio => 'Ugrás az előadó rádiójához';

  @override
  String get goToPlaylist => 'Ugrás a lejátszási listához';

  @override
  String get goToSongRadio => 'Ugrás a dal rádiójához';

  @override
  String get home => 'Főoldal';

  @override
  String get myAwesomePlaylist => 'Saját lenyűgöző lejátszási listám';

  @override
  String get myPlaylist => 'Saját lejátszási lista';

  @override
  String get newPlaylist1 => 'Új lejátszási lista';

  @override
  String get play => 'Lejátszás';

  @override
  String get playStation => 'Állomás lejátszása';

  @override
  String get playNext => 'Következő lejátszása';

  @override
  String get playlist => 'Lejátszási lista';

  @override
  String get playlistName => 'Lejátszási lista neve';

  @override
  String get playlists1 => 'Lejátszási listák';

  @override
  String get queue1 => 'Várólista';

  @override
  String get recentlyPlayed => 'Nemrég játszott';

  @override
  String get removeFromQueue => 'Eltávolítás a várólistáról';

  @override
  String get retry => 'Újrapróbálkozás';

  @override
  String get searchMusicArtistsAlbums => 'Zene, előadók, albumok keresése...';

  @override
  String get share => 'Megosztás';

  @override
  String featuringArtist(String artistName) {
    return 'KÖZREMŰKÖDIK: $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Jelenlegi: $country';
  }

  @override
  String get queueTooltip => 'Várólista';

  @override
  String get searchHint => 'Zene, előadók, albumok keresése...';

  @override
  String get language => 'Nyelv';

  @override
  String get systemDefault => 'Rendszer alapértelmezett';

  @override
  String get songsTab => 'Dalok';

  @override
  String get foldersTab => 'Mappák';

  @override
  String get artistsTab => 'Előadók';

  @override
  String get albumsTab => 'Albumok';

  @override
  String get genresTab => 'Műfajok';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Lejátszási sebesség';

  @override
  String get addMusic => 'Zene hozzáadása';

  @override
  String get addFiles => 'Fájlok hozzáadása';

  @override
  String get addFolder => 'Mappa hozzáadása';

  @override
  String get rescanLibrary => 'Könyvtár újraolvasása';

  @override
  String get sortTitle => 'Rendezés cím szerint';

  @override
  String get sortArtist => 'Rendezés előadó szerint';

  @override
  String get sortAlbum => 'Rendezés album szerint';

  @override
  String get sortDuration => 'Rendezés időtartam szerint';

  @override
  String get sortDateAdded => 'Rendezés hozzáadás dátuma szerint';

  @override
  String get sortBy => 'Rendezés';

  @override
  String get trackInformation => 'Szám információi';

  @override
  String get removeFromLibrary => 'Eltávolítás a könyvtárból';

  @override
  String get showInFolder => 'Megjelenítés mappában';

  @override
  String get unknownArtist => 'Ismeretlen előadó';

  @override
  String get unknownAlbum => 'Ismeretlen album';

  @override
  String get importedFiles => 'Importált fájlok';

  @override
  String get playFolder => 'Mappa lejátszása';

  @override
  String get shuffleFolder => 'Mappa keverése';

  @override
  String get playAll => 'Összes lejátszása';

  @override
  String get includeSubfolders => 'Almappák belefoglalása';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count szám',
      one: '1 szám',
      zero: '0 szám',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Nem találhatók helyi dalok';

  @override
  String get searchLocalMusic => 'Helyi zene keresése...';

  @override
  String get viewAsList => 'Megjelenítés listaként';

  @override
  String get viewAsGrid => 'Megjelenítés rácsként';

  @override
  String get trackInfoPath => 'Útvonal';

  @override
  String get trackInfoFormat => 'Formátum';

  @override
  String get trackInfoDuration => 'Időtartam';

  @override
  String get aboutDescription =>
      'Egy ingyenes, nyílt forráskódú médialejátszó.';

  @override
  String get aboutApp => 'A PPPlayer névjegye';

  @override
  String get appTagline => 'A te zenéd. A te stílusod.';

  @override
  String get exploreApp => 'PPPlayer felfedezése';

  @override
  String get viewSource => 'Forráskód megtekintése';

  @override
  String get seeWhatsNew => 'Újdonságok';

  @override
  String get getHelp => 'Segítségkérés';

  @override
  String versionInfo(Object version, Object build) {
    return '$version. verzió ($build. build)';
  }

  @override
  String get createdBy => 'Készítette: Lucas Coelho';

  @override
  String get website => 'Weboldal';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Kiadási megjegyzések';

  @override
  String get support => 'Támogatás';

  @override
  String get license => 'Licenc';

  @override
  String get acknowledgments => 'Köszönetnyilvánítások';

  @override
  String get close => 'Bezárás';

  @override
  String copyright(Object year) {
    return '© $year PPPlayer közreműködők';
  }

  @override
  String get goodMorning => 'Jó reggelt';

  @override
  String get goodAfternoon => 'Jó napot';

  @override
  String get goodEvening => 'Jó estét';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'A zenéd vár rád.';

  @override
  String dailyMix(Object number) {
    return 'Napi mix $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries => 'Kedvenceid\nés új felfedezések';

  @override
  String get discoverWeekly => 'E heti újdonságok';

  @override
  String get releaseRadar => 'Újdonságok';

  @override
  String get newMusicJustForYou => 'Új zene\ncsak neked';

  @override
  String get chillMix => 'Chill mix';

  @override
  String get relaxAndUnwind => 'Dőlj hátra és lazíts';

  @override
  String get focusMix => 'Fókusz mix';

  @override
  String get deepFocusAndProductivity => 'Mély fókusz\nés produktivitás';

  @override
  String artistRadio(Object artist) {
    return '$artist Rádió';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre Rádió';
  }

  @override
  String get filterAll => 'Összes';

  @override
  String get filterPlaylists => 'Lejátszási listák';

  @override
  String get filterArtists => 'Előadók';

  @override
  String get filterAlbums => 'Albumok';

  @override
  String get filterStations => 'Állomások';

  @override
  String get filterStreams => 'Streamek';

  @override
  String get localMusicCard => 'Helyi zene';

  @override
  String get createPlaylistButton => 'Lejátszási lista létrehozása';

  @override
  String get radioStations => 'Rádióállomások';

  @override
  String get discoverMusic => 'Zene felfedezése';

  @override
  String get importLocalMusic => 'Helyi zene importálása';

  @override
  String get importAudioFiles => 'Audiofájlok importálása';

  @override
  String get importFolder => 'Mappa importálása';

  @override
  String get importFolderSubtitle =>
      'Válasszon egy mappát, amely hangfájlokat tartalmaz';

  @override
  String get importPlaylist => 'Lejátszási lista importálása';

  @override
  String get importPlaylistSubtitle => '.m3u vagy .m3u8 fájl importálása';

  @override
  String get exportPlaylist => 'Lejátszási lista exportálása';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Nem támogatott formátum vagy sérült fájl';

  @override
  String get playbackErrorFileInaccessible =>
      'Fájl nem elérhető vagy nem található';

  @override
  String get localVideosCard => 'Helyi videók';

  @override
  String get noLocalVideos => 'Nem található videó';

  @override
  String get searchLocalVideos => 'Helyi videók keresése';

  @override
  String get addVideos => 'Videók hozzáadása';

  @override
  String get subtitles => 'Feliratok';

  @override
  String get audioTracks => 'Hangsávok';

  @override
  String get loadSubtitleFile => 'Feliratfájl betöltése...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Hiba a felirat betöltésekor: $error';
  }

  @override
  String get off => 'Ki';

  @override
  String get playOn => 'Lejátszás ezen';

  @override
  String get thisDevice => 'Ez az eszköz';

  @override
  String get availableDevices => 'Elérhető eszközök';

  @override
  String get searchingDevices => 'Eszközök keresése…';

  @override
  String get refresh => 'Frissítés';

  @override
  String get connecting => 'Csatlakozás…';

  @override
  String connectingTo(String name) {
    return 'Csatlakozás ehhez: $name…';
  }

  @override
  String get connected => 'Csatlakoztatva';

  @override
  String get unsupportedOutput =>
      'Ez a forrás nem játszható le ezen a kimeneten.';

  @override
  String get airPlayAudioOutput => 'AirPlay és hangkimenet';

  @override
  String get returnForAirPlay =>
      'Az AirPlay használatához játssz le ezen az eszközön.';

  @override
  String get openSoundSettings =>
      'Nyisd meg a hangbeállításokat a kimenet kiválasztásához.';

  @override
  String get soundSettingsError =>
      'Nem sikerült megnyitni a hangbeállításokat.';

  @override
  String get systemOutput => 'Rendszerkimenet';

  @override
  String playingOn(String name) {
    return 'Lejátszás ezen: $name';
  }

  @override
  String get chooseAirPlay =>
      'Érintsd meg az AirPlay gombot hangszóró vagy tévé kiválasztásához.';

  @override
  String get airPlayDevice => 'AirPlay-eszköz';

  @override
  String get playOnIphone => 'Lejátszás ezen az iPhone-on';

  @override
  String get chooseIphone =>
      'Válaszd ezt az iPhone-t az alábbi AirPlay gombbal.';

  @override
  String get profile => 'Profil';

  @override
  String get preferences => 'Beállítások';

  @override
  String get themeColor => 'Téma színe';

  @override
  String get yourMusic => 'A zenéid';

  @override
  String get apiCredentials => 'API-hozzáférési adatok';

  @override
  String get dataStorage => 'Adatok és tárhely';

  @override
  String get editProfileHelp => 'Állítsd be a neved és az avatárod';

  @override
  String get customProvider => 'Egyéni szolgáltató';

  @override
  String get defaultProvider => 'PPPlayer alapértelmezés';

  @override
  String get proExperience => 'Pro mód aktív';

  @override
  String get beta => 'Béta';

  @override
  String get loading => 'Betöltés…';

  @override
  String get unknown => 'Ismeretlen';

  @override
  String get pause => 'Szünet';

  @override
  String get repeat => 'Ismétlés';

  @override
  String get mute => 'Némítás';

  @override
  String get unmute => 'Hang bekapcsolása';

  @override
  String get fitVideo => 'Igazítás';

  @override
  String get fillVideo => 'Kitöltés';

  @override
  String get fullscreen => 'Teljes képernyő';

  @override
  String get exitFullscreen => 'Kilépés a teljes képernyőből';

  @override
  String get volume => 'Hangerő';

  @override
  String get save => 'Mentés';

  @override
  String get delete => 'Törlés';

  @override
  String get clear => 'Kiürítés';

  @override
  String get follow => 'Követés';

  @override
  String get unfollow => 'Követés leállítása';

  @override
  String get following => 'Követve';

  @override
  String get showAll => 'Összes megjelenítése';

  @override
  String get appearance => 'Megjelenés';

  @override
  String get subtitleSize => 'Méret';

  @override
  String get subtitleBackground => 'Háttér';

  @override
  String get earlier => 'Korábban';

  @override
  String get later => 'Később';

  @override
  String get reset => 'Visszaállítás';

  @override
  String subtitleDelay(String seconds) {
    return 'Késleltetés: $seconds mp';
  }

  @override
  String get morePlaybackControls => 'További lejátszási vezérlők';

  @override
  String get hideVideo => 'Videó elrejtése';

  @override
  String get showVideo => 'Videó megjelenítése';

  @override
  String get closeQueue => 'Sor bezárása';

  @override
  String get enabled => 'Be';

  @override
  String get openFile => 'Fájl megnyitása…';

  @override
  String get openFolder => 'Mappa megnyitása…';

  @override
  String get openUrl => 'URL megnyitása…';

  @override
  String get fileMenu => 'Fájl';

  @override
  String get viewMenu => 'Nézet';

  @override
  String get windowMenu => 'Ablak';

  @override
  String get saveChanges => 'Módosítások mentése';

  @override
  String get themeAvatarColor => 'Téma és avatar színe';

  @override
  String get networkStreams => 'Hálózati adatfolyamok';

  @override
  String get networkStream => 'Hálózati adatfolyam';

  @override
  String get openNetworkStream => 'Hálózati adatfolyam megnyitása';

  @override
  String get editPlaylist => 'Lejátszási lista szerkesztése';

  @override
  String get editStreamItem => 'Adatfolyamelem szerkesztése';

  @override
  String get streamUrl => 'Adatfolyam URL-je';

  @override
  String get platformType => 'Platform / típus';

  @override
  String get optionalTitle => 'Cím (nem kötelező)';

  @override
  String get optionalImageUrl => 'Kép URL-je (nem kötelező)';

  @override
  String get myStream => 'Saját adatfolyam';

  @override
  String get saveToLibrary => 'Mentés a könyvtárba';

  @override
  String get justPlay => 'Csak lejátszás';

  @override
  String get autoDetect => 'Automatikus felismerés';

  @override
  String get apiKeyRequired => 'API-kulcs szükséges';

  @override
  String get customApiKey => 'Saját API-kulcs használata';

  @override
  String get clientId => 'Kliensazonosító';

  @override
  String get clientSecret => 'Kliens titkos kulcsa';

  @override
  String get saveCredentials => 'Hozzáférési adatok mentése';

  @override
  String get searchStrategy => 'Keresési stratégia';

  @override
  String get credentialsLocalOnly =>
      'Biztonságosan tárolva ezen az eszközön. Soha nem kerül a PPPlayerhez.';

  @override
  String get scrapingHelp =>
      'Nem kell API-kulcs vagy kvóta. Lassabb vagy kevésbé megbízható lehet.';

  @override
  String get streamHelp =>
      'Adj meg egy HTTP(S) URL-t vagy M3U-listahivatkozást.';

  @override
  String get deletePlaylistConfirm => 'Végleg törlöd ezt a lejátszási listát?';

  @override
  String get clearCacheConfirm =>
      'Törlöd a gyorsítótárat? A könyvtár és a kedvencek változatlanok maradnak.';

  @override
  String get clearHistoryConfirm => 'Végleg törlöd a hallgatási előzményeket?';

  @override
  String get addedToQueue => 'Hozzáadva a sorhoz';

  @override
  String get addedVideo => 'Videó hozzáadva';

  @override
  String addedChannels(String count) {
    return 'Hozzáadott csatornák: $count';
  }

  @override
  String get removedFromPlaylist => 'Eltávolítva a listából';

  @override
  String get exportCancelled => 'Exportálás megszakítva';

  @override
  String exportComplete(String count) {
    return 'Lista exportálva. Kihagyott elemek: $count';
  }

  @override
  String get playlistExported => 'Lista exportálva';

  @override
  String get live => 'Élő';

  @override
  String get sponsored => 'Szponzorált';

  @override
  String get removeFromPlaylist => 'Eltávolítás a listából';

  @override
  String get likedSongsHelp => 'Ments dalokat, hogy itt megjelenjenek';

  @override
  String get apiSingleVideoHint =>
      'A videót a lejátszási lista importálása nélkül is hozzáadhatod.';

  @override
  String get linkCopied => 'Hivatkozás másolva';

  @override
  String get willPlayNext => 'Ez következik';

  @override
  String get checkItOut => 'Nézd meg';

  @override
  String get loadFailed => 'A tartalom nem tölthető be. Próbáld újra.';
}
