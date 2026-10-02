// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'ALBUMID';

  @override
  String get api => 'API';

  @override
  String get artists => 'ARTISTID';

  @override
  String get artwork => 'KAANEPILT';

  @override
  String get appVersion => 'Rakenduse versioon';

  @override
  String get artist => 'Esitaja';

  @override
  String get artistsYouFollow => 'Artistid, keda jälgite';

  @override
  String get autoplay => 'Automaatne esitus';

  @override
  String get becauseYouListenedTo => 'Sest te kuulasite';

  @override
  String get browseAll => 'Sirvi kõiki';

  @override
  String get cancel => 'Tühista';

  @override
  String get clearAppCache => 'Tühjenda rakenduse vahemälu?';

  @override
  String get clearCache => 'Tühjenda vahemälu';

  @override
  String get clearHistory => 'Tühjenda ajalugu?';

  @override
  String get clearRecentlyPlayed => 'Tühjenda hiljuti mängitud';

  @override
  String get contentMarket => 'Sisuturg';

  @override
  String get continueListening => 'Jätka kuulamist';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Jätka video taasesitust väikeses aknas';

  @override
  String get create => 'Loo';

  @override
  String get createAPlaylistToGetStarted => 'Alustamiseks loo esitusloend';

  @override
  String currentSelectedcountry(Object country) {
    return 'Praegune: $country';
  }

  @override
  String get deletePlaylist => 'Kustuta esitusloend';

  @override
  String get editProfile => 'Muuda profiili';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Viga turgude laadimisel: $err';
  }

  @override
  String error(Object error) {
    return 'Viga: $error';
  }

  @override
  String explore(Object genre) {
    return 'Avasta $genre';
  }

  @override
  String get fansAlsoLike => 'FÄNNIDELE MEELDIB KA';

  @override
  String featuringTouppercase(Object artist) {
    return 'KAASATEGEV $artist';
  }

  @override
  String get featuredPlaylists => 'Esiletõstetud esitusloendid';

  @override
  String get followArtistsToSeeThemHere => 'Jälgi artiste, et näha neid siin';

  @override
  String get followStationsToSeeThemHere => 'Jälgi jaamu, et näha neid siin';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Sunni ainult heli voogesitus andmete säästmiseks';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Vabastab ruumi ja laeb uued andmed';

  @override
  String get fromYourFavorites => 'Sinu lemmikutest';

  @override
  String get goBack => 'Mine tagasi';

  @override
  String inspiredByName(Object name) {
    return 'Inspireeritud artistist $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Jätka sarnaste lugude mängimist, kui järjekord lõppeb';

  @override
  String get library => 'Raamatukogu';

  @override
  String get likeAlbumsToSeeThemHere =>
      'Pane albumitele meeldib, et näha neid siin';

  @override
  String get likedSongs => 'Meeldinud lood';

  @override
  String get lowDataMode => 'Madala andmeside režiim';

  @override
  String get madeForYou => 'Teile tehtud';

  @override
  String moreLikeName(Object name) {
    return 'Rohkem nagu $name';
  }

  @override
  String get moreOptions => 'Rohkem valikuid';

  @override
  String get nameYourMasterpiece => 'Nime oma meistriteos...';

  @override
  String get newPlaylist => 'Uus esitusloend';

  @override
  String get newReleases => 'Uued väljalasked';

  @override
  String get next => 'Järgmine';

  @override
  String get noAlbumsFound => 'Albumeid ei leitud';

  @override
  String get noArtistsFollowed => 'Artiste ei jälgita';

  @override
  String get noArtistsFound => 'Artiste ei leitud';

  @override
  String get noLikedAlbums => 'Meeldinud albumeid pole';

  @override
  String get noPlaylistsFound => 'Esitusloendeid ei leitud';

  @override
  String get noPlaylistsYet => 'Esitusloendeid veel pole';

  @override
  String get noResultsFound => 'Tulemusi ei leitud';

  @override
  String get noStationsFollowed => 'Jaamu ei jälgita';

  @override
  String get noTrackPlaying => 'Ühtegi lugu ei mängi';

  @override
  String get noTracksFound => 'Lugusid ei leitud';

  @override
  String get playlists => 'ESITUSLOENDID';

  @override
  String get popular => 'POPULAARNE';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Eemalda kuulamisajalugu jäädavalt';

  @override
  String get pictureinpicturePip => 'Pilt pildis (PiP)';

  @override
  String get popularAlbums => 'Populaarsed albumid';

  @override
  String get popularArtists => 'Populaarsed artistid';

  @override
  String get popularGenres => 'Populaarsed žanrid';

  @override
  String get popularSongs => 'Populaarsed lood';

  @override
  String get popularTracks => 'Populaarsed lood';

  @override
  String get popularHitsRightNow => 'Populaarsed hitid praegu';

  @override
  String get previous => 'Eelmine';

  @override
  String get queue => 'JÄRJEKORD';

  @override
  String get recentSearches => 'Hiljutised otsingud';

  @override
  String get recommendedForYou => 'Sulle soovitatud';

  @override
  String get scraping => 'Andmete hankimine';

  @override
  String get search => 'Otsi';

  @override
  String get searchInAlbum => 'Otsi albumist...';

  @override
  String get searchInLibrary => 'Otsi raamatukogust...';

  @override
  String get searchInPlaylist => 'Otsi esitusloendist';

  @override
  String get searchLikedSongs => 'Otsi meeldinud lugudest...';

  @override
  String get searchPopularSongs => 'Otsi populaarseid lugusid...';

  @override
  String get selectMarket => 'Vali turg';

  @override
  String get settings => 'Seaded';

  @override
  String get showVideoPlayer => 'Näita videopleierit';

  @override
  String get shuffle => 'Juhuslik';

  @override
  String get spotifyCredentials => 'Spotify mandaadid';

  @override
  String get suggestedStations => 'Soovitatud jaamad';

  @override
  String get tracks => 'LOOD';

  @override
  String get trending => 'Trendikas';

  @override
  String get tryAgain => 'Proovi uuesti';

  @override
  String get tryADifferentSearchTerm => 'Proovige teist otsinguterminit';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Kasuta YouTube\'i mängijat, kui see on saadaval';

  @override
  String get video => 'VIDEO';

  @override
  String get whatDoYouWantToListenTo => 'Mida te soovite kuulata?';

  @override
  String get youtubeCredentials => 'YouTube\'i mandaadid';

  @override
  String get yourLibrary => 'Teie raamatukogu';

  @override
  String get playerscreenviewswitch => 'mangija_ekraani_vaate_lüliti';

  @override
  String get addToPlaylist => 'Lisa esitusloendisse';

  @override
  String get addToQueue => 'Lisa järjekorda';

  @override
  String get copyId => 'Kopeeri ID';

  @override
  String get copyLink => 'Kopeeri link';

  @override
  String get discover => 'Avasta';

  @override
  String get enterYourName => 'Sisesta oma nimi';

  @override
  String get favorites => 'Lemmikud';

  @override
  String get goToAlbum => 'Mine albumisse';

  @override
  String get goToArtist => 'Mine artisti juurde';

  @override
  String get goToArtistRadio => 'Mine artisti raadiosse';

  @override
  String get goToPlaylist => 'Mine esitusloendisse';

  @override
  String get goToSongRadio => 'Mine loo raadiosse';

  @override
  String get home => 'Avaleht';

  @override
  String get myAwesomePlaylist => 'Minu äge esitusloend';

  @override
  String get myPlaylist => 'Minu esitusloend';

  @override
  String get newPlaylist1 => 'Uus esitusloend';

  @override
  String get play => 'Mängi';

  @override
  String get playStation => 'Mängi jaama';

  @override
  String get playNext => 'Mängi järgmisena';

  @override
  String get playlist => 'Esitusloend';

  @override
  String get playlistName => 'Esitusloendi nimi';

  @override
  String get playlists1 => 'Esitusloendid';

  @override
  String get queue1 => 'Järjekord';

  @override
  String get recentlyPlayed => 'Hiljuti mängitud';

  @override
  String get removeFromQueue => 'Eemalda järjekorrast';

  @override
  String get retry => 'Proovi uuesti';

  @override
  String get searchMusicArtistsAlbums => 'Otsi muusikat, artiste, albumeid...';

  @override
  String get share => 'Jaga';

  @override
  String featuringArtist(String artistName) {
    return 'KAASATEGEV $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Praegune: $country';
  }

  @override
  String get queueTooltip => 'Järjekord';

  @override
  String get searchHint => 'Otsi muusikat, artiste, albumeid...';

  @override
  String get language => 'Keel';

  @override
  String get systemDefault => 'Süsteemi vaikeväärtus';

  @override
  String get songsTab => 'Laulud';

  @override
  String get foldersTab => 'Kaustad';

  @override
  String get artistsTab => 'Artistid';

  @override
  String get albumsTab => 'Albumid';

  @override
  String get genresTab => 'Žanrid';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Taasesituse kiirus';

  @override
  String get addMusic => 'Lisa muusika';

  @override
  String get addFiles => 'Lisa failid';

  @override
  String get addFolder => 'Lisa kaust';

  @override
  String get rescanLibrary => 'Skanni teek uuesti';

  @override
  String get sortTitle => 'Sordi pealkirja järgi';

  @override
  String get sortArtist => 'Sordi artisti järgi';

  @override
  String get sortAlbum => 'Sordi albumi järgi';

  @override
  String get sortDuration => 'Sordi kestuse järgi';

  @override
  String get sortDateAdded => 'Sordi lisamiskuupäeva järgi';

  @override
  String get sortBy => 'Sorteeri';

  @override
  String get trackInformation => 'Loo teave';

  @override
  String get removeFromLibrary => 'Eemalda teegist';

  @override
  String get showInFolder => 'Näita kaustas';

  @override
  String get unknownArtist => 'Tundmatu artist';

  @override
  String get unknownAlbum => 'Tundmatu album';

  @override
  String get importedFiles => 'Imporditud failid';

  @override
  String get playFolder => 'Esita kausta';

  @override
  String get shuffleFolder => 'Esita kausta juhuslikult';

  @override
  String get playAll => 'Esita kõik';

  @override
  String get includeSubfolders => 'Kaasa alamkaustad';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lugu',
      one: '1 lugu',
      zero: '0 lugu',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Kohalikke laule ei leitud';

  @override
  String get searchLocalMusic => 'Otsi kohalikku muusikat...';

  @override
  String get viewAsList => 'Vaata loendina';

  @override
  String get viewAsGrid => 'Vaata ruudustikuna';

  @override
  String get trackInfoPath => 'Tee';

  @override
  String get trackInfoFormat => 'Formaat';

  @override
  String get trackInfoDuration => 'Kestus';

  @override
  String get aboutDescription => 'Tasuta avatud lähtekoodiga meediapleier.';

  @override
  String get aboutApp => 'PPPlayeri teave';

  @override
  String get appTagline => 'Sinu muusika. Sinu moodi.';

  @override
  String get exploreApp => 'Avasta PPPlayerit';

  @override
  String get viewSource => 'Vaata lähtekoodi';

  @override
  String get seeWhatsNew => 'Vaata uuendusi';

  @override
  String get getHelp => 'Saa abi';

  @override
  String versionInfo(Object version, Object build) {
    return 'Versioon $version (Järk $build)';
  }

  @override
  String get createdBy => 'Loonud Lucas Coelho';

  @override
  String get website => 'Veebisait';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Väljalaskemärkmed';

  @override
  String get support => 'Tugi';

  @override
  String get license => 'Litsents';

  @override
  String get acknowledgments => 'Tunnustused';

  @override
  String get close => 'Sulge';

  @override
  String copyright(Object year) {
    return '© $year PPPlayeri panustajad';
  }

  @override
  String get goodMorning => 'Tere hommikust';

  @override
  String get goodAfternoon => 'Tere päevast';

  @override
  String get goodEvening => 'Tere õhtust';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Sinu muusika ootab.';

  @override
  String dailyMix(Object number) {
    return 'Päevane miks $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'Sinu lemmikud\nja uued avastused';

  @override
  String get discoverWeekly => 'Iganädalane avastus';

  @override
  String get releaseRadar => 'Uute väljalasete radar';

  @override
  String get newMusicJustForYou => 'Uus muusika\nainult sulle';

  @override
  String get chillMix => 'Rahustav miks';

  @override
  String get relaxAndUnwind => 'Lõõgastu ja puhka';

  @override
  String get focusMix => 'Keskendumise miks';

  @override
  String get deepFocusAndProductivity => 'Sügav fookus\nja produktiivsus';

  @override
  String artistRadio(Object artist) {
    return '$artist Raadio';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre Raadio';
  }

  @override
  String get filterAll => 'Kõik';

  @override
  String get filterPlaylists => 'Esitusloendid';

  @override
  String get filterArtists => 'Artistid';

  @override
  String get filterAlbums => 'Albumid';

  @override
  String get filterStations => 'Jaamad';

  @override
  String get filterStreams => 'Vood';

  @override
  String get localMusicCard => 'Kohalik muusika';

  @override
  String get createPlaylistButton => 'Loo esitusloend';

  @override
  String get radioStations => 'Raadiojaamad';

  @override
  String get discoverMusic => 'Avasta muusikat';

  @override
  String get importLocalMusic => 'Impordi kohalik muusika';

  @override
  String get importAudioFiles => 'Impordi helifailid';

  @override
  String get importFolder => 'Impordi kaust';

  @override
  String get importFolderSubtitle => 'Vali kaust, mis sisaldab helifaile';

  @override
  String get importPlaylist => 'Impordi esitusloend';

  @override
  String get importPlaylistSubtitle => 'Impordi .m3u või .m3u8 fail';

  @override
  String get exportPlaylist => 'Ekspordi esitusloend';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Toetamata vorming või rikutud fail';

  @override
  String get playbackErrorFileInaccessible =>
      'Fail pole kättesaadav või seda ei leitud';

  @override
  String get localVideosCard => 'Kohalikud videod';

  @override
  String get noLocalVideos => 'Videoid ei leitud';

  @override
  String get searchLocalVideos => 'Otsi kohalikke videoid';

  @override
  String get addVideos => 'Lisa videod';

  @override
  String get subtitles => 'Subtiitrid';

  @override
  String get audioTracks => 'Helirajad';

  @override
  String get loadSubtitleFile => 'Laadi subtiitrifail...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Viga subtiitrite laadimisel: $error';
  }

  @override
  String get off => 'Väljas';

  @override
  String get playOn => 'Esita seadmes';

  @override
  String get thisDevice => 'See seade';

  @override
  String get availableDevices => 'Saadaolevad seadmed';

  @override
  String get searchingDevices => 'Seadmete otsimine…';

  @override
  String get refresh => 'Värskenda';

  @override
  String get connecting => 'Ühendamine…';

  @override
  String connectingTo(String name) {
    return 'Ühendamine seadmega $name…';
  }

  @override
  String get connected => 'Ühendatud';

  @override
  String get unsupportedOutput =>
      'Seda allikat ei saa selle väljundi kaudu esitada.';

  @override
  String get airPlayAudioOutput => 'AirPlay ja heliväljund';

  @override
  String get returnForAirPlay => 'AirPlay kasutamiseks esita selles seadmes.';

  @override
  String get openSoundSettings => 'Väljundi valimiseks ava heliseaded.';

  @override
  String get soundSettingsError => 'Heliseadeid ei saanud avada.';

  @override
  String get systemOutput => 'Süsteemi väljund';

  @override
  String playingOn(String name) {
    return 'Esitatakse seadmes $name';
  }

  @override
  String get chooseAirPlay =>
      'Kõlari või teleri valimiseks puuduta AirPlay nuppu.';

  @override
  String get airPlayDevice => 'AirPlay seade';

  @override
  String get playOnIphone => 'Esita selles iPhone’is';

  @override
  String get chooseIphone => 'Vali see iPhone alloleva AirPlay nupuga.';

  @override
  String get profile => 'Profiil';

  @override
  String get preferences => 'Eelistused';

  @override
  String get themeColor => 'Teema värv';

  @override
  String get yourMusic => 'Sinu muusika';

  @override
  String get apiCredentials => 'API pääsuandmed';

  @override
  String get dataStorage => 'Andmed ja salvestusruum';

  @override
  String get editProfileHelp => 'Määra oma nimi ja avatar';

  @override
  String get customProvider => 'Kohandatud pakkuja';

  @override
  String get defaultProvider => 'PPPlayeri vaikeseade';

  @override
  String get proExperience => 'Pro-kogemus aktiivne';

  @override
  String get beta => 'Beeta';

  @override
  String get loading => 'Laadimine…';

  @override
  String get unknown => 'Tundmatu';

  @override
  String get pause => 'Paus';

  @override
  String get repeat => 'Korda';

  @override
  String get mute => 'Vaigista';

  @override
  String get unmute => 'Lülita heli sisse';

  @override
  String get fitVideo => 'Mahuta';

  @override
  String get fillVideo => 'Täida';

  @override
  String get fullscreen => 'Täisekraan';

  @override
  String get exitFullscreen => 'Välju täisekraanist';

  @override
  String get volume => 'Helitugevus';

  @override
  String get save => 'Salvesta';

  @override
  String get delete => 'Kustuta';

  @override
  String get clear => 'Tühjenda';

  @override
  String get follow => 'Jälgi';

  @override
  String get unfollow => 'Lõpeta jälgimine';

  @override
  String get following => 'Jälgitav';

  @override
  String get showAll => 'Näita kõiki';

  @override
  String get appearance => 'Välimus';

  @override
  String get subtitleSize => 'Suurus';

  @override
  String get subtitleBackground => 'Taust';

  @override
  String get earlier => 'Varem';

  @override
  String get later => 'Hiljem';

  @override
  String get reset => 'Lähtesta';

  @override
  String subtitleDelay(String seconds) {
    return 'Viivitus: $seconds s';
  }

  @override
  String get morePlaybackControls => 'Rohkem esitusnuppe';

  @override
  String get hideVideo => 'Peida video';

  @override
  String get showVideo => 'Näita videot';

  @override
  String get closeQueue => 'Sulge järjekord';

  @override
  String get enabled => 'Sees';

  @override
  String get openFile => 'Ava fail…';

  @override
  String get openFolder => 'Ava kaust…';

  @override
  String get openUrl => 'Ava URL…';

  @override
  String get fileMenu => 'Fail';

  @override
  String get viewMenu => 'Vaade';

  @override
  String get windowMenu => 'Aken';

  @override
  String get saveChanges => 'Salvesta muudatused';

  @override
  String get themeAvatarColor => 'Teema ja avatari värv';

  @override
  String get networkStreams => 'Võrguvood';

  @override
  String get networkStream => 'Võrguvoog';

  @override
  String get openNetworkStream => 'Ava võrguvoog';

  @override
  String get editPlaylist => 'Muuda esitusloendit';

  @override
  String get editStreamItem => 'Muuda voo üksust';

  @override
  String get streamUrl => 'Voo URL';

  @override
  String get platformType => 'Platvorm / tüüp';

  @override
  String get optionalTitle => 'Pealkiri (valikuline)';

  @override
  String get optionalImageUrl => 'Pildi URL (valikuline)';

  @override
  String get myStream => 'Minu voog';

  @override
  String get saveToLibrary => 'Salvesta kogusse';

  @override
  String get justPlay => 'Lihtsalt esita';

  @override
  String get autoDetect => 'Tuvasta automaatselt';

  @override
  String get apiKeyRequired => 'Vajalik on API võti';

  @override
  String get customApiKey => 'Kasuta oma API võtit';

  @override
  String get clientId => 'Kliendi ID';

  @override
  String get clientSecret => 'Kliendi salavõti';

  @override
  String get saveCredentials => 'Salvesta pääsuandmed';

  @override
  String get searchStrategy => 'Otsingustrateegia';

  @override
  String get credentialsLocalOnly =>
      'Turvaliselt salvestatud selles seadmes. Ei saadeta kunagi PPPlayerile.';

  @override
  String get scrapingHelp =>
      'API võtit ega kvooti pole vaja. Võib olla aeglasem või vähem töökindel.';

  @override
  String get streamHelp => 'Sisesta HTTP(S) URL või M3U-esitusloendi link.';

  @override
  String get deletePlaylistConfirm => 'Kustuta see esitusloend jäädavalt?';

  @override
  String get clearCacheConfirm =>
      'Kustuta vahemälu? Kogu ja lemmikud jäävad muutmata.';

  @override
  String get clearHistoryConfirm => 'Kustuta kuulamisajalugu jäädavalt?';

  @override
  String get addedToQueue => 'Lisatud järjekorda';

  @override
  String get addedVideo => 'Video lisatud';

  @override
  String addedChannels(String count) {
    return 'Lisatud kanalid: $count';
  }

  @override
  String get removedFromPlaylist => 'Eemaldatud esitusloendist';

  @override
  String get exportCancelled => 'Eksport tühistatud';

  @override
  String exportComplete(String count) {
    return 'Esitusloend eksporditud. Vahele jäetud üksused: $count';
  }

  @override
  String get playlistExported => 'Esitusloend eksporditud';

  @override
  String get live => 'Otse';

  @override
  String get sponsored => 'Sponsoreeritud';

  @override
  String get removeFromPlaylist => 'Eemalda esitusloendist';

  @override
  String get likedSongsHelp => 'Salvesta lugusid, et neid siin näha';

  @override
  String get apiSingleVideoHint =>
      'Saad selle video lisada esitusloendit importimata.';

  @override
  String get linkCopied => 'Link kopeeritud';

  @override
  String get willPlayNext => 'Esitatakse järgmisena';

  @override
  String get checkItOut => 'Vaata lähemalt';

  @override
  String get loadFailed => 'Sisu ei õnnestunud laadida. Proovi uuesti.';
}
