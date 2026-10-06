// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

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
  String get artists => 'ARTISTER';

  @override
  String get artwork => 'SKIVOMSLAG';

  @override
  String get appVersion => 'App-version';

  @override
  String get artist => 'Artist';

  @override
  String get artistsYouFollow => 'Artister du följer';

  @override
  String get autoplay => 'Spela upp automatiskt';

  @override
  String get becauseYouListenedTo => 'Eftersom du lyssnade på';

  @override
  String get browseAll => 'Bläddra bland alla';

  @override
  String get cancel => 'Avbryt';

  @override
  String get clearAppCache => 'Rensa appcache?';

  @override
  String get clearCache => 'Rensa cache';

  @override
  String get clearHistory => 'Rensa historik?';

  @override
  String get clearRecentlyPlayed => 'Rensa nyligen spelade';

  @override
  String get contentMarket => 'Innehållsmarknad';

  @override
  String get continueListening => 'Fortsätt lyssna';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Fortsätt videouppspelning i ett litet fönster';

  @override
  String get create => 'Skapa';

  @override
  String get createAPlaylistToGetStarted =>
      'Skapa en spellista för att komma igång';

  @override
  String currentSelectedcountry(Object country) {
    return 'Nuvarande: $country';
  }

  @override
  String get deletePlaylist => 'Ta bort spellista';

  @override
  String get editProfile => 'Redigera profil';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Fel vid inläsning av marknader: $err';
  }

  @override
  String error(Object error) {
    return 'Fel: $error';
  }

  @override
  String explore(Object genre) {
    return 'Utforska $genre';
  }

  @override
  String get fansAlsoLike => 'FANS GILLAR OCKSÅ';

  @override
  String featuringTouppercase(Object artist) {
    return 'MED $artist';
  }

  @override
  String get featuredPlaylists => 'Utvalda spellistor';

  @override
  String get followArtistsToSeeThemHere => 'Följ artister för att se dem här';

  @override
  String get followStationsToSeeThemHere => 'Följ stationer för att se dem här';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Tvinga endast ljud-strömmar för att spara data';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Frigör utrymme och tvingar fram ny data vid nästa inläsning';

  @override
  String get fromYourFavorites => 'Från dina favoriter';

  @override
  String get goBack => 'Gå tillbaka';

  @override
  String inspiredByName(Object name) {
    return 'Inspirerad av $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Fortsätt spela liknande spår när kön tar slut';

  @override
  String get library => 'Bibliotek';

  @override
  String get likeAlbumsToSeeThemHere => 'Gilla album för att se dem här';

  @override
  String get likedSongs => 'Gillade låtar';

  @override
  String get lowDataMode => 'Låg dataförbrukning';

  @override
  String get madeForYou => 'Skapad för dig';

  @override
  String moreLikeName(Object name) {
    return 'Mer som $name';
  }

  @override
  String get moreOptions => 'Fler alternativ';

  @override
  String get nameYourMasterpiece => 'Namnge ditt mästerverk...';

  @override
  String get newPlaylist => 'Ny spellista';

  @override
  String get newReleases => 'Nya releaser';

  @override
  String get next => 'Nästa';

  @override
  String get noAlbumsFound => 'Inga album hittades';

  @override
  String get noArtistsFollowed => 'Inga artister följs';

  @override
  String get noArtistsFound => 'Inga artister hittades';

  @override
  String get noLikedAlbums => 'Inga gillade album';

  @override
  String get noPlaylistsFound => 'Inga spellistor hittades';

  @override
  String get noPlaylistsYet => 'Inga spellistor ännu';

  @override
  String get noResultsFound => 'Inga resultat hittades';

  @override
  String get noStationsFollowed => 'Inga stationer följs';

  @override
  String get noTrackPlaying => 'Inget spår spelas upp';

  @override
  String get noTracksFound => 'Inga spår hittades';

  @override
  String get playlists => 'SPELLISTOR';

  @override
  String get popular => 'POPULÄRA';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Ta bort lyssningshistorik permanent';

  @override
  String get pictureinpicturePip => 'Bild-i-bild (PiP)';

  @override
  String get popularAlbums => 'Populära album';

  @override
  String get popularArtists => 'Populära artister';

  @override
  String get popularGenres => 'Populära genrer';

  @override
  String get popularSongs => 'Populära låtar';

  @override
  String get popularTracks => 'Populära spår';

  @override
  String get popularHitsRightNow => 'Populära hits just nu';

  @override
  String get previous => 'Föregående';

  @override
  String get queue => 'KÖ';

  @override
  String get recentSearches => 'Senaste sökningar';

  @override
  String get recommendedForYou => 'Rekommenderas för dig';

  @override
  String get scraping => 'Hämtar';

  @override
  String get search => 'Sök';

  @override
  String get searchInAlbum => 'Sök i album...';

  @override
  String get searchInLibrary => 'Sök i biblioteket...';

  @override
  String get searchInPlaylist => 'Sök i spellistan';

  @override
  String get searchLikedSongs => 'Sök bland gillade låtar...';

  @override
  String get searchPopularSongs => 'Sök populära låtar...';

  @override
  String get selectMarket => 'Välj marknad';

  @override
  String get settings => 'Inställningar';

  @override
  String get showVideoPlayer => 'Visa videospelare';

  @override
  String get shuffle => 'Blanda';

  @override
  String get spotifyCredentials => 'Spotify-uppgifter';

  @override
  String get suggestedStations => 'Föreslagna stationer';

  @override
  String get tracks => 'SPÅR';

  @override
  String get trending => 'Trender';

  @override
  String get tryAgain => 'Försök igen';

  @override
  String get tryADifferentSearchTerm => 'Försök med en annan sökterm';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Använd YouTube-spelaren när den är tillgänglig';

  @override
  String get video => 'VIDEO';

  @override
  String get whatDoYouWantToListenTo => 'Vad vill du lyssna på?';

  @override
  String get youtubeCredentials => 'YouTube-uppgifter';

  @override
  String get yourLibrary => 'Ditt bibliotek';

  @override
  String get playerscreenviewswitch => 'vaxla_spelar_skarm_vy';

  @override
  String get addToPlaylist => 'Lägg till i spellista';

  @override
  String get addToQueue => 'Lägg till i kö';

  @override
  String get copyId => 'Kopiera ID';

  @override
  String get copyLink => 'Kopiera länk';

  @override
  String get discover => 'Upptäck';

  @override
  String get enterYourName => 'Ange ditt namn';

  @override
  String get favorites => 'Favoriter';

  @override
  String get goToAlbum => 'Gå till album';

  @override
  String get goToArtist => 'Gå till artist';

  @override
  String get goToArtistRadio => 'Gå till artistradio';

  @override
  String get goToPlaylist => 'Gå till spellista';

  @override
  String get goToSongRadio => 'Gå till låtradio';

  @override
  String get home => 'Hem';

  @override
  String get myAwesomePlaylist => 'Min grymma spellista';

  @override
  String get myPlaylist => 'Min spellista';

  @override
  String get newPlaylist1 => 'Ny spellista';

  @override
  String get play => 'Spela';

  @override
  String get playStation => 'Spela station';

  @override
  String get playNext => 'Spela nästa';

  @override
  String get playlist => 'Spellista';

  @override
  String get playlistName => 'Spellistans namn';

  @override
  String get playlists1 => 'Spellistor';

  @override
  String get queue1 => 'Kö';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueUpNext => 'Up next';

  @override
  String get recentlyPlayed => 'Nyligen spelade';

  @override
  String get removeFromQueue => 'Ta bort från kö';

  @override
  String get retry => 'Försök igen';

  @override
  String get searchMusicArtistsAlbums => 'Sök efter musik, artister, album...';

  @override
  String get share => 'Dela';

  @override
  String featuringArtist(String artistName) {
    return 'MED $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Nuvarande: $country';
  }

  @override
  String get queueTooltip => 'Kö';

  @override
  String get searchHint => 'Sök efter musik, artister, album...';

  @override
  String get language => 'Språk';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get songsTab => 'Låtar';

  @override
  String get foldersTab => 'Mappar';

  @override
  String get artistsTab => 'Artister';

  @override
  String get albumsTab => 'Album';

  @override
  String get genresTab => 'Genrer';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Uppspelningshastighet';

  @override
  String get addMusic => 'Lägg till musik';

  @override
  String get addFiles => 'Lägg till filer';

  @override
  String get addFolder => 'Lägg till mapp';

  @override
  String get rescanLibrary => 'Skanna om bibliotek';

  @override
  String get sortTitle => 'Sortera efter titel';

  @override
  String get sortArtist => 'Sortera efter artist';

  @override
  String get sortAlbum => 'Sortera efter album';

  @override
  String get sortDuration => 'Sortera efter längd';

  @override
  String get sortDateAdded => 'Sortera efter datum';

  @override
  String get sortBy => 'Sortera efter';

  @override
  String get trackInformation => 'Spårinformation';

  @override
  String get removeFromLibrary => 'Ta bort från bibliotek';

  @override
  String get showInFolder => 'Visa i mapp';

  @override
  String get unknownArtist => 'Okänd artist';

  @override
  String get unknownAlbum => 'Okänt album';

  @override
  String get importedFiles => 'Importerade filer';

  @override
  String get playFolder => 'Spela upp mapp';

  @override
  String get shuffleFolder => 'Blanda mapp';

  @override
  String get playAll => 'Spela upp alla';

  @override
  String get includeSubfolders => 'Inkludera undermappar';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spår',
      one: '1 spår',
      zero: '0 spår',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Inga lokala låtar hittades';

  @override
  String get searchLocalMusic => 'Sök lokal musik...';

  @override
  String get viewAsList => 'Visa som lista';

  @override
  String get viewAsGrid => 'Visa som rutnät';

  @override
  String get trackInfoPath => 'Sökväg';

  @override
  String get trackInfoFormat => 'Format';

  @override
  String get trackInfoDuration => 'Längd';

  @override
  String get aboutDescription => 'En gratis mediaspelare med öppen källkod.';

  @override
  String get aboutApp => 'Om PPPlayer';

  @override
  String get appTagline => 'Din musik. På ditt sätt.';

  @override
  String get exploreApp => 'Utforska PPPlayer';

  @override
  String get viewSource => 'Visa källkod';

  @override
  String get seeWhatsNew => 'Nyheter';

  @override
  String get getHelp => 'Få hjälp';

  @override
  String versionInfo(Object version, Object build) {
    return 'Version $version (Bygge $build)';
  }

  @override
  String get createdBy => 'Skapad av Lucas Coelho';

  @override
  String get website => 'Webbplats';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Versionsfakta';

  @override
  String get support => 'Support';

  @override
  String get license => 'Licens';

  @override
  String get acknowledgments => 'Erkännanden';

  @override
  String get close => 'Stäng';

  @override
  String copyright(Object year) {
    return '© $year PPPlayer-bidragsgivare';
  }

  @override
  String get goodMorning => 'God morgon';

  @override
  String get goodAfternoon => 'God eftermiddag';

  @override
  String get goodEvening => 'God kväll';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Din musik väntar.';

  @override
  String dailyMix(Object number) {
    return 'Daily Mix $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'Dina favoriter\noch nya upptäckter';

  @override
  String get discoverWeekly => 'Discover Weekly';

  @override
  String get releaseRadar => 'Release Radar';

  @override
  String get newMusicJustForYou => 'Ny musik\nbara för dig';

  @override
  String get chillMix => 'Chill Mix';

  @override
  String get relaxAndUnwind => 'Koppla av';

  @override
  String get focusMix => 'Focus Mix';

  @override
  String get deepFocusAndProductivity => 'Djupt fokus\noch produktivitet';

  @override
  String artistRadio(Object artist) {
    return '$artist Radio';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre Radio';
  }

  @override
  String get filterAll => 'Allt';

  @override
  String get filterPlaylists => 'Spellistor';

  @override
  String get filterArtists => 'Artister';

  @override
  String get filterAlbums => 'Album';

  @override
  String get filterStations => 'Stationer';

  @override
  String get filterStreams => 'Strömmar';

  @override
  String get localMusicCard => 'Lokal musik';

  @override
  String get createPlaylistButton => 'Skapa spellista';

  @override
  String get radioStations => 'Radiostationer';

  @override
  String get discoverMusic => 'Upptäck musik';

  @override
  String get importLocalMusic => 'Importera lokal musik';

  @override
  String get importAudioFiles => 'Importera ljudfiler';

  @override
  String get importFolder => 'Importera mapp';

  @override
  String get importFolderSubtitle => 'Välj en mapp som innehåller ljudfiler';

  @override
  String get importPlaylist => 'Importera spellista';

  @override
  String get importPlaylistSubtitle => 'Importera .m3u- eller .m3u8-fil';

  @override
  String get exportPlaylist => 'Exportera spellista';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Formatet stöds inte eller filen är skadad';

  @override
  String get playbackErrorFileInaccessible =>
      'Filen är oåtkomlig eller hittades inte';

  @override
  String get localVideosCard => 'Lokala videor';

  @override
  String get noLocalVideos => 'Inga videor hittades';

  @override
  String get searchLocalVideos => 'Sök i lokala videor';

  @override
  String get addVideos => 'Lägg till videor';

  @override
  String get subtitles => 'Undertexter';

  @override
  String get audioTracks => 'Ljudspår';

  @override
  String get loadSubtitleFile => 'Ladda undertextfil...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Fel vid inläsning av undertext: $error';
  }

  @override
  String get off => 'Av';

  @override
  String get playOn => 'Spela på';

  @override
  String get thisDevice => 'Den här enheten';

  @override
  String get availableDevices => 'Tillgängliga enheter';

  @override
  String get searchingDevices => 'Söker efter enheter…';

  @override
  String get refresh => 'Uppdatera';

  @override
  String get connecting => 'Ansluter…';

  @override
  String connectingTo(String name) {
    return 'Ansluter till $name…';
  }

  @override
  String get connected => 'Ansluten';

  @override
  String get unsupportedOutput =>
      'Den här källan kan inte spelas på den här utgången.';

  @override
  String get airPlayAudioOutput => 'AirPlay och ljudutgång';

  @override
  String get returnForAirPlay =>
      'Spela på den här enheten för att använda AirPlay.';

  @override
  String get openSoundSettings =>
      'Öppna ljudinställningarna för att välja en utgång.';

  @override
  String get soundSettingsError => 'Kunde inte öppna ljudinställningarna.';

  @override
  String get systemOutput => 'Systemutgång';

  @override
  String playingOn(String name) {
    return 'Spelar på $name';
  }

  @override
  String get chooseAirPlay =>
      'Tryck på AirPlay-knappen för att välja en högtalare eller tv.';

  @override
  String get airPlayDevice => 'AirPlay-enhet';

  @override
  String get playOnIphone => 'Spela på den här iPhone-enheten';

  @override
  String get chooseIphone => 'Välj denna iPhone med AirPlay-knappen nedan.';

  @override
  String get profile => 'Profil';

  @override
  String get preferences => 'Inställningar';

  @override
  String get themeColor => 'Temafärg';

  @override
  String get yourMusic => 'Din musik';

  @override
  String get apiCredentials => 'API-uppgifter';

  @override
  String get dataStorage => 'Data och lagring';

  @override
  String get editProfileHelp => 'Ange ditt namn och din avatar';

  @override
  String get customProvider => 'Anpassad leverantör';

  @override
  String get defaultProvider => 'PPPlayer-standard';

  @override
  String get proExperience => 'Pro-upplevelse aktiv';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Läser in…';

  @override
  String get unknown => 'Okänd';

  @override
  String get pause => 'Pausa';

  @override
  String get repeat => 'Upprepa';

  @override
  String get mute => 'Stäng av ljud';

  @override
  String get unmute => 'Slå på ljud';

  @override
  String get fitVideo => 'Anpassa';

  @override
  String get fillVideo => 'Fyll';

  @override
  String get fullscreen => 'Helskärm';

  @override
  String get exitFullscreen => 'Avsluta helskärm';

  @override
  String get volume => 'Volym';

  @override
  String get save => 'Spara';

  @override
  String get delete => 'Ta bort';

  @override
  String get clear => 'Rensa';

  @override
  String get follow => 'Följ';

  @override
  String get unfollow => 'Sluta följa';

  @override
  String get following => 'Följer';

  @override
  String get showAll => 'Visa alla';

  @override
  String get appearance => 'Utseende';

  @override
  String get subtitleSize => 'Storlek';

  @override
  String get subtitleBackground => 'Bakgrund';

  @override
  String get earlier => 'Tidigare';

  @override
  String get later => 'Senare';

  @override
  String get reset => 'Återställ';

  @override
  String subtitleDelay(String seconds) {
    return 'Fördröjning: $seconds s';
  }

  @override
  String get morePlaybackControls => 'Fler uppspelningskontroller';

  @override
  String get hideVideo => 'Dölj video';

  @override
  String get showVideo => 'Visa video';

  @override
  String get closeQueue => 'Stäng kö';

  @override
  String get enabled => 'På';

  @override
  String get openFile => 'Öppna fil…';

  @override
  String get openFolder => 'Öppna mapp…';

  @override
  String get openUrl => 'Öppna URL…';

  @override
  String get fileMenu => 'Arkiv';

  @override
  String get viewMenu => 'Visa';

  @override
  String get windowMenu => 'Fönster';

  @override
  String get saveChanges => 'Spara ändringar';

  @override
  String get themeAvatarColor => 'Tema- och avatarfärg';

  @override
  String get networkStreams => 'Nätverksströmmar';

  @override
  String get networkStream => 'Nätverksström';

  @override
  String get openNetworkStream => 'Öppna nätverksström';

  @override
  String get editPlaylist => 'Redigera spellista';

  @override
  String get editStreamItem => 'Redigera strömobjekt';

  @override
  String get streamUrl => 'Ström-URL';

  @override
  String get platformType => 'Plattform / typ';

  @override
  String get optionalTitle => 'Titel (valfri)';

  @override
  String get optionalImageUrl => 'Bild-URL (valfri)';

  @override
  String get myStream => 'Min ström';

  @override
  String get saveToLibrary => 'Spara i bibliotek';

  @override
  String get justPlay => 'Spela endast';

  @override
  String get autoDetect => 'Identifiera automatiskt';

  @override
  String get apiKeyRequired => 'API-nyckel krävs';

  @override
  String get customApiKey => 'Använd egen API-nyckel';

  @override
  String get clientId => 'Klient-id';

  @override
  String get clientSecret => 'Klienthemlighet';

  @override
  String get saveCredentials => 'Spara inloggningsuppgifter';

  @override
  String get searchStrategy => 'Sökstrategi';

  @override
  String get credentialsLocalOnly =>
      'Lagras säkert på denna enhet. Skickas aldrig till PPPlayer.';

  @override
  String get scrapingHelp =>
      'Ingen API-nyckel eller kvot krävs. Kan vara långsammare eller mindre tillförlitligt.';

  @override
  String get streamHelp =>
      'Ange en HTTP(S)-URL eller en länk till en M3U-spellista.';

  @override
  String get deletePlaylistConfirm => 'Ta bort denna spellista permanent?';

  @override
  String get clearCacheConfirm =>
      'Ta bort cachedata? Bibliotek och favoriter förblir oförändrade.';

  @override
  String get clearHistoryConfirm => 'Ta bort din lyssningshistorik permanent?';

  @override
  String get addedToQueue => 'Tillagt i kön';

  @override
  String get addedVideo => 'Video tillagd';

  @override
  String addedChannels(String count) {
    return 'Tillagda kanaler: $count';
  }

  @override
  String get removedFromPlaylist => 'Borttaget från spellistan';

  @override
  String get exportCancelled => 'Export avbruten';

  @override
  String exportComplete(String count) {
    return 'Spellista exporterad. Överhoppade objekt: $count';
  }

  @override
  String get playlistExported => 'Spellista exporterad';

  @override
  String get live => 'Live';

  @override
  String get sponsored => 'Sponsrat';

  @override
  String get removeFromPlaylist => 'Ta bort från spellista';

  @override
  String get likedSongsHelp => 'Spara låtar för att se dem här';

  @override
  String get apiSingleVideoHint =>
      'Du kan lägga till videon utan att importera spellistan.';

  @override
  String get linkCopied => 'Länk kopierad';

  @override
  String get willPlayNext => 'Spelas härnäst';

  @override
  String get checkItOut => 'Ta en titt';

  @override
  String get loadFailed => 'Det gick inte att läsa in innehållet. Försök igen.';
}
