// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'ALBA';

  @override
  String get api => 'API';

  @override
  String get artists => 'UMĚLCI';

  @override
  String get artwork => 'OBRÁZEK';

  @override
  String get appVersion => 'Verze aplikace';

  @override
  String get artist => 'Umělec';

  @override
  String get artistsYouFollow => 'Umělci, které sledujete';

  @override
  String get autoplay => 'Automatické přehrávání';

  @override
  String get becauseYouListenedTo => 'Protože jste poslouchali';

  @override
  String get browseAll => 'Procházet vše';

  @override
  String get cancel => 'Zrušit';

  @override
  String get clearAppCache => 'Vymazat mezipaměť aplikace?';

  @override
  String get clearCache => 'Vymazat mezipaměť';

  @override
  String get clearHistory => 'Vymazat historii?';

  @override
  String get clearRecentlyPlayed => 'Vymazat nedávno přehrané';

  @override
  String get contentMarket => 'Trh s obsahem';

  @override
  String get continueListening => 'Pokračovat v poslechu';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Pokračovat v přehrávání videa v malém okně';

  @override
  String get create => 'Vytvořit';

  @override
  String get createAPlaylistToGetStarted => 'Vytvořte playlist a začněte';

  @override
  String currentSelectedcountry(Object country) {
    return 'Aktuální: $country';
  }

  @override
  String get deletePlaylist => 'Smazat playlist';

  @override
  String get editProfile => 'Upravit profil';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Chyba při načítání trhů: $err';
  }

  @override
  String error(Object error) {
    return 'Chyba: $error';
  }

  @override
  String explore(Object genre) {
    return 'Prozkoumat $genre';
  }

  @override
  String get fansAlsoLike => 'FANOUŠKŮM SE TAKÉ LÍBÍ';

  @override
  String featuringTouppercase(Object artist) {
    return 'S ÚČASTÍ $artist';
  }

  @override
  String get featuredPlaylists => 'Doporučené playlisty';

  @override
  String get followArtistsToSeeThemHere =>
      'Sledujte umělce, abyste je zde viděli';

  @override
  String get followStationsToSeeThemHere =>
      'Sledujte stanice, abyste je zde viděli';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Vynutit pouze zvukové streamy pro úsporu dat';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Uvolní místo a vynutí nová data při dalším načtení';

  @override
  String get fromYourFavorites => 'Z vašich oblíbených';

  @override
  String get goBack => 'Jít zpět';

  @override
  String inspiredByName(Object name) {
    return 'Inspirováno $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Po skončení fronty pokračovat v přehrávání podobných skladeb';

  @override
  String get library => 'Knihovna';

  @override
  String get likeAlbumsToSeeThemHere =>
      'Dejte to se mi líbí u alb, abyste je zde viděli';

  @override
  String get likedSongs => 'Oblíbené skladby';

  @override
  String get lowDataMode => 'Režim úspory dat';

  @override
  String get madeForYou => 'Vytvořeno pro vás';

  @override
  String moreLikeName(Object name) {
    return 'Více jako $name';
  }

  @override
  String get moreOptions => 'Další možnosti';

  @override
  String get nameYourMasterpiece => 'Pojmenujte své mistrovské dílo...';

  @override
  String get newPlaylist => 'Nový playlist';

  @override
  String get newReleases => 'Nová vydání';

  @override
  String get next => 'Další';

  @override
  String get noAlbumsFound => 'Nenalezena žádná alba';

  @override
  String get noArtistsFollowed => 'Nesledujete žádné umělce';

  @override
  String get noArtistsFound => 'Nenalezeni žádní umělci';

  @override
  String get noLikedAlbums => 'Žádná oblíbená alba';

  @override
  String get noPlaylistsFound => 'Nenalezeny žádné playlisty';

  @override
  String get noPlaylistsYet => 'Zatím žádné playlisty';

  @override
  String get noResultsFound => 'Nenalezeny žádné výsledky';

  @override
  String get noStationsFollowed => 'Nesledujete žádné stanice';

  @override
  String get noTrackPlaying => 'Nehraje žádná skladba';

  @override
  String get noTracksFound => 'Nenalezeny žádné skladby';

  @override
  String get playlists => 'PLAYLISTY';

  @override
  String get popular => 'POPULÁRNÍ';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Trvale odstranit historii poslechu';

  @override
  String get pictureinpicturePip => 'Obraz v obraze (PiP)';

  @override
  String get popularAlbums => 'Populární alba';

  @override
  String get popularArtists => 'Populární umělci';

  @override
  String get popularGenres => 'Populární žánry';

  @override
  String get popularSongs => 'Populární skladby';

  @override
  String get popularTracks => 'Populární skladby';

  @override
  String get popularHitsRightNow => 'Populární hity právě teď';

  @override
  String get previous => 'Předchozí';

  @override
  String get queue => 'FRONTA';

  @override
  String get recentSearches => 'Nedávná hledání';

  @override
  String get recommendedForYou => 'Doporučeno pro vás';

  @override
  String get scraping => 'Získávání dat';

  @override
  String get search => 'Hledat';

  @override
  String get searchInAlbum => 'Hledat v albu...';

  @override
  String get searchInLibrary => 'Hledat v knihovně...';

  @override
  String get searchInPlaylist => 'Hledat v playlistu';

  @override
  String get searchLikedSongs => 'Hledat v oblíbených skladbách...';

  @override
  String get searchPopularSongs => 'Hledat populární skladby...';

  @override
  String get selectMarket => 'Vybrat trh';

  @override
  String get settings => 'Nastavení';

  @override
  String get showVideoPlayer => 'Zobrazit videopřehrávač';

  @override
  String get shuffle => 'Náhodně';

  @override
  String get spotifyCredentials => 'Přihlašovací údaje Spotify';

  @override
  String get suggestedStations => 'Navrhované stanice';

  @override
  String get tracks => 'SKLADBY';

  @override
  String get trending => 'Trendy';

  @override
  String get tryAgain => 'Zkusit znovu';

  @override
  String get tryADifferentSearchTerm => 'Zkuste jiný hledaný výraz';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Použít přehrávač YouTube, když je k dispozici';

  @override
  String get video => 'VIDEO';

  @override
  String get whatDoYouWantToListenTo => 'Co chcete poslouchat?';

  @override
  String get youtubeCredentials => 'Přihlašovací údaje YouTube';

  @override
  String get yourLibrary => 'Vaše knihovna';

  @override
  String get playerscreenviewswitch => 'prepinac_zobrazeni_prehravace';

  @override
  String get addToPlaylist => 'Přidat do playlistu';

  @override
  String get addToQueue => 'Přidat do fronty';

  @override
  String get copyId => 'Kopírovat ID';

  @override
  String get copyLink => 'Kopírovat odkaz';

  @override
  String get discover => 'Objevit';

  @override
  String get enterYourName => 'Zadejte své jméno';

  @override
  String get favorites => 'Oblíbené';

  @override
  String get goToAlbum => 'Přejít na album';

  @override
  String get goToArtist => 'Přejít na umělce';

  @override
  String get goToArtistRadio => 'Přejít na rádio umělce';

  @override
  String get goToPlaylist => 'Přejít na playlist';

  @override
  String get goToSongRadio => 'Přejít na rádio skladby';

  @override
  String get home => 'Domů';

  @override
  String get myAwesomePlaylist => 'Můj úžasný playlist';

  @override
  String get myPlaylist => 'Můj playlist';

  @override
  String get newPlaylist1 => 'Nový playlist';

  @override
  String get play => 'Přehrát';

  @override
  String get playStation => 'Přehrát stanici';

  @override
  String get playNext => 'Přehrát jako další';

  @override
  String get playlist => 'Playlist';

  @override
  String get playlistName => 'Název playlistu';

  @override
  String get playlists1 => 'Playlisty';

  @override
  String get queue1 => 'Fronta';

  @override
  String get recentlyPlayed => 'Nedávno přehrané';

  @override
  String get removeFromQueue => 'Odebrat z fronty';

  @override
  String get retry => 'Opakovat';

  @override
  String get searchMusicArtistsAlbums => 'Hledat hudbu, umělce, alba...';

  @override
  String get share => 'Sdílet';

  @override
  String featuringArtist(String artistName) {
    return 'S ÚČASTÍ $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Aktuální: $country';
  }

  @override
  String get queueTooltip => 'Fronta';

  @override
  String get searchHint => 'Hledat hudbu, umělce, alba...';

  @override
  String get language => 'Jazyk';

  @override
  String get systemDefault => 'Výchozí systémový';

  @override
  String get songsTab => 'Skladby';

  @override
  String get foldersTab => 'Složky';

  @override
  String get artistsTab => 'Umělci';

  @override
  String get albumsTab => 'Alba';

  @override
  String get genresTab => 'Žánry';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Rychlost přehrávání';

  @override
  String get addMusic => 'Přidat hudbu';

  @override
  String get addFiles => 'Přidat soubory';

  @override
  String get addFolder => 'Přidat složku';

  @override
  String get rescanLibrary => 'Znovu skenovat knihovnu';

  @override
  String get sortTitle => 'Seřadit podle názvu';

  @override
  String get sortArtist => 'Seřadit podle umělce';

  @override
  String get sortAlbum => 'Seřadit podle alba';

  @override
  String get sortDuration => 'Seřadit podle délky';

  @override
  String get sortDateAdded => 'Seřadit podle data přidání';

  @override
  String get sortBy => 'Řadit podle';

  @override
  String get trackInformation => 'Informace o skladbě';

  @override
  String get removeFromLibrary => 'Odebrat z knihovny';

  @override
  String get showInFolder => 'Zobrazit ve složce';

  @override
  String get unknownArtist => 'Neznámý umělec';

  @override
  String get unknownAlbum => 'Neznámé album';

  @override
  String get importedFiles => 'Importované soubory';

  @override
  String get playFolder => 'Přehrát složku';

  @override
  String get shuffleFolder => 'Náhodně přehrát složku';

  @override
  String get playAll => 'Přehrát vše';

  @override
  String get includeSubfolders => 'Zahrnout podsložky';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skladeb',
      few: '$count skladby',
      one: '1 skladba',
      zero: '0 skladeb',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Nenalezeny žádné místní skladby';

  @override
  String get searchLocalMusic => 'Hledat místní hudbu...';

  @override
  String get viewAsList => 'Zobrazit jako seznam';

  @override
  String get viewAsGrid => 'Zobrazit jako mřížku';

  @override
  String get trackInfoPath => 'Cesta';

  @override
  String get trackInfoFormat => 'Formát';

  @override
  String get trackInfoDuration => 'Délka';

  @override
  String get aboutDescription =>
      'Bezplatný přehrávač médií s otevřeným zdrojovým kódem.';

  @override
  String get aboutApp => 'O PPPlayer';

  @override
  String get appTagline => 'Vaše hudba. Vaše pravidla.';

  @override
  String get exploreApp => 'Prozkoumat PPPlayer';

  @override
  String get viewSource => 'Zobrazit zdrojový kód';

  @override
  String get seeWhatsNew => 'Co je nového';

  @override
  String get getHelp => 'Získat pomoc';

  @override
  String versionInfo(Object version, Object build) {
    return 'Verze $version (Sestavení $build)';
  }

  @override
  String get createdBy => 'Vytvořil Lucas Coelho';

  @override
  String get website => 'Webová stránka';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Poznámky k vydání';

  @override
  String get support => 'Podpora';

  @override
  String get license => 'Licence';

  @override
  String get acknowledgments => 'Poděkování';

  @override
  String get close => 'Zavřít';

  @override
  String copyright(Object year) {
    return '© $year Přispěvatelé PPPlayer';
  }

  @override
  String get goodMorning => 'Dobré ráno';

  @override
  String get goodAfternoon => 'Dobré odpoledne';

  @override
  String get goodEvening => 'Dobrý večer';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Vaše hudba čeká.';

  @override
  String dailyMix(Object number) {
    return 'Denní mix $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries => 'Vaše oblíbené\na nové objevy';

  @override
  String get discoverWeekly => 'Objevujte týdně';

  @override
  String get releaseRadar => 'Radar novinek';

  @override
  String get newMusicJustForYou => 'Nová hudba\njen pro vás';

  @override
  String get chillMix => 'Pohodový mix';

  @override
  String get relaxAndUnwind => 'Relaxujte a odpočívejte';

  @override
  String get focusMix => 'Mix pro soustředění';

  @override
  String get deepFocusAndProductivity => 'Hluboké soustředění\na produktivita';

  @override
  String artistRadio(Object artist) {
    return '$artist Rádio';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre Rádio';
  }

  @override
  String get filterAll => 'Vše';

  @override
  String get filterPlaylists => 'Playlisty';

  @override
  String get filterArtists => 'Umělci';

  @override
  String get filterAlbums => 'Alba';

  @override
  String get filterStations => 'Stanice';

  @override
  String get filterStreams => 'Filtrovat streamy';

  @override
  String get localMusicCard => 'Místní hudba';

  @override
  String get createPlaylistButton => 'Vytvořit playlist';

  @override
  String get radioStations => 'Rádiové stanice';

  @override
  String get discoverMusic => 'Objevovat hudbu';

  @override
  String get importLocalMusic => 'Importovat místní hudbu';

  @override
  String get importAudioFiles => 'Importovat zvukové soubory';

  @override
  String get importFolder => 'Importovat složku';

  @override
  String get importFolderSubtitle =>
      'Vyberte složku obsahující zvukové soubory';

  @override
  String get importPlaylist => 'Importovat playlist';

  @override
  String get importPlaylistSubtitle => 'Importovat soubor .m3u nebo .m3u8';

  @override
  String get exportPlaylist => 'Exportovat playlist';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Nepodporovaný formát nebo poškozený soubor';

  @override
  String get playbackErrorFileInaccessible =>
      'Soubor není přístupný nebo nebyl nalezen';

  @override
  String get localVideosCard => 'Místní videa';

  @override
  String get noLocalVideos => 'Nenalezena žádná videa';

  @override
  String get searchLocalVideos => 'Hledat místní videa';

  @override
  String get addVideos => 'Přidat videa';

  @override
  String get subtitles => 'Titulky';

  @override
  String get audioTracks => 'Zvukové stopy';

  @override
  String get loadSubtitleFile => 'Načíst soubor s titulky...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Chyba při načítání titulků: $error';
  }

  @override
  String get off => 'Vypnuto';

  @override
  String get playOn => 'Přehrávat na';

  @override
  String get thisDevice => 'Toto zařízení';

  @override
  String get availableDevices => 'Dostupná zařízení';

  @override
  String get searchingDevices => 'Vyhledávání zařízení…';

  @override
  String get refresh => 'Obnovit';

  @override
  String get connecting => 'Připojování…';

  @override
  String connectingTo(String name) {
    return 'Připojování k $name…';
  }

  @override
  String get connected => 'Připojeno';

  @override
  String get unsupportedOutput => 'Tento zdroj nelze na tomto výstupu přehrát.';

  @override
  String get airPlayAudioOutput => 'AirPlay a zvukový výstup';

  @override
  String get returnForAirPlay =>
      'Chcete-li použít AirPlay, přehrávejte na tomto zařízení.';

  @override
  String get openSoundSettings => 'Otevřete nastavení zvuku a vyberte výstup.';

  @override
  String get soundSettingsError => 'Nastavení zvuku se nepodařilo otevřít.';

  @override
  String get systemOutput => 'Systémový výstup';

  @override
  String playingOn(String name) {
    return 'Přehrávání na $name';
  }

  @override
  String get chooseAirPlay =>
      'Klepnutím na tlačítko AirPlay vyberte reproduktor nebo televizor.';

  @override
  String get airPlayDevice => 'Zařízení AirPlay';

  @override
  String get playOnIphone => 'Přehrávat na tomto iPhonu';

  @override
  String get chooseIphone => 'Vyberte tento iPhone tlačítkem AirPlay níže.';

  @override
  String get profile => 'Profil';

  @override
  String get preferences => 'Předvolby';

  @override
  String get themeColor => 'Barva motivu';

  @override
  String get yourMusic => 'Vaše hudba';

  @override
  String get apiCredentials => 'Přihlašovací údaje API';

  @override
  String get dataStorage => 'Data a úložiště';

  @override
  String get editProfileHelp => 'Nastavte si jméno a avatar';

  @override
  String get customProvider => 'Vlastní poskytovatel';

  @override
  String get defaultProvider => 'Výchozí PPPlayer';

  @override
  String get proExperience => 'Režim Pro aktivní';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Načítání…';

  @override
  String get unknown => 'Neznámé';

  @override
  String get pause => 'Pozastavit';

  @override
  String get repeat => 'Opakovat';

  @override
  String get mute => 'Ztlumit';

  @override
  String get unmute => 'Zapnout zvuk';

  @override
  String get fitVideo => 'Přizpůsobit';

  @override
  String get fillVideo => 'Vyplnit';

  @override
  String get fullscreen => 'Celá obrazovka';

  @override
  String get exitFullscreen => 'Opustit celou obrazovku';

  @override
  String get volume => 'Hlasitost';

  @override
  String get save => 'Uložit';

  @override
  String get delete => 'Smazat';

  @override
  String get clear => 'Vymazat';

  @override
  String get follow => 'Sledovat';

  @override
  String get unfollow => 'Přestat sledovat';

  @override
  String get following => 'Sledováno';

  @override
  String get showAll => 'Zobrazit vše';

  @override
  String get appearance => 'Vzhled';

  @override
  String get subtitleSize => 'Velikost';

  @override
  String get subtitleBackground => 'Pozadí';

  @override
  String get earlier => 'Dříve';

  @override
  String get later => 'Později';

  @override
  String get reset => 'Obnovit';

  @override
  String subtitleDelay(String seconds) {
    return 'Zpoždění: $seconds s';
  }

  @override
  String get morePlaybackControls => 'Další ovládání přehrávání';

  @override
  String get hideVideo => 'Skrýt video';

  @override
  String get showVideo => 'Zobrazit video';

  @override
  String get closeQueue => 'Zavřít frontu';

  @override
  String get enabled => 'Zapnuto';

  @override
  String get openFile => 'Otevřít soubor…';

  @override
  String get openFolder => 'Otevřít složku…';

  @override
  String get openUrl => 'Otevřít URL…';

  @override
  String get fileMenu => 'Soubor';

  @override
  String get viewMenu => 'Zobrazení';

  @override
  String get windowMenu => 'Okno';

  @override
  String get saveChanges => 'Uložit změny';

  @override
  String get themeAvatarColor => 'Barva motivu a avataru';

  @override
  String get networkStreams => 'Síťové streamy';

  @override
  String get networkStream => 'Síťový stream';

  @override
  String get openNetworkStream => 'Otevřít síťový stream';

  @override
  String get editPlaylist => 'Upravit playlist';

  @override
  String get editStreamItem => 'Upravit položku streamu';

  @override
  String get streamUrl => 'URL streamu';

  @override
  String get platformType => 'Platforma / typ';

  @override
  String get optionalTitle => 'Název (volitelný)';

  @override
  String get optionalImageUrl => 'URL obrázku (volitelné)';

  @override
  String get myStream => 'Můj stream';

  @override
  String get saveToLibrary => 'Uložit do knihovny';

  @override
  String get justPlay => 'Pouze přehrát';

  @override
  String get autoDetect => 'Automaticky rozpoznat';

  @override
  String get apiKeyRequired => 'Je vyžadován klíč API';

  @override
  String get customApiKey => 'Použít vlastní klíč API';

  @override
  String get clientId => 'ID klienta';

  @override
  String get clientSecret => 'Tajný klíč klienta';

  @override
  String get saveCredentials => 'Uložit přihlašovací údaje';

  @override
  String get searchStrategy => 'Strategie vyhledávání';

  @override
  String get credentialsLocalOnly =>
      'Bezpečně uložené v tomto zařízení. Nikdy se neposílají do PPPlayer.';

  @override
  String get scrapingHelp =>
      'Není potřeba klíč API ani kvóta. Může být pomalejší nebo méně spolehlivé.';

  @override
  String get streamHelp => 'Zadejte URL HTTP(S) nebo odkaz na playlist M3U.';

  @override
  String get deletePlaylistConfirm => 'Trvale smazat tento playlist?';

  @override
  String get clearCacheConfirm =>
      'Smazat data v mezipaměti? Knihovna a oblíbené zůstanou beze změny.';

  @override
  String get clearHistoryConfirm => 'Trvale smazat historii poslechu?';

  @override
  String get addedToQueue => 'Přidáno do fronty';

  @override
  String get addedVideo => 'Video přidáno';

  @override
  String addedChannels(String count) {
    return 'Přidané kanály: $count';
  }

  @override
  String get removedFromPlaylist => 'Odebráno z playlistu';

  @override
  String get exportCancelled => 'Export zrušen';

  @override
  String exportComplete(String count) {
    return 'Playlist exportován. Přeskočené položky: $count';
  }

  @override
  String get playlistExported => 'Playlist exportován';

  @override
  String get live => 'Živě';

  @override
  String get sponsored => 'Sponzorováno';

  @override
  String get removeFromPlaylist => 'Odebrat z playlistu';

  @override
  String get likedSongsHelp => 'Uložte skladby, aby se tu zobrazily';

  @override
  String get apiSingleVideoHint =>
      'Toto video můžete přidat bez importu playlistu.';

  @override
  String get linkCopied => 'Odkaz zkopírován';

  @override
  String get willPlayNext => 'Přehraje se jako další';

  @override
  String get checkItOut => 'Prohlédnout';

  @override
  String get loadFailed => 'Obsah se nepodařilo načíst. Zkuste to znovu.';
}
