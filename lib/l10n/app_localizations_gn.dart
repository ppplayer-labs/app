// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Guarani (`gn`).
class AppLocalizationsGn extends AppLocalizations {
  AppLocalizationsGn([String locale = 'gn']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'ALBUMKUÉRA';

  @override
  String get api => 'API';

  @override
  String get artists => 'PURAHEIHÁRAKUÉRA';

  @override
  String get artwork => 'IMAGEN';

  @override
  String get appVersion => 'Tembiaporã versión';

  @override
  String get artist => 'Puraheihára';

  @override
  String get artistsYouFollow => 'Puraheihára rehesa\'ỹjóva';

  @override
  String get autoplay => 'Mbopu Pochy\'ỹre';

  @override
  String get becauseYouListenedTo => 'Ehendu va\'erã';

  @override
  String get browseAll => 'Ehecha Paite';

  @override
  String get cancel => 'Mbotove';

  @override
  String get clearAppCache => 'Embogue Tembiaporã Caché?';

  @override
  String get clearCache => 'Embogue Caché';

  @override
  String get clearHistory => 'Embogue Tembiasakue?';

  @override
  String get clearRecentlyPlayed => 'Embogue Oñembopu Va\'ekue';

  @override
  String get contentMarket => 'Tembiporu Ñorairõ';

  @override
  String get continueListening => 'Eheñói Ehendu Hag̃ua';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Eheñói mbopu marandupy\'a michĩva-pe';

  @override
  String get create => 'Moñepyrũ';

  @override
  String get createAPlaylistToGetStarted => 'Emoñepyrũ tysýi ñepyrũ hag̃ua';

  @override
  String currentSelectedcountry(Object country) {
    return 'Ko\'ág̃a: $country';
  }

  @override
  String get deletePlaylist => 'Mboguete Tysýi';

  @override
  String get editProfile => 'Moambue Perfil';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Javy oikuaa hag̃ua ñorairõ: $err';
  }

  @override
  String error(Object error) {
    return 'Javy: $error';
  }

  @override
  String explore(Object genre) {
    return 'Eikutu $genre';
  }

  @override
  String get fansAlsoLike => 'PURAHEIVÝVA OIPOTÁVA';

  @override
  String featuringTouppercase(Object artist) {
    return 'NDIVE $artist';
  }

  @override
  String get featuredPlaylists => 'Tysýi Ombojerapykuéva';

  @override
  String get followArtistsToSeeThemHere =>
      'Resa\'ỹjo puraheihára ehecha hag̃ua ko\'ápe';

  @override
  String get followStationsToSeeThemHere =>
      'Resa\'ỹjo emisoras ehecha hag̃ua ko\'ápe';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Mboipota audio-nte roinjévo datos monguerekohápe';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Embogue tenda ha moĩ datos pyahu oúvo';

  @override
  String get fromYourFavorites => 'Ne rembipotágui';

  @override
  String get goBack => 'Ei Tapykuépe';

