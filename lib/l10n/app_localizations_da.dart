// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

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
  String get artists => 'KUNSTNERE';

  @override
  String get artwork => 'BILLEDE';

  @override
  String get appVersion => 'App-version';

  @override
  String get artist => 'Kunstner';

  @override
  String get artistsYouFollow => 'Kunstnere du følger';

  @override
  String get autoplay => 'Automatisk afspilning';

  @override
  String get becauseYouListenedTo => 'Fordi du lyttede til';

  @override
  String get browseAll => 'Gennemse alt';

  @override
  String get cancel => 'Annuller';

  @override
  String get clearAppCache => 'Ryd app-cache?';

  @override
  String get clearCache => 'Ryd cache';

  @override
  String get clearHistory => 'Ryd historik?';

  @override
  String get clearRecentlyPlayed => 'Ryd nyligt afspillede';

  @override
  String get contentMarket => 'Indholdsmarked';

  @override
  String get continueListening => 'Fortsæt med at lytte';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Fortsæt videoafspilning i et lille vindue';

  @override
  String get create => 'Opret';

  @override
  String get createAPlaylistToGetStarted =>
      'Opret en playliste for at komme i gang';

  @override
  String currentSelectedcountry(Object country) {
    return 'Nuværende: $country';
  }

  @override
  String get deletePlaylist => 'Slet playliste';

  @override
  String get editProfile => 'Rediger profil';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Fejl ved indlæsning af markeder: $err';
  }

  @override
  String error(Object error) {
    return 'Fejl: $error';
  }

  @override
  String explore(Object genre) {
    return 'Udforsk $genre';
  }

  @override
  String get fansAlsoLike => 'FANS KAN OGSÅ LIDE';

  @override
  String featuringTouppercase(Object artist) {
    return 'MED $artist';
  }

  @override
  String get featuredPlaylists => 'Udvalgte playlister';

  @override
  String get followArtistsToSeeThemHere => 'Følg kunstnere for at se dem her';

  @override
  String get followStationsToSeeThemHere => 'Følg stationer for at se dem her';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Tving kun lyd-streams for at spare data';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Frigør plads og fremtvinger nye data ved næste indlæsning';

  @override
  String get fromYourFavorites => 'Fra dine favoritter';

  @override
  String get goBack => 'Gå tilbage';

  @override
  String inspiredByName(Object name) {
    return 'Inspireret af $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Bliv ved med at afspille lignende numre, når køen slutter';

  @override
  String get library => 'Bibliotek';

  @override
  String get likeAlbumsToSeeThemHere => 'Synes godt om album for at se dem her';

  @override
  String get likedSongs => 'Sange, du synes godt om';

  @override
  String get lowDataMode => 'Lav datatilstand';

  @override
  String get madeForYou => 'Lavet til dig';

  @override
  String moreLikeName(Object name) {
    return 'Mere som $name';
  }

  @override
  String get moreOptions => 'Flere muligheder';

  @override
  String get nameYourMasterpiece => 'Navngiv dit mesterværk...';

  @override
  String get newPlaylist => 'Ny playliste';

  @override
  String get newReleases => 'Nye udgivelser';

  @override
  String get next => 'Næste';

  @override
  String get noAlbumsFound => 'Ingen album fundet';

  @override
  String get noArtistsFollowed => 'Ingen fulgte kunstnere';

  @override
  String get noArtistsFound => 'Ingen kunstnere fundet';

  @override
  String get noLikedAlbums => 'Ingen album, du synes godt om';

  @override
  String get noPlaylistsFound => 'Ingen playlister fundet';

  @override
  String get noPlaylistsYet => 'Ingen playlister endnu';

  @override
  String get noResultsFound => 'Ingen resultater fundet';

  @override
  String get noStationsFollowed => 'Ingen fulgte stationer';

  @override
  String get noTrackPlaying => 'Intet nummer afspilles';

  @override
  String get noTracksFound => 'Ingen numre fundet';

  @override
  String get playlists => 'PLAYLISTER';

  @override
  String get popular => 'POPULÆR';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Fjern lyttehistorik permanent';

  @override
  String get pictureinpicturePip => 'Billede-i-billede (PiP)';

  @override
  String get popularAlbums => 'Populære album';

  @override
  String get popularArtists => 'Populære kunstnere';

  @override
  String get popularGenres => 'Populære genrer';

  @override
  String get popularSongs => 'Populære sange';

  @override
  String get popularTracks => 'Populære numre';

  @override
  String get popularHitsRightNow => 'Populære hits lige nu';

  @override
  String get previous => 'Forrige';

  @override
  String get queue => 'KØ';

  @override
  String get recentSearches => 'Seneste søgninger';

  @override
  String get recommendedForYou => 'Anbefalet til dig';

  @override
  String get scraping => 'Skraber';

  @override
  String get search => 'Søg';

  @override
  String get searchInAlbum => 'Søg i album...';

  @override
  String get searchInLibrary => 'Søg i bibliotek...';

  @override
  String get searchInPlaylist => 'Søg i playliste';

  @override
  String get searchLikedSongs => 'Søg i sange, du synes godt om...';

  @override
  String get searchPopularSongs => 'Søg i populære sange...';

  @override
  String get selectMarket => 'Vælg marked';

  @override
  String get settings => 'Indstillinger';

  @override
  String get showVideoPlayer => 'Vis videoafspiller';

  @override
  String get shuffle => 'Bland';

  @override
  String get spotifyCredentials => 'Spotify-legitimationsoplysninger';

  @override
  String get suggestedStations => 'Foreslåede stationer';

  @override
  String get tracks => 'NUMRE';

  @override
  String get trending => 'Trender';

  @override
  String get tryAgain => 'Prøv igen';

  @override
  String get tryADifferentSearchTerm => 'Prøv et andet søgeord';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Brug YouTube-afspiller, når den er tilgængelig';

  @override
  String get video => 'VIDEO';

  @override
  String get whatDoYouWantToListenTo => 'Hvad vil du lytte til?';

  @override
  String get youtubeCredentials => 'YouTube-legitimationsoplysninger';

  @override
  String get yourLibrary => 'Dit bibliotek';

  @override
  String get playerscreenviewswitch => 'skift_spiller_skaerm_visning';

  @override
  String get addToPlaylist => 'Føj til playliste';

  @override
  String get addToQueue => 'Føj til kø';

  @override
  String get copyId => 'Kopier ID';

  @override
  String get copyLink => 'Kopier link';

  @override
  String get discover => 'Opdag';

  @override
  String get enterYourName => 'Indtast dit navn';

  @override
  String get favorites => 'Favoritter';

  @override
  String get goToAlbum => 'Gå til album';

  @override
  String get goToArtist => 'Gå til kunstner';

  @override
  String get goToArtistRadio => 'Gå til kunstnerradio';

  @override
  String get goToPlaylist => 'Gå til playliste';

  @override
  String get goToSongRadio => 'Gå til sangradio';

  @override
  String get home => 'Hjem';

  @override
  String get myAwesomePlaylist => 'Min fantastiske playliste';

  @override
  String get myPlaylist => 'Min playliste';

  @override
  String get newPlaylist1 => 'Ny playliste';

  @override
  String get play => 'Afspil';

  @override
  String get playStation => 'Afspil station';

  @override
  String get playNext => 'Afspil næste';

  @override
  String get playlist => 'Playliste';

  @override
  String get playlistName => 'Playlistenavn';

  @override
  String get playlists1 => 'Playlister';

  @override
  String get queue1 => 'Kø';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueUpNext => 'Up next';

  @override
  String get recentlyPlayed => 'Nyligt afspillet';

  @override
  String get removeFromQueue => 'Fjern fra kø';

  @override
  String get retry => 'Prøv igen';

  @override
  String get searchMusicArtistsAlbums => 'Søg efter musik, kunstnere, album...';

  @override
  String get share => 'Del';

  @override
  String featuringArtist(String artistName) {
    return 'MED $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Nuværende: $country';
  }

  @override
  String get queueTooltip => 'Kø';

  @override
  String get searchHint => 'Søg efter musik, kunstnere, album...';

  @override
  String get language => 'Sprog';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get songsTab => 'Sange';

  @override
  String get foldersTab => 'Mapper';

  @override
  String get artistsTab => 'Kunstnere';

  @override
  String get albumsTab => 'Album';

  @override
  String get genresTab => 'Genrer';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Afspilningshastighed';

  @override
  String get addMusic => 'Tilføj musik';

  @override
  String get addFiles => 'Tilføj filer';

  @override
  String get addFolder => 'Tilføj mappe';

  @override
  String get rescanLibrary => 'Genskan bibliotek';

  @override
  String get sortTitle => 'Sortér efter titel';

  @override
  String get sortArtist => 'Sortér efter kunstner';

  @override
  String get sortAlbum => 'Sortér efter album';

  @override
  String get sortDuration => 'Sortér efter varighed';

  @override
  String get sortDateAdded => 'Sortér efter tilføjelsesdato';

  @override
  String get sortBy => 'Sortér efter';

  @override
  String get trackInformation => 'Sporinformation';

  @override
  String get removeFromLibrary => 'Fjern fra bibliotek';

  @override
  String get showInFolder => 'Vis i mappe';

  @override
  String get unknownArtist => 'Ukendt kunstner';

  @override
  String get unknownAlbum => 'Ukendt album';

  @override
  String get importedFiles => 'Importerede filer';

  @override
  String get playFolder => 'Afspil mappe';

  @override
  String get shuffleFolder => 'Bland mappe';

  @override
  String get playAll => 'Afspil alle';

  @override
  String get includeSubfolders => 'Inkluder undermapper';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spor',
      one: '1 spor',
      zero: '0 spor',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Ingen lokale sange fundet';

  @override
  String get searchLocalMusic => 'Søg i lokal musik...';

  @override
  String get viewAsList => 'Vis som liste';

  @override
  String get viewAsGrid => 'Vis som gitter';

  @override
  String get trackInfoPath => 'Sti';

  @override
  String get trackInfoFormat => 'Format';

  @override
  String get trackInfoDuration => 'Varighed';

  @override
  String get aboutDescription => 'En gratis, open-source medieafspiller.';

  @override
  String get aboutApp => 'Om PPPlayer';

  @override
  String get appTagline => 'Din musik. På din måde.';

  @override
  String get exploreApp => 'Udforsk PPPlayer';

  @override
  String get viewSource => 'Vis kildekode';

  @override
  String get seeWhatsNew => 'Se hvad der er nyt';

  @override
  String get getHelp => 'Få hjælp';

  @override
  String versionInfo(Object version, Object build) {
    return 'Version $version (Build $build)';
  }

  @override
  String get createdBy => 'Skabt af Lucas Coelho';

  @override
  String get website => 'Hjemmeside';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Udgivelsesnoter';

  @override
  String get support => 'Support';

  @override
  String get license => 'Licens';

  @override
  String get acknowledgments => 'Anerkendelser';

  @override
  String get close => 'Luk';

  @override
  String copyright(Object year) {
    return '© $year PPPlayer bidragydere';
  }

  @override
  String get goodMorning => 'Godmorgen';

  @override
  String get goodAfternoon => 'Godeftermiddag';

  @override
  String get goodEvening => 'Godaften';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Din musik venter.';

  @override
  String dailyMix(Object number) {
    return 'Daglige mix $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'Dine favoritter\nog nye opdagelser';

  @override
  String get discoverWeekly => 'Discover Weekly';

  @override
  String get releaseRadar => 'Release Radar';

  @override
  String get newMusicJustForYou => 'Ny musik\nkun til dig';

  @override
  String get chillMix => 'Chill Mix';

  @override
  String get relaxAndUnwind => 'Slap af og nyd det';

  @override
  String get focusMix => 'Focus Mix';

  @override
  String get deepFocusAndProductivity => 'Dybt fokus\nog produktivitet';

  @override
  String artistRadio(Object artist) {
    return '$artist Radio';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre Radio';
  }

  @override
  String get filterAll => 'Alt';

  @override
  String get filterPlaylists => 'Playlister';

  @override
  String get filterArtists => 'Kunstnere';

  @override
  String get filterAlbums => 'Album';

  @override
  String get filterStations => 'Stationer';

  @override
  String get filterStreams => 'Strømme';

  @override
  String get localMusicCard => 'Lokal musik';

  @override
  String get createPlaylistButton => 'Opret playliste';

  @override
  String get radioStations => 'Radiostationer';

  @override
  String get discoverMusic => 'Opdag musik';

  @override
  String get importLocalMusic => 'Importer lokal musik';

  @override
  String get importAudioFiles => 'Importer lydfiler';

  @override
  String get importFolder => 'Importer mappe';

  @override
  String get importFolderSubtitle => 'Vælg en mappe, der indeholder lydfiler';

  @override
  String get importPlaylist => 'Importer afspilningsliste';

  @override
  String get importPlaylistSubtitle => 'Importer .m3u eller .m3u8 fil';

  @override
  String get exportPlaylist => 'Eksporter afspilningsliste';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Ikke-understøttet format eller beskadiget fil';

  @override
  String get playbackErrorFileInaccessible =>
      'Filen er utilgængelig eller ikke fundet';

  @override
  String get localVideosCard => 'Lokale videoer';

  @override
  String get noLocalVideos => 'Ingen videoer fundet';

  @override
  String get searchLocalVideos => 'Søg i lokale videoer';

  @override
  String get addVideos => 'Tilføj videoer';

  @override
  String get subtitles => 'Undertekster';

  @override
  String get audioTracks => 'Lydspor';

  @override
  String get loadSubtitleFile => 'Indlæs undertekstfil...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Fejl ved indlæsning af undertekster: $error';
  }

  @override
  String get off => 'Fra';

  @override
  String get playOn => 'Afspil på';

  @override
  String get thisDevice => 'Denne enhed';

  @override
  String get availableDevices => 'Tilgængelige enheder';

  @override
  String get searchingDevices => 'Søger efter enheder…';

  @override
  String get refresh => 'Opdater';

  @override
  String get connecting => 'Opretter forbindelse…';

  @override
  String connectingTo(String name) {
    return 'Opretter forbindelse til $name…';
  }

  @override
  String get connected => 'Tilsluttet';

  @override
  String get unsupportedOutput =>
      'Denne kilde kan ikke afspilles på denne udgang.';

  @override
  String get airPlayAudioOutput => 'AirPlay og lydudgang';

  @override
  String get returnForAirPlay => 'Afspil på denne enhed for at bruge AirPlay.';

  @override
  String get openSoundSettings =>
      'Åbn lydindstillingerne for at vælge en udgang.';

  @override
  String get soundSettingsError => 'Kunne ikke åbne lydindstillingerne.';

  @override
  String get systemOutput => 'Systemudgang';

  @override
  String playingOn(String name) {
    return 'Afspiller på $name';
  }

  @override
  String get chooseAirPlay =>
      'Tryk på AirPlay-knappen for at vælge en højttaler eller et tv.';

  @override
  String get airPlayDevice => 'AirPlay-enhed';

  @override
  String get playOnIphone => 'Afspil på denne iPhone';

  @override
  String get chooseIphone => 'Vælg denne iPhone med AirPlay-knappen nedenfor.';

  @override
  String get profile => 'Profil';

  @override
  String get preferences => 'Indstillinger';

  @override
  String get themeColor => 'Temafarve';

  @override
  String get yourMusic => 'Din musik';

  @override
  String get apiCredentials => 'API-oplysninger';

  @override
  String get dataStorage => 'Data og lager';

  @override
  String get editProfileHelp => 'Indstil dit navn og din avatar';

  @override
  String get customProvider => 'Tilpasset udbyder';

  @override
  String get defaultProvider => 'PPPlayer-standard';

  @override
  String get proExperience => 'Pro-oplevelse aktiv';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Indlæser…';

  @override
  String get unknown => 'Ukendt';

  @override
  String get pause => 'Pause';

  @override
  String get repeat => 'Gentag';

  @override
  String get mute => 'Slå lyd fra';

  @override
  String get unmute => 'Slå lyd til';

  @override
  String get fitVideo => 'Tilpas';

  @override
  String get fillVideo => 'Udfyld';

  @override
  String get fullscreen => 'Fuld skærm';

  @override
  String get exitFullscreen => 'Afslut fuld skærm';

  @override
  String get volume => 'Lydstyrke';

  @override
  String get save => 'Gem';

  @override
  String get delete => 'Slet';

  @override
  String get clear => 'Ryd';

  @override
  String get follow => 'Følg';

  @override
  String get unfollow => 'Følg ikke længere';

  @override
  String get following => 'Følger';

  @override
  String get showAll => 'Vis alle';

  @override
  String get appearance => 'Udseende';

  @override
  String get subtitleSize => 'Størrelse';

  @override
  String get subtitleBackground => 'Baggrund';

  @override
  String get earlier => 'Tidligere';

  @override
  String get later => 'Senere';

  @override
  String get reset => 'Nulstil';

  @override
  String subtitleDelay(String seconds) {
    return 'Forsinkelse: $seconds s';
  }

  @override
  String get morePlaybackControls => 'Flere afspilningskontroller';

  @override
  String get hideVideo => 'Skjul video';

  @override
  String get showVideo => 'Vis video';

  @override
  String get closeQueue => 'Luk kø';

  @override
  String get enabled => 'Til';

  @override
  String get openFile => 'Åbn fil…';

  @override
  String get openFolder => 'Åbn mappe…';

  @override
  String get openUrl => 'Åbn URL…';

  @override
  String get fileMenu => 'Fil';

  @override
  String get viewMenu => 'Vis';

  @override
  String get windowMenu => 'Vindue';

  @override
  String get saveChanges => 'Gem ændringer';

  @override
  String get themeAvatarColor => 'Tema- og avatarfarve';

  @override
  String get networkStreams => 'Netværksstreams';

  @override
  String get networkStream => 'Netværksstream';

  @override
  String get openNetworkStream => 'Åbn netværksstream';

  @override
  String get editPlaylist => 'Rediger afspilningsliste';

  @override
  String get editStreamItem => 'Rediger streamelement';

  @override
  String get streamUrl => 'Stream-URL';

  @override
  String get platformType => 'Platform / type';

  @override
  String get optionalTitle => 'Titel (valgfri)';

  @override
  String get optionalImageUrl => 'Billed-URL (valgfri)';

  @override
  String get myStream => 'Min stream';

  @override
  String get saveToLibrary => 'Gem i bibliotek';

  @override
  String get justPlay => 'Afspil kun';

  @override
  String get autoDetect => 'Registrer automatisk';

  @override
  String get apiKeyRequired => 'API-nøgle kræves';

  @override
  String get customApiKey => 'Brug egen API-nøgle';

  @override
  String get clientId => 'Klient-id';

  @override
  String get clientSecret => 'Klienthemmelighed';

  @override
  String get saveCredentials => 'Gem legitimationsoplysninger';

  @override
  String get searchStrategy => 'Søgestrategi';

  @override
  String get credentialsLocalOnly =>
      'Opbevares sikkert på denne enhed. Sendes aldrig til PPPlayer.';

  @override
  String get scrapingHelp =>
      'Kræver ingen API-nøgle eller kvote. Kan være langsommere eller mindre pålidelig.';

  @override
  String get streamHelp =>
      'Indtast en HTTP(S)-URL eller et link til en M3U-afspilningsliste.';

  @override
  String get deletePlaylistConfirm => 'Slet denne afspilningsliste permanent?';

  @override
  String get clearCacheConfirm =>
      'Slet cachedata? Dit bibliotek og dine favoritter ændres ikke.';

  @override
  String get clearHistoryConfirm => 'Slet din lyttehistorik permanent?';

  @override
  String get addedToQueue => 'Føjet til kø';

  @override
  String get addedVideo => 'Video tilføjet';

  @override
  String addedChannels(String count) {
    return 'Tilføjede kanaler: $count';
  }

  @override
  String get removedFromPlaylist => 'Fjernet fra afspilningsliste';

  @override
  String get exportCancelled => 'Eksport annulleret';

  @override
  String exportComplete(String count) {
    return 'Afspilningsliste eksporteret. Sprungne elementer: $count';
  }

  @override
  String get playlistExported => 'Afspilningsliste eksporteret';

  @override
  String get live => 'Live';

  @override
  String get sponsored => 'Sponsoreret';

  @override
  String get removeFromPlaylist => 'Fjern fra afspilningsliste';

  @override
  String get likedSongsHelp => 'Gem sange for at se dem her';

  @override
  String get apiSingleVideoHint =>
      'Du kan tilføje denne video uden at importere afspilningslisten.';

  @override
  String get linkCopied => 'Link kopieret';

  @override
  String get willPlayNext => 'Afspilles som næste';

  @override
  String get checkItOut => 'Se nærmere';

  @override
  String get loadFailed => 'Indholdet kunne ikke indlæses. Prøv igen.';
}
