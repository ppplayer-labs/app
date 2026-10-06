// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

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
  String get artists => 'IZVOĐAČI';

  @override
  String get artwork => 'OMOT';

  @override
  String get appVersion => 'Verzija aplikacije';

  @override
  String get artist => 'Izvođač';

  @override
  String get artistsYouFollow => 'Izvođači koje pratite';

  @override
  String get autoplay => 'Automatska reprodukcija';

  @override
  String get becauseYouListenedTo => 'Zato što ste slušali';

  @override
  String get browseAll => 'Pregledaj sve';

  @override
  String get cancel => 'Odustani';

  @override
  String get clearAppCache => 'Očistiti predmemoriju aplikacije?';

  @override
  String get clearCache => 'Očisti predmemoriju';

  @override
  String get clearHistory => 'Očistiti povijest?';

  @override
  String get clearRecentlyPlayed => 'Očisti nedavno slušano';

  @override
  String get contentMarket => 'Tržište sadržaja';

  @override
  String get continueListening => 'Nastavi slušati';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Nastavi reprodukciju videa u malom prozoru';

  @override
  String get create => 'Stvori';

  @override
  String get createAPlaylistToGetStarted =>
      'Stvorite popis za reprodukciju za početak';

  @override
  String currentSelectedcountry(Object country) {
    return 'Trenutno: $country';
  }

  @override
  String get deletePlaylist => 'Izbriši popis za reprodukciju';

  @override
  String get editProfile => 'Uredi profil';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Greška pri učitavanju tržišta: $err';
  }

  @override
  String error(Object error) {
    return 'Greška: $error';
  }

  @override
  String explore(Object genre) {
    return 'Istraži $genre';
  }

  @override
  String get fansAlsoLike => 'OBOŽAVATELJI TAKOĐER VOLE';

  @override
  String featuringTouppercase(Object artist) {
    return 'SUDJELUJE $artist';
  }

  @override
  String get featuredPlaylists => 'Istaknuti popisi za reprodukciju';

  @override
  String get followArtistsToSeeThemHere =>
      'Pratite izvođače da biste ih vidjeli ovdje';

  @override
  String get followStationsToSeeThemHere =>
      'Pratite stanice da biste ih vidjeli ovdje';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Forsiraj samo audio streamove za uštedu podataka';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Oslobađa prostor i forsira nove podatke';

  @override
  String get fromYourFavorites => 'Iz vaših favorita';

  @override
  String get goBack => 'Idi natrag';

  @override
  String inspiredByName(Object name) {
    return 'Inspirirano izvođačem $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Nastavi reproducirati slične pjesme kada završi red čekanja';

  @override
  String get library => 'Biblioteka';

  @override
  String get likeAlbumsToSeeThemHere =>
      'Lajkajte albume da biste ih vidjeli ovdje';

  @override
  String get likedSongs => 'Lajkane pjesme';

  @override
  String get lowDataMode => 'Način rada s malo podataka';

  @override
  String get madeForYou => 'Napravljeno za vas';

  @override
  String moreLikeName(Object name) {
    return 'Više kao $name';
  }

  @override
  String get moreOptions => 'Više opcija';

  @override
  String get nameYourMasterpiece => 'Imenujte svoje remek-djelo...';

  @override
  String get newPlaylist => 'Novi popis za reprodukciju';

  @override
  String get newReleases => 'Nova izdanja';

  @override
  String get next => 'Sljedeće';

  @override
  String get noAlbumsFound => 'Nisu pronađeni albumi';

  @override
  String get noArtistsFollowed => 'Ne pratite nijednog izvođača';

  @override
  String get noArtistsFound => 'Nisu pronađeni izvođači';

  @override
  String get noLikedAlbums => 'Nema lajkanih albuma';

  @override
  String get noPlaylistsFound => 'Nisu pronađeni popisi za reprodukciju';

  @override
  String get noPlaylistsYet => 'Još nema popisa za reprodukciju';

  @override
  String get noResultsFound => 'Nema rezultata';

  @override
  String get noStationsFollowed => 'Ne pratite nijednu stanicu';

  @override
  String get noTrackPlaying => 'Niti jedna pjesma se ne reproducira';

  @override
  String get noTracksFound => 'Nisu pronađene pjesme';

  @override
  String get playlists => 'POPISI ZA REPRODUKCIJU';

  @override
  String get popular => 'POPULARNO';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Trajno ukloni povijest slušanja';

  @override
  String get pictureinpicturePip => 'Slika u slici (PiP)';

  @override
  String get popularAlbums => 'Popularni albumi';

  @override
  String get popularArtists => 'Popularni izvođači';

  @override
  String get popularGenres => 'Popularni žanrovi';

  @override
  String get popularSongs => 'Popularne pjesme';

  @override
  String get popularTracks => 'Popularne pjesme';

  @override
  String get popularHitsRightNow => 'Trenutno popularni hitovi';

  @override
  String get previous => 'Prethodno';

  @override
  String get queue => 'RED ČEKANJA';

  @override
  String get recentSearches => 'Nedavna pretraživanja';

  @override
  String get recommendedForYou => 'Preporučeno za vas';

  @override
  String get scraping => 'Dohvaćanje podataka';

  @override
  String get search => 'Pretraživanje';

  @override
  String get searchInAlbum => 'Pretraži u albumu...';

  @override
  String get searchInLibrary => 'Pretraži u biblioteci...';

  @override
  String get searchInPlaylist => 'Pretraži u popisu za reprodukciju';

  @override
  String get searchLikedSongs => 'Pretraži lajkane pjesme...';

  @override
  String get searchPopularSongs => 'Pretraži popularne pjesme...';

  @override
  String get selectMarket => 'Odaberi tržište';

  @override
  String get settings => 'Postavke';

  @override
  String get showVideoPlayer => 'Prikaži video player';

  @override
  String get shuffle => 'Nasumično';

  @override
  String get spotifyCredentials => 'Vjerodajnice za Spotify';

  @override
  String get suggestedStations => 'Predložene stanice';

  @override
  String get tracks => 'PJESME';

  @override
  String get trending => 'U trendu';

  @override
  String get tryAgain => 'Pokušaj ponovno';

  @override
  String get tryADifferentSearchTerm =>
      'Pokušajte s drugim pojmom za pretraživanje';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Koristi YouTube player kada je dostupan';

  @override
  String get video => 'VIDEO';

  @override
  String get whatDoYouWantToListenTo => 'Što želite slušati?';

  @override
  String get youtubeCredentials => 'Vjerodajnice za YouTube';

  @override
  String get yourLibrary => 'Vaša biblioteka';

  @override
  String get playerscreenviewswitch => 'prebacivanje_prikaza_zaslona_sviraca';

  @override
  String get addToPlaylist => 'Dodaj na popis za reprodukciju';

  @override
  String get addToQueue => 'Dodaj u red čekanja';

  @override
  String get copyId => 'Kopiraj ID';

  @override
  String get copyLink => 'Kopiraj vezu';

  @override
  String get discover => 'Otkrij';

  @override
  String get enterYourName => 'Unesite svoje ime';

  @override
  String get favorites => 'Favoriti';

  @override
  String get goToAlbum => 'Idi na album';

  @override
  String get goToArtist => 'Idi na izvođača';

  @override
  String get goToArtistRadio => 'Idi na radio izvođača';

  @override
  String get goToPlaylist => 'Idi na popis za reprodukciju';

  @override
  String get goToSongRadio => 'Idi na radio pjesme';

  @override
  String get home => 'Početna';

  @override
  String get myAwesomePlaylist => 'Moj super popis za reprodukciju';

  @override
  String get myPlaylist => 'Moj popis za reprodukciju';

  @override
  String get newPlaylist1 => 'Novi popis za reprodukciju';

  @override
  String get play => 'Reproduciraj';

  @override
  String get playStation => 'Reproduciraj stanicu';

  @override
  String get playNext => 'Reproduciraj sljedeće';

  @override
  String get playlist => 'Popis za reprodukciju';

  @override
  String get playlistName => 'Naziv popisa za reprodukciju';

  @override
  String get playlists1 => 'Popisi za reprodukciju';

  @override
  String get queue1 => 'Red čekanja';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueUpNext => 'Up next';

  @override
  String get recentlyPlayed => 'Nedavno slušano';

  @override
  String get removeFromQueue => 'Ukloni iz reda čekanja';

  @override
  String get retry => 'Pokušaj ponovno';

  @override
  String get searchMusicArtistsAlbums =>
      'Pretražite glazbu, izvođače, albume...';

  @override
  String get share => 'Dijeli';

  @override
  String featuringArtist(String artistName) {
    return 'SUDJELUJE $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Trenutno: $country';
  }

  @override
  String get queueTooltip => 'Red čekanja';

  @override
  String get searchHint => 'Pretražite glazbu, izvođače, albume...';

  @override
  String get language => 'Jezik';

  @override
  String get systemDefault => 'Zadano u sustavu';

  @override
  String get songsTab => 'Pjesme';

  @override
  String get foldersTab => 'Mape';

  @override
  String get artistsTab => 'Izvođači';

  @override
  String get albumsTab => 'Albumi';

  @override
  String get genresTab => 'Žanrovi';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Brzina reprodukcije';

  @override
  String get addMusic => 'Dodaj glazbu';

  @override
  String get addFiles => 'Dodaj datoteke';

  @override
  String get addFolder => 'Dodaj mapu';

  @override
  String get rescanLibrary => 'Ponovno skeniraj biblioteku';

  @override
  String get sortTitle => 'Poredaj po naslovu';

  @override
  String get sortArtist => 'Poredaj po izvođaču';

  @override
  String get sortAlbum => 'Poredaj po albumu';

  @override
  String get sortDuration => 'Poredaj po trajanju';

  @override
  String get sortDateAdded => 'Poredaj po datumu';

  @override
  String get sortBy => 'Poredaj po';

  @override
  String get trackInformation => 'Informacije o zapisu';

  @override
  String get removeFromLibrary => 'Ukloni iz biblioteke';

  @override
  String get showInFolder => 'Prikaži u mapi';

  @override
  String get unknownArtist => 'Nepoznat izvođač';

  @override
  String get unknownAlbum => 'Nepoznat album';

  @override
  String get importedFiles => 'Uvezene datoteke';

  @override
  String get playFolder => 'Pokreni mapu';

  @override
  String get shuffleFolder => 'Nasumično pokreni mapu';

  @override
  String get playAll => 'Pokreni sve';

  @override
  String get includeSubfolders => 'Uključi podmape';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zapisa',
      few: '$count zapisa',
      one: '1 zapis',
      zero: '0 zapisa',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Nema lokalnih pjesama';

  @override
  String get searchLocalMusic => 'Pretraži lokalnu glazbu...';

  @override
  String get viewAsList => 'Prikaži kao popis';

  @override
  String get viewAsGrid => 'Prikaži kao mrežu';

  @override
  String get trackInfoPath => 'Putanja';

  @override
  String get trackInfoFormat => 'Format';

  @override
  String get trackInfoDuration => 'Trajanje';

  @override
  String get aboutDescription => 'Besplatan media player otvorenog koda.';

  @override
  String get aboutApp => 'O PPPlayeru';

  @override
  String get appTagline => 'Tvoja glazba. Tvoj način.';

  @override
  String get exploreApp => 'Istraži PPPlayer';

  @override
  String get viewSource => 'Prikaži izvorni kod';

  @override
  String get seeWhatsNew => 'Što je novo';

  @override
  String get getHelp => 'Zatraži pomoć';

  @override
  String versionInfo(Object version, Object build) {
    return 'Verzija $version (Oznaka međuverzije $build)';
  }

  @override
  String get createdBy => 'Izradio Lucas Coelho';

  @override
  String get website => 'Web stranica';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Napomene o izdanju';

  @override
  String get support => 'Podrška';

  @override
  String get license => 'Licenca';

  @override
  String get acknowledgments => 'Zahvale';

  @override
  String get close => 'Zatvori';

  @override
  String copyright(Object year) {
    return '© $year Suradnici PPPlayer-a';
  }

  @override
  String get goodMorning => 'Dobro jutro';

  @override
  String get goodAfternoon => 'Dobar dan';

  @override
  String get goodEvening => 'Dobra večer';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Tvoja glazba te čeka.';

  @override
  String dailyMix(Object number) {
    return 'Dnevni miks $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries => 'Tvoji favoriti\ni nova otkrića';

  @override
  String get discoverWeekly => 'Tjedno otkriće';

  @override
  String get releaseRadar => 'Radar izdanja';

  @override
  String get newMusicJustForYou => 'Nova glazba\nsamo za tebe';

  @override
  String get chillMix => 'Opušteni miks';

  @override
  String get relaxAndUnwind => 'Opusti se i uživaj';

  @override
  String get focusMix => 'Miks za fokus';

  @override
  String get deepFocusAndProductivity => 'Duboki fokus\ni produktivnost';

  @override
  String artistRadio(Object artist) {
    return '$artist radio';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre radio';
  }

  @override
  String get filterAll => 'Sve';

  @override
  String get filterPlaylists => 'Popisi za reprodukciju';

  @override
  String get filterArtists => 'Izvođači';

  @override
  String get filterAlbums => 'Albumi';

  @override
  String get filterStations => 'Postaje';

  @override
  String get filterStreams => 'Tokovi';

  @override
  String get localMusicCard => 'Lokalna glazba';

  @override
  String get createPlaylistButton => 'Stvori popis za reprodukciju';

  @override
  String get radioStations => 'Radiopostaje';

  @override
  String get discoverMusic => 'Otkrij glazbu';

  @override
  String get importLocalMusic => 'Uvezi lokalnu glazbu';

  @override
  String get importAudioFiles => 'Uvezi audio datoteke';

  @override
  String get importFolder => 'Uvezi mapu';

  @override
  String get importFolderSubtitle =>
      'Odaberite mapu koja sadrži audio datoteke';

  @override
  String get importPlaylist => 'Uvezi popis pjesama';

  @override
  String get importPlaylistSubtitle => 'Uvezi .m3u ili .m3u8 datoteku';

  @override
  String get exportPlaylist => 'Izvezi popis pjesama';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Nepodržan format ili oštećena datoteka';

  @override
  String get playbackErrorFileInaccessible =>
      'Datoteka nedostupna ili nije pronađena';

  @override
  String get localVideosCard => 'Lokalni videozapisi';

  @override
  String get noLocalVideos => 'Nisu pronađeni videozapisi';

  @override
  String get searchLocalVideos => 'Pretraži lokalne videozapise';

  @override
  String get addVideos => 'Dodaj videozapise';

  @override
  String get subtitles => 'Titlovi';

  @override
  String get audioTracks => 'Audio zapisi';

  @override
  String get loadSubtitleFile => 'Učitaj datoteku titlova...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Pogreška pri učitavanju titlova: $error';
  }

  @override
  String get off => 'Isključeno';

  @override
  String get playOn => 'Reproduciraj na';

  @override
  String get thisDevice => 'Ovaj uređaj';

  @override
  String get availableDevices => 'Dostupni uređaji';

  @override
  String get searchingDevices => 'Traženje uređaja…';

  @override
  String get refresh => 'Osvježi';

  @override
  String get connecting => 'Povezivanje…';

  @override
  String connectingTo(String name) {
    return 'Povezivanje s $name…';
  }

  @override
  String get connected => 'Povezano';

  @override
  String get unsupportedOutput =>
      'Ovaj izvor nije moguće reproducirati na ovom izlazu.';

  @override
  String get airPlayAudioOutput => 'AirPlay i audioizlaz';

  @override
  String get returnForAirPlay =>
      'Reproducirajte na ovom uređaju za korištenje AirPlaya.';

  @override
  String get openSoundSettings => 'Otvorite postavke zvuka i odaberite izlaz.';

  @override
  String get soundSettingsError => 'Nije moguće otvoriti postavke zvuka.';

  @override
  String get systemOutput => 'Izlaz sustava';

  @override
  String playingOn(String name) {
    return 'Reprodukcija na $name';
  }

  @override
  String get chooseAirPlay =>
      'Dodirnite gumb AirPlay za odabir zvučnika ili televizora.';

  @override
  String get airPlayDevice => 'AirPlay uređaj';

  @override
  String get playOnIphone => 'Reproduciraj na ovom iPhoneu';

  @override
  String get chooseIphone =>
      'Odaberite ovaj iPhone pomoću gumba AirPlay u nastavku.';

  @override
  String get profile => 'Profil';

  @override
  String get preferences => 'Postavke';

  @override
  String get themeColor => 'Boja teme';

  @override
  String get yourMusic => 'Vaša glazba';

  @override
  String get apiCredentials => 'API pristupni podaci';

  @override
  String get dataStorage => 'Podaci i pohrana';

  @override
  String get editProfileHelp => 'Postavite ime i avatar';

  @override
  String get customProvider => 'Prilagođeni pružatelj';

  @override
  String get defaultProvider => 'Zadano za PPPlayer';

  @override
  String get proExperience => 'Pro iskustvo aktivno';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Učitavanje…';

  @override
  String get unknown => 'Nepoznato';

  @override
  String get pause => 'Pauza';

  @override
  String get repeat => 'Ponavljaj';

  @override
  String get mute => 'Isključi zvuk';

  @override
  String get unmute => 'Uključi zvuk';

  @override
  String get fitVideo => 'Prilagodi';

  @override
  String get fillVideo => 'Ispuni';

  @override
  String get fullscreen => 'Cijeli zaslon';

  @override
  String get exitFullscreen => 'Izađi iz cijelog zaslona';

  @override
  String get volume => 'Glasnoća';

  @override
  String get save => 'Spremi';

  @override
  String get delete => 'Izbriši';

  @override
  String get clear => 'Očisti';

  @override
  String get follow => 'Prati';

  @override
  String get unfollow => 'Prestani pratiti';

  @override
  String get following => 'Pratite';

  @override
  String get showAll => 'Prikaži sve';

  @override
  String get appearance => 'Izgled';

  @override
  String get subtitleSize => 'Veličina';

  @override
  String get subtitleBackground => 'Pozadina';

  @override
  String get earlier => 'Ranije';

  @override
  String get later => 'Kasnije';

  @override
  String get reset => 'Vrati na zadano';

  @override
  String subtitleDelay(String seconds) {
    return 'Odgoda: $seconds s';
  }

  @override
  String get morePlaybackControls => 'Više kontrola reprodukcije';

  @override
  String get hideVideo => 'Sakrij video';

  @override
  String get showVideo => 'Prikaži video';

  @override
  String get closeQueue => 'Zatvori red';

  @override
  String get enabled => 'Uključeno';

  @override
  String get openFile => 'Otvori datoteku…';

  @override
  String get openFolder => 'Otvori mapu…';

  @override
  String get openUrl => 'Otvori URL…';

  @override
  String get fileMenu => 'Datoteka';

  @override
  String get viewMenu => 'Prikaz';

  @override
  String get windowMenu => 'Prozor';

  @override
  String get saveChanges => 'Spremi promjene';

  @override
  String get themeAvatarColor => 'Boja teme i avatara';

  @override
  String get networkStreams => 'Mrežni tokovi';

  @override
  String get networkStream => 'Mrežni tok';

  @override
  String get openNetworkStream => 'Otvori mrežni tok';

  @override
  String get editPlaylist => 'Uredi popis za reprodukciju';

  @override
  String get editStreamItem => 'Uredi stavku toka';

  @override
  String get streamUrl => 'URL toka';

  @override
  String get platformType => 'Platforma / vrsta';

  @override
  String get optionalTitle => 'Naslov (neobavezno)';

  @override
  String get optionalImageUrl => 'URL slike (neobavezno)';

  @override
  String get myStream => 'Moj tok';

  @override
  String get saveToLibrary => 'Spremi u biblioteku';

  @override
  String get justPlay => 'Samo reproduciraj';

  @override
  String get autoDetect => 'Automatsko prepoznavanje';

  @override
  String get apiKeyRequired => 'Potreban je API ključ';

  @override
  String get customApiKey => 'Koristi vlastiti API ključ';

  @override
  String get clientId => 'ID klijenta';

  @override
  String get clientSecret => 'Tajna klijenta';

  @override
  String get saveCredentials => 'Spremi pristupne podatke';

  @override
  String get searchStrategy => 'Strategija pretraživanja';

  @override
  String get credentialsLocalOnly =>
      'Sigurno pohranjeni na ovom uređaju. Nikad se ne šalju PPPlayeru.';

  @override
  String get scrapingHelp =>
      'API ključ ni kvota nisu potrebni. Može biti sporije ili manje pouzdano.';

  @override
  String get streamHelp => 'Unesite HTTP(S) URL ili poveznicu na M3U popis.';

  @override
  String get deletePlaylistConfirm =>
      'Trajno izbrisati ovaj popis za reprodukciju?';

  @override
  String get clearCacheConfirm =>
      'Izbrisati predmemoriju? Biblioteka i omiljeni ostaju nepromijenjeni.';

  @override
  String get clearHistoryConfirm => 'Trajno izbrisati povijest slušanja?';

  @override
  String get addedToQueue => 'Dodano u red';

  @override
  String get addedVideo => 'Video dodan';

  @override
  String addedChannels(String count) {
    return 'Dodani kanali: $count';
  }

  @override
  String get removedFromPlaylist => 'Uklonjeno s popisa';

  @override
  String get exportCancelled => 'Izvoz otkazan';

  @override
  String exportComplete(String count) {
    return 'Popis izvezen. Preskočene stavke: $count';
  }

  @override
  String get playlistExported => 'Popis izvezen';

  @override
  String get live => 'Uživo';

  @override
  String get sponsored => 'Sponzorirano';

  @override
  String get removeFromPlaylist => 'Ukloni s popisa';

  @override
  String get likedSongsHelp => 'Spremite pjesme da ih vidite ovdje';

  @override
  String get apiSingleVideoHint =>
      'Ovaj video možete dodati bez uvoza popisa za reprodukciju.';

  @override
  String get linkCopied => 'Poveznica kopirana';

  @override
  String get willPlayNext => 'Reproducirat će se sljedeće';

  @override
  String get checkItOut => 'Pogledajte';

  @override
  String get loadFailed => 'Sadržaj se nije mogao učitati. Pokušajte ponovno.';
}
