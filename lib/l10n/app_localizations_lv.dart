// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'ALBUMI';

  @override
  String get api => 'API';

  @override
  String get artists => 'MĀKSLINIEKI';

  @override
  String get artwork => 'VĀKS';

  @override
  String get appVersion => 'Lietotnes versija';

  @override
  String get artist => 'Mākslinieks';

  @override
  String get artistsYouFollow => 'Mākslinieki, kurus sekojat';

  @override
  String get autoplay => 'Automātiskā atskaņošana';

  @override
  String get becauseYouListenedTo => 'Tāpēc, ka jūs klausījāties';

  @override
  String get browseAll => 'Skatīt visu';

  @override
  String get cancel => 'Atcelt';

  @override
  String get clearAppCache => 'Notīrīt lietotnes kešatmiņu?';

  @override
  String get clearCache => 'Notīrīt kešatmiņu';

  @override
  String get clearHistory => 'Notīrīt vēsturi?';

  @override
  String get clearRecentlyPlayed => 'Notīrīt nesen atskaņotos';

  @override
  String get contentMarket => 'Satura tirgus';

  @override
  String get continueListening => 'Turpināt klausīties';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Turpināt video atskaņošanu mazā logā';

  @override
  String get create => 'Izveidot';

  @override
  String get createAPlaylistToGetStarted =>
      'Izveidojiet atskaņošanas sarakstu, lai sāktu';

  @override
  String currentSelectedcountry(Object country) {
    return 'Pašreizējā: $country';
  }

  @override
  String get deletePlaylist => 'Dzēst atskaņošanas sarakstu';

  @override
  String get editProfile => 'Rediģēt profilu';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Kļūda ielādējot tirgus: $err';
  }

  @override
  String error(Object error) {
    return 'Kļūda: $error';
  }

  @override
  String explore(Object genre) {
    return 'Izpētīt $genre';
  }

  @override
  String get fansAlsoLike => 'FANIEM PATĪK ARĪ';

  @override
  String featuringTouppercase(Object artist) {
    return 'PIEDALĀS $artist';
  }

  @override
  String get featuredPlaylists => 'Ieteiktie atskaņošanas saraksti';

  @override
  String get followArtistsToSeeThemHere =>
      'Sekojiet māksliniekiem, lai redzētu tos šeit';

  @override
  String get followStationsToSeeThemHere =>
      'Sekojiet stacijām, lai redzētu tās šeit';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Piespiest tikai audio straumēšanu, lai taupītu datus';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Atbrīvo vietu un piespiež jaunus datus nākamajā ielādē';

  @override
  String get fromYourFavorites => 'No jūsu favorītiem';

  @override
  String get goBack => 'Atpakaļ';

  @override
  String inspiredByName(Object name) {
    return 'Iedvesmojies no $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Turpināt atskaņot līdzīgus ierakstus, kad rinda beidzas';

  @override
  String get library => 'Bibliotēka';

  @override
  String get likeAlbumsToSeeThemHere => 'Patīk albumi, lai redzētu tos šeit';

  @override
  String get likedSongs => 'Iecienītās dziesmas';

  @override
  String get lowDataMode => 'Zema datu režīms';

  @override
  String get madeForYou => 'Izveidots tev';

  @override
  String moreLikeName(Object name) {
    return 'Vairāk kā $name';
  }

  @override
  String get moreOptions => 'Vairāk iespēju';

  @override
  String get nameYourMasterpiece => 'Nosauciet savu šedevru...';

  @override
  String get newPlaylist => 'Jauns atskaņošanas saraksts';

  @override
  String get newReleases => 'Jaunākās izdošanas';

  @override
  String get next => 'Nākamais';

  @override
  String get noAlbumsFound => 'Nav atrasts neviens albums';

  @override
  String get noArtistsFollowed => 'Nav sekotu mākslinieku';

  @override
  String get noArtistsFound => 'Nav atrasts neviens mākslinieks';

  @override
  String get noLikedAlbums => 'Nav iecienītu albumu';

  @override
  String get noPlaylistsFound => 'Nav atrasti atskaņošanas saraksti';

  @override
  String get noPlaylistsYet => 'Vēl nav atskaņošanas sarakstu';

  @override
  String get noResultsFound => 'Nav atrasti rezultāti';

  @override
  String get noStationsFollowed => 'Nav sekotu staciju';

  @override
  String get noTrackPlaying => 'Netiek atskaņots neviens ieraksts';

  @override
  String get noTracksFound => 'Nav atrasti ieraksti';

  @override
  String get playlists => 'ATSKAŅOŠANAS SARAKSTI';

  @override
  String get popular => 'POPULĀRS';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Neatgriezeniski noņemt klausīšanās vēsturi';

  @override
  String get pictureinpicturePip => 'Attēls attēlā (PiP)';

  @override
  String get popularAlbums => 'Populāri albumi';

  @override
  String get popularArtists => 'Populāri mākslinieki';

  @override
  String get popularGenres => 'Populāri žanri';

  @override
  String get popularSongs => 'Populāras dziesmas';

  @override
  String get popularTracks => 'Populāri ieraksti';

  @override
  String get popularHitsRightNow => 'Populārie hiti šobrīd';

  @override
  String get previous => 'Iepriekšējais';

  @override
  String get queue => 'RINDA';

  @override
  String get recentSearches => 'Pēdējie meklējumi';

  @override
  String get recommendedForYou => 'Ieteikts tev';

  @override
  String get scraping => 'Iegūst datus';

  @override
  String get search => 'Meklēt';

  @override
  String get searchInAlbum => 'Meklēt albumā...';

  @override
  String get searchInLibrary => 'Meklēt bibliotēkā...';

  @override
  String get searchInPlaylist => 'Meklēt atskaņošanas sarakstā';

  @override
  String get searchLikedSongs => 'Meklēt iecienītās dziesmas...';

  @override
  String get searchPopularSongs => 'Meklēt populāras dziesmas...';

  @override
  String get selectMarket => 'Atlasīt tirgu';

  @override
  String get settings => 'Iestatījumi';

  @override
  String get showVideoPlayer => 'Rādīt video atskaņotāju';

  @override
  String get shuffle => 'Jaukt';

  @override
  String get spotifyCredentials => 'Spotify akreditācijas dati';

  @override
  String get suggestedStations => 'Ieteiktās stacijas';

  @override
  String get tracks => 'IERAKSTI';

  @override
  String get trending => 'Populārs';

  @override
  String get tryAgain => 'Mēģināt vēlreiz';

  @override
  String get tryADifferentSearchTerm => 'Mēģiniet citu meklēšanas terminu';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Izmantot YouTube atskaņotāju, ja pieejams';

  @override
  String get video => 'VIDEO';

  @override
  String get whatDoYouWantToListenTo => 'Ko vēlaties klausīties?';

  @override
  String get youtubeCredentials => 'YouTube akreditācijas dati';

  @override
  String get yourLibrary => 'Jūsu bibliotēka';

  @override
  String get playerscreenviewswitch => 'speletaja_ekrana_skata_sledzis';

  @override
  String get addToPlaylist => 'Pievienot atskaņošanas sarakstam';

  @override
  String get addToQueue => 'Pievienot rindai';

  @override
  String get copyId => 'Kopēt ID';

  @override
  String get copyLink => 'Kopēt saiti';

  @override
  String get discover => 'Atklāt';

  @override
  String get enterYourName => 'Ievadiet savu vārdu';

  @override
  String get favorites => 'Favorīti';

  @override
  String get goToAlbum => 'Doties uz albumu';

  @override
  String get goToArtist => 'Doties uz mākslinieku';

  @override
  String get goToArtistRadio => 'Doties uz mākslinieka radio';

  @override
  String get goToPlaylist => 'Doties uz atskaņošanas sarakstu';

  @override
  String get goToSongRadio => 'Doties uz dziesmas radio';

  @override
  String get home => 'Sākums';

  @override
  String get myAwesomePlaylist => 'Mans lieliskais atskaņošanas saraksts';

  @override
  String get myPlaylist => 'Mans atskaņošanas saraksts';

  @override
  String get newPlaylist1 => 'Jauns atskaņošanas saraksts';

  @override
  String get play => 'Atskaņot';

  @override
  String get playStation => 'Atskaņot staciju';

  @override
  String get playNext => 'Atskaņot nākamo';

  @override
  String get playlist => 'Atskaņošanas saraksts';

  @override
  String get playlistName => 'Atskaņošanas saraksta nosaukums';

  @override
  String get playlists1 => 'Atskaņošanas saraksti';

  @override
  String get queue1 => 'Rinda';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueUpNext => 'Up next';

  @override
  String get recentlyPlayed => 'Nesen atskaņotie';

  @override
  String get removeFromQueue => 'Noņemt no rindas';

  @override
  String get retry => 'Mēģināt vēlreiz';

  @override
  String get searchMusicArtistsAlbums =>
      'Meklēt mūziku, māksliniekus, albumus...';

  @override
  String get share => 'Kopīgot';

  @override
  String featuringArtist(String artistName) {
    return 'PIEDALĀS $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Pašreizējā: $country';
  }

  @override
  String get queueTooltip => 'Rinda';

  @override
  String get searchHint => 'Meklēt mūziku, māksliniekus, albumus...';

  @override
  String get language => 'Valoda';

  @override
  String get systemDefault => 'Sistēmas noklusējums';

  @override
  String get songsTab => 'Dziesmas';

  @override
  String get foldersTab => 'Mapes';

  @override
  String get artistsTab => 'Mākslinieki';

  @override
  String get albumsTab => 'Albumi';

  @override
  String get genresTab => 'Žanri';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Atskaņošanas ātrums';

  @override
  String get addMusic => 'Pievienot mūziku';

  @override
  String get addFiles => 'Pievienot failus';

  @override
  String get addFolder => 'Pievienot mapi';

  @override
  String get rescanLibrary => 'Atkārtoti skenēt bibliotēku';

  @override
  String get sortTitle => 'Kārtot pēc nosaukuma';

  @override
  String get sortArtist => 'Kārtot pēc mākslinieka';

  @override
  String get sortAlbum => 'Kārtot pēc albuma';

  @override
  String get sortDuration => 'Kārtot pēc ilguma';

  @override
  String get sortDateAdded => 'Kārtot pēc pievienošanas datuma';

  @override
  String get sortBy => 'Kārtot pēc';

  @override
  String get trackInformation => 'Sliežu ceļa informācija';

  @override
  String get removeFromLibrary => 'Noņemt no bibliotēkas';

  @override
  String get showInFolder => 'Rādīt mapē';

  @override
  String get unknownArtist => 'Nezināms mākslinieks';

  @override
  String get unknownAlbum => 'Nezināms albums';

  @override
  String get importedFiles => 'Importētie faili';

  @override
  String get playFolder => 'Atskaņot mapi';

  @override
  String get shuffleFolder => 'Jaukt mapi';

  @override
  String get playAll => 'Atskaņot visu';

  @override
  String get includeSubfolders => 'Iekļaut apakšmapes';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count celiņi',
      one: '1 celiņš',
      zero: '0 celiņi',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Vietējās dziesmas nav atrastas';

  @override
  String get searchLocalMusic => 'Meklēt vietējo mūziku...';

  @override
  String get viewAsList => 'Skatīt kā sarakstu';

  @override
  String get viewAsGrid => 'Skatīt kā režģi';

  @override
  String get trackInfoPath => 'Ceļš';

  @override
  String get trackInfoFormat => 'Formāts';

  @override
  String get trackInfoDuration => 'Ilgums';

  @override
  String get aboutDescription =>
      'Bezmaksas atvērtā pirmkoda multivides atskaņotājs.';

  @override
  String get aboutApp => 'Par PPPlayer';

  @override
  String get appTagline => 'Tava mūzika. Tavā veidā.';

  @override
  String get exploreApp => 'Izpētīt PPPlayer';

  @override
  String get viewSource => 'Skatīt avotu';

  @override
  String get seeWhatsNew => 'Kas jauns';

  @override
  String get getHelp => 'Saņemt palīdzību';

  @override
  String versionInfo(Object version, Object build) {
    return 'Versija $version (Būvējums $build)';
  }

  @override
  String get createdBy => 'Izveidoja Lucas Coelho';

  @override
  String get website => 'Tīmekļa vietne';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Laidiena piezīmes';

  @override
  String get support => 'Atbalsts';

  @override
  String get license => 'Licence';

  @override
  String get acknowledgments => 'Pateicības';

  @override
  String get close => 'Aizvērt';

  @override
  String copyright(Object year) {
    return '© $year PPPlayer atbalstītāji';
  }

  @override
  String get goodMorning => 'Labrīt';

  @override
  String get goodAfternoon => 'Labdien';

  @override
  String get goodEvening => 'Labvakar';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Tava mūzika gaida.';

  @override
  String dailyMix(Object number) {
    return 'Dienas mikss $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'Tavi iecienītākie\nun jauni atklājumi';

  @override
  String get discoverWeekly => 'Nedēļas atklājumi';

  @override
  String get releaseRadar => 'Jaunumu radars';

  @override
  String get newMusicJustForYou => 'Jauna mūzika\ntikai tev';

  @override
  String get chillMix => 'Mierīgais mikss';

  @override
  String get relaxAndUnwind => 'Atpūties un relaksējies';

  @override
  String get focusMix => 'Fokusa mikss';

  @override
  String get deepFocusAndProductivity => 'Dziļš fokuss\nun produktivitāte';

  @override
  String artistRadio(Object artist) {
    return '$artist Radio';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre Radio';
  }

  @override
  String get filterAll => 'Viss';

  @override
  String get filterPlaylists => 'Atskaņošanas saraksti';

  @override
  String get filterArtists => 'Mākslinieki';

  @override
  String get filterAlbums => 'Albumi';

  @override
  String get filterStations => 'Stacijas';

  @override
  String get filterStreams => 'Straumējumi';

  @override
  String get localMusicCard => 'Vietējā mūzika';

  @override
  String get createPlaylistButton => 'Izveidot atskaņošanas sarakstu';

  @override
  String get radioStations => 'Radiostacijas';

  @override
  String get discoverMusic => 'Atklāt mūziku';

  @override
  String get importLocalMusic => 'Importēt vietējo mūziku';

  @override
  String get importAudioFiles => 'Importēt audio failus';

  @override
  String get importFolder => 'Importēt mapi';

  @override
  String get importFolderSubtitle => 'Izvēlieties mapi, kurā ir audio faili';

  @override
  String get importPlaylist => 'Importēt atskaņošanas sarakstu';

  @override
  String get importPlaylistSubtitle => 'Importēt .m3u vai .m3u8 failu';

  @override
  String get exportPlaylist => 'Eksportēt atskaņošanas sarakstu';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Neatbalstīts formāts vai bojāts fails';

  @override
  String get playbackErrorFileInaccessible =>
      'Fails nav pieejams vai nav atrasts';

  @override
  String get localVideosCard => 'Lokālie videoklipi';

  @override
  String get noLocalVideos => 'Videoklipi nav atrast';

  @override
  String get searchLocalVideos => 'Meklēt lokālos videoklipus';

  @override
  String get addVideos => 'Pievienot videoklipus';

  @override
  String get subtitles => 'Subtitri';

  @override
  String get audioTracks => 'Audio celiņi';

  @override
  String get loadSubtitleFile => 'Ielādēt subtitru failu...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Kļūda, ielādējot subtitrus: $error';
  }

  @override
  String get off => 'Izslēgts';

  @override
  String get playOn => 'Atskaņot ierīcē';

  @override
  String get thisDevice => 'Šī ierīce';

  @override
  String get availableDevices => 'Pieejamās ierīces';

  @override
  String get searchingDevices => 'Meklē ierīces…';

  @override
  String get refresh => 'Atsvaidzināt';

  @override
  String get connecting => 'Savieno…';

  @override
  String connectingTo(String name) {
    return 'Savieno ar $name…';
  }

  @override
  String get connected => 'Savienots';

  @override
  String get unsupportedOutput => 'Šo avotu nevar atskaņot šajā izvadē.';

  @override
  String get airPlayAudioOutput => 'AirPlay un audio izvade';

  @override
  String get returnForAirPlay =>
      'Lai izmantotu AirPlay, atskaņojiet šajā ierīcē.';

  @override
  String get openSoundSettings =>
      'Atveriet skaņas iestatījumus, lai izvēlētos izvadi.';

  @override
  String get soundSettingsError => 'Neizdevās atvērt skaņas iestatījumus.';

  @override
  String get systemOutput => 'Sistēmas izvade';

  @override
  String playingOn(String name) {
    return 'Atskaņo ierīcē $name';
  }

  @override
  String get chooseAirPlay =>
      'Pieskarieties AirPlay pogai, lai izvēlētos skaļruni vai televizoru.';

  @override
  String get airPlayDevice => 'AirPlay ierīce';

  @override
  String get playOnIphone => 'Atskaņot šajā iPhone';

  @override
  String get chooseIphone =>
      'Izvēlieties šo iPhone ar tālāk esošo AirPlay pogu.';

  @override
  String get profile => 'Profils';

  @override
  String get preferences => 'Preferences';

  @override
  String get themeColor => 'Motīva krāsa';

  @override
  String get yourMusic => 'Jūsu mūzika';

  @override
  String get apiCredentials => 'API piekļuves dati';

  @override
  String get dataStorage => 'Dati un krātuve';

  @override
  String get editProfileHelp => 'Iestatiet vārdu un avatāru';

  @override
  String get customProvider => 'Pielāgots pakalpojuma sniedzējs';

  @override
  String get defaultProvider => 'PPPlayer noklusējums';

  @override
  String get proExperience => 'Pro iespējas aktīvas';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Ielādē…';

  @override
  String get unknown => 'Nezināms';

  @override
  String get pause => 'Pauze';

  @override
  String get repeat => 'Atkārtot';

  @override
  String get mute => 'Izslēgt skaņu';

  @override
  String get unmute => 'Ieslēgt skaņu';

  @override
  String get fitVideo => 'Ietilpināt';

  @override
  String get fillVideo => 'Aizpildīt';

  @override
  String get fullscreen => 'Pilnekrāns';

  @override
  String get exitFullscreen => 'Iziet no pilnekrāna';

  @override
  String get volume => 'Skaļums';

  @override
  String get save => 'Saglabāt';

  @override
  String get delete => 'Dzēst';

  @override
  String get clear => 'Notīrīt';

  @override
  String get follow => 'Sekot';

  @override
  String get unfollow => 'Pārtraukt sekot';

  @override
  String get following => 'Sekojat';

  @override
  String get showAll => 'Rādīt visu';

  @override
  String get appearance => 'Izskats';

  @override
  String get subtitleSize => 'Izmērs';

  @override
  String get subtitleBackground => 'Fons';

  @override
  String get earlier => 'Agrāk';

  @override
  String get later => 'Vēlāk';

  @override
  String get reset => 'Atiestatīt';

  @override
  String subtitleDelay(String seconds) {
    return 'Aizkave: $seconds s';
  }

  @override
  String get morePlaybackControls => 'Vairāk atskaņošanas vadīklu';

  @override
  String get hideVideo => 'Paslēpt video';

  @override
  String get showVideo => 'Rādīt video';

  @override
  String get closeQueue => 'Aizvērt rindu';

  @override
  String get enabled => 'Ieslēgts';

  @override
  String get openFile => 'Atvērt failu…';

  @override
  String get openFolder => 'Atvērt mapi…';

  @override
  String get openUrl => 'Atvērt URL…';

  @override
  String get fileMenu => 'Fails';

  @override
  String get viewMenu => 'Skats';

  @override
  String get windowMenu => 'Logs';

  @override
  String get saveChanges => 'Saglabāt izmaiņas';

  @override
  String get themeAvatarColor => 'Motīva un avatāra krāsa';

  @override
  String get networkStreams => 'Tīkla straumes';

  @override
  String get networkStream => 'Tīkla straume';

  @override
  String get openNetworkStream => 'Atvērt tīkla straumi';

  @override
  String get editPlaylist => 'Rediģēt atskaņošanas sarakstu';

  @override
  String get editStreamItem => 'Rediģēt straumes vienumu';

  @override
  String get streamUrl => 'Straumes URL';

  @override
  String get platformType => 'Platforma / veids';

  @override
  String get optionalTitle => 'Nosaukums (neobligāts)';

  @override
  String get optionalImageUrl => 'Attēla URL (neobligāts)';

  @override
  String get myStream => 'Mana straume';

  @override
  String get saveToLibrary => 'Saglabāt bibliotēkā';

  @override
  String get justPlay => 'Tikai atskaņot';

  @override
  String get autoDetect => 'Automātiska noteikšana';

  @override
  String get apiKeyRequired => 'Nepieciešama API atslēga';

  @override
  String get customApiKey => 'Izmantot savu API atslēgu';

  @override
  String get clientId => 'Klienta ID';

  @override
  String get clientSecret => 'Klienta noslēpums';

  @override
  String get saveCredentials => 'Saglabāt piekļuves datus';

  @override
  String get searchStrategy => 'Meklēšanas stratēģija';

  @override
  String get credentialsLocalOnly =>
      'Droši glabājas šajā ierīcē. Nekad netiek sūtīti uz PPPlayer.';

  @override
  String get scrapingHelp =>
      'API atslēga un kvota nav vajadzīga. Var būt lēnāk vai mazāk uzticami.';

  @override
  String get streamHelp =>
      'Ievadiet HTTP(S) URL vai M3U atskaņošanas saraksta saiti.';

  @override
  String get deletePlaylistConfirm =>
      'Neatgriezeniski dzēst šo atskaņošanas sarakstu?';

  @override
  String get clearCacheConfirm =>
      'Dzēst kešatmiņu? Bibliotēka un izlase nemainīsies.';

  @override
  String get clearHistoryConfirm =>
      'Neatgriezeniski dzēst klausīšanās vēsturi?';

  @override
  String get addedToQueue => 'Pievienots rindai';

  @override
  String get addedVideo => 'Video pievienots';

  @override
  String addedChannels(String count) {
    return 'Pievienotie kanāli: $count';
  }

  @override
  String get removedFromPlaylist => 'Izņemts no saraksta';

  @override
  String get exportCancelled => 'Eksports atcelts';

  @override
  String exportComplete(String count) {
    return 'Saraksts eksportēts. Izlaistie vienumi: $count';
  }

  @override
  String get playlistExported => 'Saraksts eksportēts';

  @override
  String get live => 'Tiešraide';

  @override
  String get sponsored => 'Sponsorēts';

  @override
  String get removeFromPlaylist => 'Izņemt no saraksta';

  @override
  String get likedSongsHelp => 'Saglabājiet dziesmas, lai tās redzētu šeit';

  @override
  String get apiSingleVideoHint =>
      'Šo video varat pievienot, neimportējot atskaņošanas sarakstu.';

  @override
  String get linkCopied => 'Saite nokopēta';

  @override
  String get willPlayNext => 'Tiks atskaņots nākamais';

  @override
  String get checkItOut => 'Apskatīt';

  @override
  String get loadFailed => 'Neizdevās ielādēt saturu. Mēģiniet vēlreiz.';
}
