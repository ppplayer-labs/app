// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

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
  String get artists => 'ARTISTI';

  @override
  String get artwork => 'COPERTINA';

  @override
  String get appVersion => 'Versione app';

  @override
  String get artist => 'Artista';

  @override
  String get artistsYouFollow => 'Artisti che segui';

  @override
  String get autoplay => 'Riproduzione automatica';

  @override
  String get becauseYouListenedTo => 'Perché hai ascoltato';

  @override
  String get browseAll => 'Sfoglia tutto';

  @override
  String get cancel => 'Annulla';

  @override
  String get clearAppCache => 'Svuotare la cache dell\'app?';

  @override
  String get clearCache => 'Svuota cache';

  @override
  String get clearHistory => 'Cancellare la cronologia?';

  @override
  String get clearRecentlyPlayed => 'Cancella ascoltati di recente';

  @override
  String get contentMarket => 'Mercato dei contenuti';

  @override
  String get continueListening => 'Continua ad ascoltare';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Continua la riproduzione video in una piccola finestra';

  @override
  String get create => 'Crea';

  @override
  String get createAPlaylistToGetStarted => 'Crea una playlist per iniziare';

  @override
  String currentSelectedcountry(Object country) {
    return 'Attuale: $country';
  }

  @override
  String get deletePlaylist => 'Elimina playlist';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Errore nel caricamento dei mercati: $err';
  }

  @override
  String error(Object error) {
    return 'Errore: $error';
  }

  @override
  String explore(Object genre) {
    return 'Esplora $genre';
  }

  @override
  String get fansAlsoLike => 'I FAN AMANO ANCHE';

  @override
  String featuringTouppercase(Object artist) {
    return 'CON $artist';
  }

  @override
  String get featuredPlaylists => 'Playlist in primo piano';

  @override
  String get followArtistsToSeeThemHere => 'Segui gli artisti per vederli qui';

  @override
  String get followStationsToSeeThemHere => 'Segui le stazioni per vederle qui';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Forza stream solo audio per risparmiare dati';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Libera spazio e forza dati freschi al prossimo caricamento';

  @override
  String get fromYourFavorites => 'Dai tuoi preferiti';

  @override
  String get goBack => 'Torna indietro';

  @override
  String inspiredByName(Object name) {
    return 'Ispirato da $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Continua a riprodurre brani simili quando la coda finisce';

  @override
  String get library => 'Libreria';

  @override
  String get likeAlbumsToSeeThemHere =>
      'Metti mi piace agli album per vederli qui';

  @override
  String get likedSongs => 'Brani che ti piacciono';

  @override
  String get lowDataMode => 'Modalità risparmio dati';

  @override
  String get madeForYou => 'Creato per te';

  @override
  String moreLikeName(Object name) {
    return 'Simile a $name';
  }

  @override
  String get moreOptions => 'Altre opzioni';

  @override
  String get nameYourMasterpiece => 'Dai un nome al tuo capolavoro...';

  @override
  String get newPlaylist => 'Nuova playlist';

  @override
  String get newReleases => 'Nuove uscite';

  @override
  String get next => 'Successivo';

  @override
  String get noAlbumsFound => 'Nessun album trovato';

  @override
  String get noArtistsFollowed => 'Nessun artista seguito';

  @override
  String get noArtistsFound => 'Nessun artista trovato';

  @override
  String get noLikedAlbums => 'Nessun album piaciuto';

  @override
  String get noPlaylistsFound => 'Nessuna playlist trovata';

  @override
  String get noPlaylistsYet => 'Nessuna playlist ancora';

  @override
  String get noResultsFound => 'Nessun risultato trovato';

  @override
  String get noStationsFollowed => 'Nessuna stazione seguita';

  @override
  String get noTrackPlaying => 'Nessun brano in riproduzione';

  @override
  String get noTracksFound => 'Nessun brano trovato';

  @override
  String get playlists => 'PLAYLIST';

  @override
  String get popular => 'POPOLARE';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Rimuovi permanentemente la cronologia di ascolto';

  @override
  String get pictureinpicturePip => 'Immagine nell\'immagine (PiP)';

  @override
  String get popularAlbums => 'Album popolari';

  @override
  String get popularArtists => 'Artisti popolari';

  @override
  String get popularGenres => 'Generi popolari';

  @override
  String get popularSongs => 'Brani popolari';

  @override
  String get popularTracks => 'Tracce popolari';

  @override
  String get popularHitsRightNow => 'Hit popolari al momento';

  @override
  String get previous => 'Precedente';

  @override
  String get queue => 'CODA';

  @override
  String get recentSearches => 'Ricerche recenti';

  @override
  String get recommendedForYou => 'Consigliato per te';

  @override
  String get scraping => 'Raschiatura';

  @override
  String get search => 'Cerca';

  @override
  String get searchInAlbum => 'Cerca nell\'album...';

  @override
  String get searchInLibrary => 'Cerca nella libreria...';

  @override
  String get searchInPlaylist => 'Cerca nella playlist';

  @override
  String get searchLikedSongs => 'Cerca nei brani piaciuti...';

  @override
  String get searchPopularSongs => 'Cerca brani popolari...';

  @override
  String get selectMarket => 'Seleziona mercato';

  @override
  String get settings => 'Impostazioni';

  @override
  String get showVideoPlayer => 'Mostra riproduttore video';

  @override
  String get shuffle => 'Riproduzione casuale';

  @override
  String get spotifyCredentials => 'Credenziali Spotify';

  @override
  String get suggestedStations => 'Stazioni suggerite';

  @override
  String get tracks => 'BRANI';

  @override
  String get trending => 'Tendenze';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get tryADifferentSearchTerm => 'Prova un termine di ricerca diverso';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Usa il player di YouTube quando disponibile';

  @override
  String get video => 'VIDEO';

  @override
  String get whatDoYouWantToListenTo => 'Cosa vuoi ascoltare?';

  @override
  String get youtubeCredentials => 'Credenziali YouTube';

  @override
  String get yourLibrary => 'La tua libreria';

  @override
  String get playerscreenviewswitch => 'cambia_vista_schermo_giocatore';

  @override
  String get addToPlaylist => 'Aggiungi alla playlist';

  @override
  String get addToQueue => 'Aggiungi alla coda';

  @override
  String get copyId => 'Copia ID';

  @override
  String get copyLink => 'Copia link';

  @override
  String get discover => 'Scopri';

  @override
  String get enterYourName => 'Inserisci il tuo nome';

  @override
  String get favorites => 'Preferiti';

  @override
  String get goToAlbum => 'Vai all\'album';

  @override
  String get goToArtist => 'Vai all\'artista';

  @override
  String get goToArtistRadio => 'Vai alla radio dell\'artista';

  @override
  String get goToPlaylist => 'Vai alla playlist';

  @override
  String get goToSongRadio => 'Vai alla radio del brano';

  @override
  String get home => 'Inizio';

  @override
  String get myAwesomePlaylist => 'La mia fantastica playlist';

  @override
  String get myPlaylist => 'La mia playlist';

  @override
  String get newPlaylist1 => 'Nuova playlist';

  @override
  String get play => 'Riproduci';

  @override
  String get playStation => 'Riproduci stazione';

  @override
  String get playNext => 'Riproduci successivo';

  @override
  String get playlist => 'Playlist';

  @override
  String get playlistName => 'Nome della playlist';

  @override
  String get playlists1 => 'Playlist';

  @override
  String get queue1 => 'Coda';

  @override
  String get recentlyPlayed => 'Ascoltati di recente';

  @override
  String get removeFromQueue => 'Rimuovi dalla coda';

  @override
  String get retry => 'Riprova';

  @override
  String get searchMusicArtistsAlbums => 'Cerca musica, artisti, album...';

  @override
  String get share => 'Condividi';

  @override
  String featuringArtist(String artistName) {
    return 'CON $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Attuale: $country';
  }

  @override
  String get queueTooltip => 'Coda';

  @override
  String get searchHint => 'Cerca musica, artisti, album...';

  @override
  String get language => 'Lingua';

  @override
  String get systemDefault => 'Predefinito di sistema';

  @override
  String get songsTab => 'Brani';

  @override
  String get foldersTab => 'Cartelle';

  @override
  String get artistsTab => 'Artisti';

  @override
  String get albumsTab => 'Album';

  @override
  String get genresTab => 'Generi';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Velocità di riproduzione';

  @override
  String get addMusic => 'Aggiungi musica';

  @override
  String get addFiles => 'Aggiungi file';

  @override
  String get addFolder => 'Aggiungi cartella';

  @override
  String get rescanLibrary => 'Riesamina libreria';

  @override
  String get sortTitle => 'Ordina per titolo';

  @override
  String get sortArtist => 'Ordina per artista';

  @override
  String get sortAlbum => 'Ordina per album';

  @override
  String get sortDuration => 'Ordina per durata';

  @override
  String get sortDateAdded => 'Ordina per data aggiunta';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get trackInformation => 'Informazioni brano';

  @override
  String get removeFromLibrary => 'Rimuovi dalla libreria';

  @override
  String get showInFolder => 'Mostra nella cartella';

  @override
  String get unknownArtist => 'Artista sconosciuto';

  @override
  String get unknownAlbum => 'Album sconosciuto';

  @override
  String get importedFiles => 'File importati';

  @override
  String get playFolder => 'Riproduci cartella';

  @override
  String get shuffleFolder => 'Riproduzione casuale cartella';

  @override
  String get playAll => 'Riproduci tutto';

  @override
  String get includeSubfolders => 'Includi sottocartelle';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
      zero: '0 brani',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Nessun brano locale trovato';

  @override
  String get searchLocalMusic => 'Cerca musica locale...';

  @override
  String get viewAsList => 'Visualizza come elenco';

  @override
  String get viewAsGrid => 'Visualizza come griglia';

  @override
  String get trackInfoPath => 'Percorso';

  @override
  String get trackInfoFormat => 'Formato';

  @override
  String get trackInfoDuration => 'Durata';

  @override
  String get aboutDescription =>
      'Un lettore multimediale gratuito e open source.';

  @override
  String get aboutApp => 'Informazioni su PPPlayer';

  @override
  String get appTagline => 'La tua musica. A modo tuo.';

  @override
  String get exploreApp => 'Esplora PPPlayer';

  @override
  String get viewSource => 'Visualizza codice sorgente';

  @override
  String get seeWhatsNew => 'Novità';

  @override
  String get getHelp => 'Ottieni assistenza';

  @override
  String versionInfo(Object version, Object build) {
    return 'Versione $version (Build $build)';
  }

  @override
  String get createdBy => 'Creato da Lucas Coelho';

  @override
  String get website => 'Sito web';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Note di rilascio';

  @override
  String get support => 'Supporto';

  @override
  String get license => 'Licenza';

  @override
  String get acknowledgments => 'Ringraziamenti';

  @override
  String get close => 'Chiudi';

  @override
  String copyright(Object year) {
    return '© $year Collaboratori di PPPlayer';
  }

  @override
  String get goodMorning => 'Buongiorno';

  @override
  String get goodAfternoon => 'Buon pomeriggio';

  @override
  String get goodEvening => 'Buonasera';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'La tua musica ti aspetta.';

  @override
  String dailyMix(Object number) {
    return 'Daily Mix $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'I tuoi preferiti\ne nuove scoperte';

  @override
  String get discoverWeekly => 'Discover Weekly';

  @override
  String get releaseRadar => 'Release Radar';

  @override
  String get newMusicJustForYou => 'Nuova musica\nsolo per te';

  @override
  String get chillMix => 'Chill Mix';

  @override
  String get relaxAndUnwind => 'Rilassati e stacca la spina';

  @override
  String get focusMix => 'Focus Mix';

  @override
  String get deepFocusAndProductivity =>
      'Concentrazione profonda\ne produttività';

  @override
  String artistRadio(Object artist) {
    return 'Radio $artist';
  }

  @override
  String genreRadio(Object genre) {
    return 'Radio $genre';
  }

  @override
  String get filterAll => 'Tutto';

  @override
  String get filterPlaylists => 'Playlist';

  @override
  String get filterArtists => 'Artisti';

  @override
  String get filterAlbums => 'Album';

  @override
  String get filterStations => 'Stazioni';

  @override
  String get filterStreams => 'Stream';

  @override
  String get localMusicCard => 'Musica locale';

  @override
  String get createPlaylistButton => 'Crea playlist';

  @override
  String get radioStations => 'Stazioni radio';

  @override
  String get discoverMusic => 'Scopri musica';

  @override
  String get importLocalMusic => 'Importa musica locale';

  @override
  String get importAudioFiles => 'Importa file audio';

  @override
  String get importFolder => 'Importa cartella';

  @override
  String get importFolderSubtitle =>
      'Scegli una cartella contenente file audio';

  @override
  String get importPlaylist => 'Importa playlist';

  @override
  String get importPlaylistSubtitle => 'Importa file .m3u o .m3u8';

  @override
  String get exportPlaylist => 'Esporta playlist';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Formato non supportato o file danneggiato';

  @override
  String get playbackErrorFileInaccessible =>
      'File inaccessibile o non trovato';

  @override
  String get localVideosCard => 'Video locali';

  @override
  String get noLocalVideos => 'Nessun video trovato';

  @override
  String get searchLocalVideos => 'Cerca video locali';

  @override
  String get addVideos => 'Aggiungi video';

  @override
  String get subtitles => 'Sottotitoli';

  @override
  String get audioTracks => 'Tracce audio';

  @override
  String get loadSubtitleFile => 'Carica file sottotitoli...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Errore durante il caricamento dei sottotitoli: $error';
  }

  @override
  String get off => 'Spento';

  @override
  String get playOn => 'Riproduci su';

  @override
  String get thisDevice => 'Questo dispositivo';

  @override
  String get availableDevices => 'Dispositivi disponibili';

  @override
  String get searchingDevices => 'Ricerca dispositivi…';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get connecting => 'Connessione…';

  @override
  String connectingTo(String name) {
    return 'Connessione a $name…';
  }

  @override
  String get connected => 'Connesso';

  @override
  String get unsupportedOutput =>
      'Questa sorgente non può essere riprodotta su questa uscita.';

  @override
  String get airPlayAudioOutput => 'AirPlay e uscita audio';

  @override
  String get returnForAirPlay =>
      'Riproduci su questo dispositivo per usare AirPlay.';

  @override
  String get openSoundSettings =>
      'Apri le impostazioni audio per scegliere un’uscita.';

  @override
  String get soundSettingsError => 'Impossibile aprire le impostazioni audio.';

  @override
  String get systemOutput => 'Uscita di sistema';

  @override
  String playingOn(String name) {
    return 'Riproduzione su $name';
  }

  @override
  String get chooseAirPlay =>
      'Tocca il pulsante AirPlay per scegliere un altoparlante o una TV.';

  @override
  String get airPlayDevice => 'Dispositivo AirPlay';

  @override
  String get playOnIphone => 'Riproduci su questo iPhone';

  @override
  String get chooseIphone =>
      'Scegli questo iPhone con il pulsante AirPlay qui sotto.';

  @override
  String get profile => 'Profilo';

  @override
  String get preferences => 'Preferenze';

  @override
  String get themeColor => 'Colore del tema';

  @override
  String get yourMusic => 'La tua musica';

  @override
  String get apiCredentials => 'Credenziali API';

  @override
  String get dataStorage => 'Dati e archiviazione';

  @override
  String get editProfileHelp => 'Imposta il tuo nome e avatar';

  @override
  String get customProvider => 'Provider personalizzato';

  @override
  String get defaultProvider => 'Predefinito PPPlayer';

  @override
  String get proExperience => 'Esperienza Pro attiva';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Caricamento…';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get pause => 'Pausa';

  @override
  String get repeat => 'Ripeti';

  @override
  String get mute => 'Disattiva audio';

  @override
  String get unmute => 'Attiva audio';

  @override
  String get fitVideo => 'Adatta';

  @override
  String get fillVideo => 'Riempi';

  @override
  String get fullscreen => 'Schermo intero';

  @override
  String get exitFullscreen => 'Esci dallo schermo intero';

  @override
  String get volume => 'Volume';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get clear => 'Cancella';

  @override
  String get follow => 'Segui';

  @override
  String get unfollow => 'Non seguire più';

  @override
  String get following => 'Seguito';

  @override
  String get showAll => 'Mostra tutto';

  @override
  String get appearance => 'Aspetto';

  @override
  String get subtitleSize => 'Dimensione';

  @override
  String get subtitleBackground => 'Sfondo';

  @override
  String get earlier => 'Prima';

  @override
  String get later => 'Dopo';

  @override
  String get reset => 'Ripristina';

  @override
  String subtitleDelay(String seconds) {
    return 'Ritardo: $seconds s';
  }

  @override
  String get morePlaybackControls => 'Altri controlli di riproduzione';

  @override
  String get hideVideo => 'Nascondi video';

  @override
  String get showVideo => 'Mostra video';

  @override
  String get closeQueue => 'Chiudi coda';

  @override
  String get enabled => 'Attivo';

  @override
  String get openFile => 'Apri file…';

  @override
  String get openFolder => 'Apri cartella…';

  @override
  String get openUrl => 'Apri URL…';

  @override
  String get fileMenu => 'File';

  @override
  String get viewMenu => 'Visualizza';

  @override
  String get windowMenu => 'Finestra';

  @override
  String get saveChanges => 'Salva modifiche';

  @override
  String get themeAvatarColor => 'Colore del tema e dell’avatar';

  @override
  String get networkStreams => 'Stream di rete';

  @override
  String get networkStream => 'Stream di rete';

  @override
  String get openNetworkStream => 'Apri stream di rete';

  @override
  String get editPlaylist => 'Modifica playlist';

  @override
  String get editStreamItem => 'Modifica elemento dello stream';

  @override
  String get streamUrl => 'URL dello stream';

  @override
  String get platformType => 'Piattaforma / tipo';

  @override
  String get optionalTitle => 'Titolo (facoltativo)';

  @override
  String get optionalImageUrl => 'URL immagine (facoltativo)';

  @override
  String get myStream => 'Il mio stream';

  @override
  String get saveToLibrary => 'Salva nella libreria';

  @override
  String get justPlay => 'Riproduci soltanto';

  @override
  String get autoDetect => 'Rileva automaticamente';

  @override
  String get apiKeyRequired => 'Chiave API richiesta';

  @override
  String get customApiKey => 'Usa chiave API personalizzata';

  @override
  String get clientId => 'ID client';

  @override
  String get clientSecret => 'Segreto client';

  @override
  String get saveCredentials => 'Salva credenziali';

  @override
  String get searchStrategy => 'Strategia di ricerca';

  @override
  String get credentialsLocalOnly =>
      'Conservate in modo sicuro su questo dispositivo. Mai inviate a PPPlayer.';

  @override
  String get scrapingHelp =>
      'Non richiede chiave API o quota. Può essere più lento o meno affidabile.';

  @override
  String get streamHelp =>
      'Inserisci un URL HTTP(S) o un link a una playlist M3U.';

  @override
  String get deletePlaylistConfirm =>
      'Eliminare definitivamente questa playlist?';

  @override
  String get clearCacheConfirm =>
      'Eliminare i dati in cache? Libreria e preferiti restano invariati.';

  @override
  String get clearHistoryConfirm =>
      'Eliminare definitivamente la cronologia di ascolto?';

  @override
  String get addedToQueue => 'Aggiunto alla coda';

  @override
  String get addedVideo => 'Video aggiunto';

  @override
  String addedChannels(String count) {
    return 'Canali aggiunti: $count';
  }

  @override
  String get removedFromPlaylist => 'Rimosso dalla playlist';

  @override
  String get exportCancelled => 'Esportazione annullata';

  @override
  String exportComplete(String count) {
    return 'Playlist esportata. Elementi saltati: $count';
  }

  @override
  String get playlistExported => 'Playlist esportata';

  @override
  String get live => 'In diretta';

  @override
  String get sponsored => 'Sponsorizzato';

  @override
  String get removeFromPlaylist => 'Rimuovi dalla playlist';

  @override
  String get likedSongsHelp => 'Salva brani per vederli qui';

  @override
  String get apiSingleVideoHint =>
      'Puoi aggiungere questo video senza importare la playlist.';

  @override
  String get linkCopied => 'Link copiato';

  @override
  String get willPlayNext => 'Verrà riprodotto dopo';

  @override
  String get checkItOut => 'Scopri';

  @override
  String get loadFailed => 'Impossibile caricare il contenuto. Riprova.';
}