  @override
  String inspiredByName(Object name) {
    return 'Inspirado $name ndive';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Eheñói mbopu pumbasy ojepaháramo tysýi';

  @override
  String get library => 'Ñemongeta';

  @override
  String get likeAlbumsToSeeThemHere => 'Eipota album ehecha hag̃ua ko\'ápe';

  @override
  String get likedSongs => 'Pumbasy Rembipota';

  @override
  String get lowDataMode => 'Datos Michĩ Modo';

  @override
  String get madeForYou => 'Ojejapo Ndéve';

  @override
  String moreLikeName(Object name) {
    return 'Oñemejãva $name';
  }

  @override
  String get moreOptions => 'Ambuéva tembiapokáva';

  @override
  String get nameYourMasterpiece => 'Eme\'ẽ réra ne mba\'e porãve...';

  @override
  String get newPlaylist => 'Tysýi Pyahu';

  @override
  String get newReleases => 'Oñemomba\'e Pyahu';

  @override
  String get next => 'Oúva';

  @override
  String get noAlbumsFound => 'Ndojejuhúi albumkuéra';

  @override
  String get noArtistsFollowed => 'Ndaipóri puraheihára rehesa\'ỹjóva';

  @override
  String get noArtistsFound => 'Ndojejuhúi puraheihára';

  @override
  String get noLikedAlbums => 'Ndaipóri album reipotáva';

  @override
  String get noPlaylistsFound => 'Ndojejuhúi tysýikuéra';

  @override
  String get noPlaylistsYet => 'Ndaipóri tysýi gueteri';

  @override
  String get noResultsFound => 'Ndojejuhúi mba\'eve';

  @override
  String get noStationsFollowed => 'Ndaipóri emisoras rehesa\'ỹjóva';

  @override
  String get noTrackPlaying => 'Ndaipóri pumbasy oñembopúva';

  @override
  String get noTracksFound => 'Ndojejuhúi pumbasykuéra';

  @override
  String get playlists => 'TYSÝIKUÉRA';

  @override
  String get popular => 'OJEPOUKAÁVA';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Mboguete mba\'eve tembiasakue ehendu va\'ekuégui';

  @override
  String get pictureinpicturePip => 'Imagen imagen-pe (PiP)';

  @override
  String get popularAlbums => 'Albumkuéra Ojepoukaáva';

  @override
  String get popularArtists => 'Puraheihárakuéra Ojepoukaáva';

  @override
  String get popularGenres => 'Géneros Ojepoukaáva';

  @override
  String get popularSongs => 'Pumbasykuéra Ojepoukaáva';

  @override
  String get popularTracks => 'Pumbasykuéra Ojepoukaáva';

  @override
  String get popularHitsRightNow => 'Hits Ojepoukaáva Ko\'ág̃a';

  @override
  String get previous => 'Tapykuégui';

  @override
  String get queue => 'TYSÝI';

  @override
  String get recentSearches => 'Ehekatéva';

  @override
  String get recommendedForYou => 'Rohechaukáva Ndéve';

  @override
  String get scraping => 'Oñembyaty Datos';

  @override
  String get search => 'Eheka';

  @override
  String get searchInAlbum => 'Eheka albumpe...';

  @override
  String get searchInLibrary => 'Eheka ñemongeta-pe...';

  @override
  String get searchInPlaylist => 'Eheka tysýipe';

  @override
  String get searchLikedSongs => 'Eheka pumbasy reipotáva...';

  @override
  String get searchPopularSongs => 'Eheka pumbasykuéra ojepoukaáva...';

  @override
  String get selectMarket => 'Eiporavo Ñorairõ';

  @override
  String get settings => 'Tembiporu';

  @override
  String get showVideoPlayer => 'Ehecha Marandupy\'a';

  @override
  String get shuffle => 'Ñemoheñói';

  @override
  String get spotifyCredentials => 'Spotify Credenciales';

  @override
  String get suggestedStations => 'Emisoras Rojapurahéiva';

  @override
  String get tracks => 'PUMBASYKUÉRA';

  @override
  String get trending => 'Ojepoukaáva';

  @override
  String get tryAgain => 'Ejejapo Jey';

  @override
  String get tryADifferentSearchTerm => 'Eikotevẽ ambuéva reheka hag̃ua';

  @override
  String get useYoutubePlayerWhenAvailable => 'Eiporu YouTube Player oĩramo';

  @override
  String get video => 'Ta\'ãngamýi';

  @override
  String get whatDoYouWantToListenTo => 'Mba\'étapa rehendu potáva?';

  @override
  String get youtubeCredentials => 'YouTube Credenciales';

  @override
  String get yourLibrary => 'Ne Ñemongeta';

  @override
  String get playerscreenviewswitch => 'moambue_hecha_mba_e_ryru';

  @override
  String get addToPlaylist => 'Moĩ Tysýipe';

  @override
  String get addToQueue => 'Moĩ Tysýipe Espera';

  @override
  String get copyId => 'Kopia ID';

  @override
  String get copyLink => 'Kopia Ñandutiresẽ';

  @override
  String get discover => 'Ejuhu';

  @override
  String get enterYourName => 'Emoinge nde réra';

  @override
  String get favorites => 'Ne Rembipota';

  @override
  String get goToAlbum => 'E\'u albumpe';

  @override
  String get goToArtist => 'E\'u puraheihárape';

  @override
  String get goToArtistRadio => 'E\'u puraheihára radiope';

  @override
  String get goToPlaylist => 'E\'u tysýipe';

  @override
  String get goToSongRadio => 'E\'u pumbasy radiope';

  @override
  String get home => 'Óga';

  @override
  String get myAwesomePlaylist => 'Che Tysýi Porã';

  @override
  String get myPlaylist => 'Che Tysýi';

  @override
  String get newPlaylist1 => 'Tysýi Pyahu';

  @override
  String get play => 'Mbopu';

  @override
  String get playStation => 'Mbopu Emisora';

  @override
  String get playNext => 'Mbopu Oúva';

  @override
  String get playlist => 'Playlist';

  @override
  String get playlistName => 'Réra Tysýi';

  @override
  String get playlists1 => 'Tysýikuéra';

  @override
  String get queue1 => 'Tysýi';

  @override
  String get recentlyPlayed => 'Oñembopu Va\'ekue';

  @override
  String get removeFromQueue => 'Mboguete Tysýigui';

  @override
  String get retry => 'Ejejapo Jey';

  @override
  String get searchMusicArtistsAlbums =>
      'Eheka pumbasy, puraheihára, albumkuéra...';

  @override
  String get share => 'Mombe\'u';

  @override
  String featuringArtist(String artistName) {
    return 'NDIVE $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Ko\'ág̃a: $country';
  }

  @override
  String get queueTooltip => 'Tysýi';

  @override
  String get searchHint => 'Eheka pumbasy, puraheihára, albumkuéra...';

  @override
  String get language => 'Ñe\'ẽ';

  @override
  String get systemDefault => 'Sistema Régagua';

  @override
  String get songsTab => 'Purahéi';

  @override
  String get foldersTab => 'Mba\'eryru';

  @override
  String get artistsTab => 'Puraheihára';

  @override
  String get albumsTab => 'Aty';

  @override
  String get genresTab => 'Mba\'epu rerekua';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Pya\'e';

  @override
  String get addMusic => 'Mbojuaju purahéi';

  @override
  String get addFiles => 'Mbojuaju marandukuéra';

  @override
  String get addFolder => 'Mbojuaju mba\'eryru';

  @override
  String get rescanLibrary => 'Heka jey purahéi';

  @override
  String get sortTitle => 'Oñemohenda héra rupi';

  @override
  String get sortArtist => 'Oñemohenda puraheihára rupi';

  @override
  String get sortAlbum => 'Oñemohenda aty rupi';

  @override
  String get sortDuration => 'Oñemohenda pukukue rupi';

  @override
  String get sortDateAdded => 'Oñemohenda ára rupi';

  @override
  String get sortBy => 'Mohenda';

  @override
  String get trackInformation => 'Purahéi marandu';

  @override
  String get removeFromLibrary => 'Nohẽ purahéi atýgui';

  @override
  String get showInFolder => 'Hechauka mba\'eryrúpe';

  @override
  String get unknownArtist => 'Puraheihára ojekuaa\'ỹva';

  @override
  String get unknownAlbum => 'Aty ojekuaa\'ỹva';

  @override
  String get importedFiles => 'Marandukuéra oñemoguahẽva';

  @override
  String get playFolder => 'Mbohyapu mba\'eryru';

  @override
  String get shuffleFolder => 'Mbohyapu sarambi mba\'eryru';

  @override
  String get playAll => 'Mbohyapu paite';

  @override
  String get includeSubfolders => 'Mbojuaju mba\'eryru\'i';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count purahéi',
      one: '1 purahéi',
      zero: '0 purahéi',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Ndojejuhúi purahéi ko\'ápe';

  @override
  String get searchLocalMusic => 'Heka purahéi ko\'ápe...';

  @override
  String get viewAsList => 'Hechauka tysýi ramo';

  @override
  String get viewAsGrid => 'Hechauka ñanduti ramo';

  @override
  String get trackInfoPath => 'Tape';

  @override
  String get trackInfoFormat => 'Formato';

  @override
  String get trackInfoDuration => 'Pukukue';

  @override
  String get aboutDescription => 'Mba\'epu rerekua ojekuaáva ha ndojepagáiva.';

  @override
  String get aboutApp => 'PPPlayer rehegua';

  @override
  String get appTagline => 'Nde purahéi. Nde reko.';

  @override
  String get exploreApp => 'Kuaa PPPlayer';

  @override
  String get viewSource => 'Hechauka rapo';

  @override
  String get seeWhatsNew => 'Ehecha mba\'e pyahu';

  @override
  String get getHelp => 'Jerure pytyvõ';

  @override
  String versionInfo(Object version, Object build) {
    return 'Mba\'e $version (Apopy $build)';
  }

  @override
  String get createdBy => 'Lucas Coelho rembiapokue';

  @override
  String get website => 'Ñanduti tenda';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Jekuaaukapy';

  @override
  String get support => 'Pytyvõ';

  @override
  String get license => 'Moneĩmby';

  @override
  String get acknowledgments => 'Aguyje';

  @override
  String get close => 'Mboty';

  @override
  String copyright(Object year) {
    return '© $year PPPlayer pytyvõhára';
  }

  @override
  String get goodMorning => 'Mba\'éichapa pyhareve';

  @override
  String get goodAfternoon => 'Mba\'éichapa ka\'aru';

  @override
  String get goodEvening => 'Mba\'éichapa pyhare';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Ne purahéi nde ra\'arõ.';

  @override
  String dailyMix(Object number) {
    return 'Mix ára ha ára $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'Ne mba\'e eipotavéva\nha pyahu rejuhúva';

  @override
  String get discoverWeekly => 'Téma pyahu arapokõindýpe';

  @override
  String get releaseRadar => 'Purahéi pyahu';

  @override
  String get newMusicJustForYou => 'Purahéi pyahu\nndéve g̃uarãnte';

  @override
  String get chillMix => 'Chill Mix';

  @override
  String get relaxAndUnwind => 'Epytu\'u ha eñembopiro\'y';

  @override
  String get focusMix => 'Focus Mix';

  @override
  String get deepFocusAndProductivity => 'Eñatende porã\nha ejapo heta mba\'e';

  @override
  String artistRadio(Object artist) {
    return '$artist Puhoe';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre Puhoe';
  }

  @override
  String get filterAll => 'Opaite';

  @override
  String get filterPlaylists => 'Tysýi';

  @override
  String get filterArtists => 'Mba\'epuapohára';

  @override
  String get filterAlbums => 'Mba\'epu\'aty';

  @override
  String get filterStations => 'Ñe\'ẽasãiha';

  @override
  String get filterStreams => 'Mboguata';

  @override
  String get localMusicCard => 'Mba\'epu ñande mba\'e';

  @override
  String get createPlaylistButton => 'Apo tysýi';

  @override
  String get radioStations => 'Ñe\'ẽasãiha';

  @override
  String get discoverMusic => 'Juhu mba\'epu';

  @override
  String get importLocalMusic => 'Gueru mba\'epu';

  @override
  String get importAudioFiles => 'Gueru ñe\'ẽryru';

  @override
  String get importFolder => 'Gueru ñongatuha';

  @override
  String get importFolderSubtitle =>
      'Eiporavo peteĩ ñongatupy oguerekóva ñe\'ẽ';

  @override
  String get importPlaylist => 'Gueru playlist';

  @override
  String get importPlaylistSubtitle => 'Gueru .m3u térã .m3u8';

  @override
  String get exportPlaylist => 'Guenohẽ playlist';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Ndikatúi oñembohasa térã oñembyai';

  @override
  String get playbackErrorFileInaccessible => 'Ndikatúi ojejuhu';

  @override
  String get localVideosCard => 'Ta\'ãngamýi ko\'ápe';

  @override
  String get noLocalVideos => 'Ndojejuhúi ta\'ãngamýi';

  @override
  String get searchLocalVideos => 'Heka ta\'ãngamýi';

  @override
  String get addVideos => 'Moĩve ta\'ãngamýi';

  @override
  String get subtitles => 'Jehaí';

  @override
  String get audioTracks => 'Ñe\'ẽ';

  @override
  String get loadSubtitleFile => 'Gueru jehai...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Ojejavy ojehupi hagua subtitle: $error';
  }

  @override
  String get off => 'Mboty';

  @override
  String get playOn => 'Emboja ipype';

  @override
  String get thisDevice => 'Ko tembiporu';

  @override
  String get availableDevices => 'Tembiporu ojepurukuaáva';

  @override
  String get searchingDevices => 'Ojeheka tembiporu…';

  @override
  String get refresh => 'Embopyahu';

  @override
  String get connecting => 'Oñembojoaju…';

  @override
  String connectingTo(String name) {
    return 'Oñembojoaju $name ndive…';
  }

  @override
  String get connected => 'Oñembojoajuma';

  @override
  String get unsupportedOutput => 'Ko ypykue ndaikatúi oñemboja ko ñesẽme.';

  @override
  String get airPlayAudioOutput => 'AirPlay ha ñe’ẽpu ñesẽ';

  @override
  String get returnForAirPlay => 'Emboja ko tembiporúpe eipuru hag̃ua AirPlay.';

  @override
  String get openSoundSettings =>
      'Eipe’a ñe’ẽpu ñemboheko eiporavo hag̃ua ñesẽ.';

  @override
  String get soundSettingsError => 'Ndaikatúi ojepe’a ñe’ẽpu ñemboheko.';

  @override
  String get systemOutput => 'Sistema ñesẽ';

  @override
  String playingOn(String name) {
    return 'Oñemboja $name pe';
  }

  @override
  String get chooseAirPlay =>
      'Epoko AirPlay votõre eiporavo hag̃ua ñe’ẽpuha térã televisor.';

  @override
  String get airPlayDevice => 'AirPlay tembiporu';

  @override
  String get playOnIphone => 'Emboja ko iPhone-pe';

  @override
  String get chooseIphone => 'Eiporavo ko iPhone AirPlay votõ yvygua rupive.';

  @override
  String get profile => 'Mba’ete';

  @override
  String get preferences => 'Jeporavopyre';

  @override
  String get themeColor => 'Tema sa’y';

  @override
  String get yourMusic => 'Ne purahéi';

  @override
  String get apiCredentials => 'API jeike rehegua';

  @override
  String get dataStorage => 'Marandu ha ñongatuha';

  @override
  String get editProfileHelp => 'Emohenda nde réra ha nde ra’anga';

  @override
  String get customProvider => 'Me’ẽha nde reiporavóva';

  @override
  String get defaultProvider => 'PPPlayer ñepyrũgua';

  @override
  String get proExperience => 'Pro jeporu oñemyendy';

  @override
  String get beta => 'Beta rehegua';

  @override
  String get loading => 'Oñembohysýi…';

  @override
  String get unknown => 'Ojekuaa’ỹva';

  @override
  String get pause => 'Epytu’u';

  @override
  String get repeat => 'Ejapo jey';

  @override
  String get mute => 'Emokirirĩ';

  @override
  String get unmute => 'Emyendy ñe’ẽpu';

  @override
  String get fitVideo => 'Emohenda';

  @override
  String get fillVideo => 'Emyenyhẽ';

  @override
  String get fullscreen => 'Tendyha tuichakue';

  @override
  String get exitFullscreen => 'Esẽ tendyha tuichakuégui';

  @override
  String get volume => 'Ñe’ẽpu hatãkue';

  @override
  String get save => 'Eñongatu';

  @override
  String get delete => 'Embogue';

  @override
  String get clear => 'Emopotĩ';

  @override
  String get follow => 'Esegui';

  @override
  String get unfollow => 'Anive esegui';

  @override
  String get following => 'Ojesegui';

  @override
  String get showAll => 'Ehechauka opaite';

  @override
  String get appearance => 'Hechapy';

  @override
  String get subtitleSize => 'Tuichakue';

  @override
  String get subtitleBackground => 'Tugua';

  @override
  String get earlier => 'Mboyve';

  @override
  String get later => 'Upe rire';

  @override
  String get reset => 'Emoñepyrũ jey';

  @override
  String subtitleDelay(String seconds) {
    return 'Ñembotapykue: $seconds aravo’ive';
  }

  @override
  String get morePlaybackControls => 'Ñemboja ñangarekoha ambue';

  @override
  String get hideVideo => 'Emokañy ta’ãngamýi';

  @override
  String get showVideo => 'Ehechauka ta’ãngamýi';

  @override
  String get closeQueue => 'Emboty tysýi';

  @override
  String get enabled => 'Hendy';

  @override
  String get openFile => 'Eipe’a marandurenda…';

  @override
  String get openFolder => 'Eipe’a ryru…';

  @override
  String get openUrl => 'Eipe’a URL…';

  @override
  String get fileMenu => 'Marandurenda';

  @override
  String get viewMenu => 'Hecha';

  @override
  String get windowMenu => 'Ovetã';

  @override
  String get saveChanges => 'Eñongatu ñemoambue';

  @override
  String get themeAvatarColor => 'Tema ha nde ra’anga sa’y';

  @override
  String get networkStreams => 'Ñanduti ñembohasapy';

  @override
  String get networkStream => 'Ñanduti ñembohasapy';

  @override
  String get openNetworkStream => 'Eipe’a ñanduti ñembohasapy';

  @override
  String get editPlaylist => 'Emoambue purahéi tysýi';

  @override
  String get editStreamItem => 'Emoambue ñembohasapy mba’e';

  @override
  String get streamUrl => 'Ñembohasapy URL';

  @override
  String get platformType => 'Ñemohenda / mba’eichagua';

  @override
  String get optionalTitle => 'Téra (natekotevẽi)';

  @override
  String get optionalImageUrl => 'Ta’ãnga URL (natekotevẽi)';

  @override
  String get myStream => 'Che ñembohasapy';

  @override
  String get saveToLibrary => 'Eñongatu arandukaty rendápe';

  @override
  String get justPlay => 'Emboja añónte';

  @override
  String get autoDetect => 'Jehechakuaa ijehegui';

  @override
  String get apiKeyRequired => 'Oñeikotevẽ API ñemigua';

  @override
  String get customApiKey => 'Eipuru nde API ñemigua';

  @override
  String get clientId => 'Puruhára ID';

  @override
  String get clientSecret => 'Puruhára ñemigua';

  @override
  String get saveCredentials => 'Eñongatu jeike rehegua';

  @override
  String get searchStrategy => 'Jeheka rape';

  @override
  String get credentialsLocalOnly =>
      'Oñongatu porã ko tembiporúpe. Araka’eve noñemondói PPPlayer-pe.';

  @override
  String get scrapingHelp =>
      'Natekotevẽi API ñemigua térã cuota. Ikatu imbeguéve térã ndoiko porãi.';

  @override
  String get streamHelp => 'Emoinge HTTP(S) URL térã M3U tysýi joajuha.';

  @override
  String get deletePlaylistConfirm => 'Emboguete ko purahéi tysýi?';

  @override
  String get clearCacheConfirm =>
      'Embogue marandu sapy’agua? Arandukaty ha umi nde rehayhúva noñemoambuéi.';

  @override
  String get clearHistoryConfirm => 'Emboguete ne rembiendu rembiasakue?';

  @override
  String get addedToQueue => 'Oñemoĩ tysýipe';

  @override
  String get addedVideo => 'Oñemoĩ ta’ãngamýi';

  @override
  String addedChannels(String count) {
    return 'Canal oñemoĩva: $count';
  }

  @override
  String get removedFromPlaylist => 'Ojepe’a purahéi tysýigui';

  @override
  String get exportCancelled => 'Ñeguenohẽ oñemboyke';

  @override
  String exportComplete(String count) {
    return 'Tysýi oñeguenohẽ. Mba’e ojehasáva: $count';
  }

  @override
  String get playlistExported => 'Tysýi oñeguenohẽ';

  @override
  String get live => 'Ñembohasa ko’ág̃a';

  @override
  String get sponsored => 'Oñepytyvõva';

  @override
  String get removeFromPlaylist => 'Eipe’a tysýigui';

  @override
  String get likedSongsHelp => 'Eñongatu purahéi rehecha hag̃ua ko’ápe';

  @override
  String get apiSingleVideoHint =>
      'Ikatu remoĩ ko ta’ãngamýi regueru’ỹre purahéi tysýi.';

  @override
  String get linkCopied => 'Joajuha ojekopia';

  @override
  String get willPlayNext => 'Oñembojáta upe rire';

  @override
  String get checkItOut => 'Ehecha';

  @override
  String get loadFailed => 'Ndaikatúi ojehechauka ipypegua. Eñeha\'ã jey.';
}
