// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'ALBEN';

  @override
  String get api => 'API';

  @override
  String get artists => 'KÜNSTLER';

  @override
  String get artwork => 'COVER';

  @override
  String get appVersion => 'App-Version';

  @override
  String get artist => 'Künstler';

  @override
  String get artistsYouFollow => 'Künstler, denen du folgst';

  @override
  String get autoplay => 'Autoplay';

  @override
  String get becauseYouListenedTo => 'Weil du gehört hast';

  @override
  String get browseAll => 'Alles durchsuchen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get clearAppCache => 'App-Cache leeren?';

  @override
  String get clearCache => 'Cache leeren';

  @override
  String get clearHistory => 'Verlauf löschen?';

  @override
  String get clearRecentlyPlayed => 'Zuletzt Gehörtes löschen';

  @override
  String get contentMarket => 'Inhaltsmarkt';

  @override
  String get continueListening => 'Weiterhören';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Videowiedergabe in kleinem Fenster fortsetzen';

  @override
  String get create => 'Erstellen';

  @override
  String get createAPlaylistToGetStarted =>
      'Erstelle eine Playlist, um zu beginnen';

  @override
  String currentSelectedcountry(Object country) {
    return 'Aktuell: $country';
  }

  @override
  String get deletePlaylist => 'Playlist löschen';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Fehler beim Laden der Märkte: $err';
  }

  @override
  String error(Object error) {
    return 'Fehler: $error';
  }

  @override
  String explore(Object genre) {
    return '$genre entdecken';
  }

  @override
  String get fansAlsoLike => 'FANS MÖGEN AUCH';

  @override
  String featuringTouppercase(Object artist) {
    return 'MIT $artist';
  }

  @override
  String get featuredPlaylists => 'Ausgewählte Playlists';

  @override
  String get followArtistsToSeeThemHere =>
      'Folge Künstlern, um sie hier zu sehen';

  @override
  String get followStationsToSeeThemHere =>
      'Folge Sendern, um sie hier zu sehen';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Nur Audio streamen, um Daten zu sparen';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Gibt Speicherplatz frei und lädt beim nächsten Start neue Daten';

  @override
  String get fromYourFavorites => 'Aus deinen Favoriten';

  @override
  String get goBack => 'Zurück';

  @override
  String inspiredByName(Object name) {
    return 'Inspiriert von $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Ähnliche Titel weiter abspielen, wenn Warteschlange endet';

  @override
  String get library => 'Bibliothek';

  @override
  String get likeAlbumsToSeeThemHere => 'Like Alben, um sie hier zu sehen';

  @override
  String get likedSongs => 'Lieblingssongs';

  @override
  String get lowDataMode => 'Datensparmodus';

  @override
  String get madeForYou => 'Für dich gemacht';

  @override
  String moreLikeName(Object name) {
    return 'Mehr wie $name';
  }

  @override
  String get moreOptions => 'Mehr Optionen';

  @override
  String get nameYourMasterpiece => 'Benenne dein Meisterwerk...';

  @override
  String get newPlaylist => 'Neue Playlist';

  @override
  String get newReleases => 'Neuerscheinungen';

  @override
  String get next => 'Weiter';

  @override
  String get noAlbumsFound => 'Keine Alben gefunden';

  @override
  String get noArtistsFollowed => 'Keinen Künstlern gefolgt';

  @override
  String get noArtistsFound => 'Keine Künstler gefunden';

  @override
  String get noLikedAlbums => 'Keine gelikten Alben';

  @override
  String get noPlaylistsFound => 'Keine Playlists gefunden';

  @override
  String get noPlaylistsYet => 'Noch keine Playlists';

  @override
  String get noResultsFound => 'Keine Ergebnisse gefunden';

  @override
  String get noStationsFollowed => 'Keinen Sendern gefolgt';

  @override
  String get noTrackPlaying => 'Kein Titel wird abgespielt';

  @override
  String get noTracksFound => 'Keine Titel gefunden';

  @override
  String get playlists => 'PLAYLISTS';

  @override
  String get popular => 'BELIEBT';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Hörverlauf dauerhaft entfernen';

  @override
  String get pictureinpicturePip => 'Bild-in-Bild (PiP)';

  @override
  String get popularAlbums => 'Beliebte Alben';

  @override
  String get popularArtists => 'Beliebte Künstler';

  @override
  String get popularGenres => 'Beliebte Genres';

  @override
  String get popularSongs => 'Beliebte Songs';

  @override
  String get popularTracks => 'Beliebte Titel';

  @override
  String get popularHitsRightNow => 'Beliebte Hits derzeit';

  @override
  String get previous => 'Zurück';

  @override
  String get queue => 'WARTESCHLANGE';

  @override
  String get recentSearches => 'Letzte Suchen';

  @override
  String get recommendedForYou => 'Für dich empfohlen';

  @override
  String get scraping => 'Scraping läuft';

  @override
  String get search => 'Suchen';

  @override
  String get searchInAlbum => 'Im Album suchen...';

  @override
  String get searchInLibrary => 'In Bibliothek suchen...';

  @override
  String get searchInPlaylist => 'In Playlist suchen';

  @override
  String get searchLikedSongs => 'Lieblingssongs suchen...';

  @override
  String get searchPopularSongs => 'Beliebte Songs suchen...';

  @override
  String get selectMarket => 'Markt auswählen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get showVideoPlayer => 'Videoplayer anzeigen';

  @override
  String get shuffle => 'Zufallswiedergabe';

  @override
  String get spotifyCredentials => 'Spotify Zugangsdaten';

  @override
  String get suggestedStations => 'Vorgeschlagene Sender';

  @override
  String get tracks => 'TITEL';

  @override
  String get trending => 'Im Trend';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get tryADifferentSearchTerm => 'Versuche einen anderen Suchbegriff';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'YouTube Player nutzen, wenn verfügbar';

  @override
  String get video => 'VIDEO';

  @override
  String get whatDoYouWantToListenTo => 'Was möchtest du hören?';

  @override
  String get youtubeCredentials => 'YouTube Zugangsdaten';

  @override
  String get yourLibrary => 'Deine Bibliothek';

  @override
  String get playerscreenviewswitch => 'spieler_bildschirm_ansicht_wechseln';

  @override
  String get addToPlaylist => 'Zur Playlist hinzufügen';

  @override
  String get addToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String get copyId => 'ID kopieren';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get discover => 'Entdecken';

  @override
  String get enterYourName => 'Gib deinen Namen ein';

  @override
  String get favorites => 'Favoriten';

  @override
  String get goToAlbum => 'Zum Album';

  @override
  String get goToArtist => 'Zum Künstler';

  @override
  String get goToArtistRadio => 'Zum Künstlerradio';

  @override
  String get goToPlaylist => 'Zur Playlist';

  @override
  String get goToSongRadio => 'Zum Songradio';

  @override
  String get home => 'Start';

  @override
  String get myAwesomePlaylist => 'Meine tolle Playlist';

  @override
  String get myPlaylist => 'Meine Playlist';

  @override
  String get newPlaylist1 => 'Neue Playlist';

  @override
  String get play => 'Abspielen';

  @override
  String get playStation => 'Sender abspielen';

  @override
  String get playNext => 'Als Nächstes abspielen';

  @override
  String get playlist => 'Playlist';

  @override
  String get playlistName => 'Playlist-Name';

  @override
  String get playlists1 => 'Wiedergabelisten';

  @override
  String get queue1 => 'Warteschlange';

  @override
  String get recentlyPlayed => 'Zuletzt gespielt';

  @override
  String get removeFromQueue => 'Aus Warteschlange entfernen';

  @override
  String get retry => 'Wiederholen';

  @override
  String get searchMusicArtistsAlbums => 'Musik, Künstler, Alben suchen...';

  @override
  String get share => 'Teilen';

  @override
  String featuringArtist(String artistName) {
    return 'MIT $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Aktuell: $country';
  }

  @override
  String get queueTooltip => 'Warteschlange';

  @override
  String get searchHint => 'Musik, Künstler, Alben suchen...';

  @override
  String get language => 'Sprache';

  @override
  String get systemDefault => 'Systemvorgabe';

  @override
  String get songsTab => 'Lieder';

  @override
  String get foldersTab => 'Ordner';

  @override
  String get artistsTab => 'Künstler';

  @override
  String get albumsTab => 'Alben';

  @override
  String get genresTab => 'Genres';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Wiedergabegeschwindigkeit';

  @override
  String get addMusic => 'Musik hinzufügen';

  @override
  String get addFiles => 'Dateien hinzufügen';

  @override
  String get addFolder => 'Ordner hinzufügen';

  @override
  String get rescanLibrary => 'Bibliothek neu scannen';

  @override
  String get sortTitle => 'Nach Titel sortieren';

  @override
  String get sortArtist => 'Nach Künstler sortieren';

  @override
  String get sortAlbum => 'Nach Album sortieren';

  @override
  String get sortDuration => 'Nach Dauer sortieren';

  @override
  String get sortDateAdded => 'Nach Hinzufügedatum sortieren';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get trackInformation => 'Titelinformationen';

  @override
  String get removeFromLibrary => 'Aus Bibliothek entfernen';

  @override
  String get showInFolder => 'Im Ordner anzeigen';

  @override
  String get unknownArtist => 'Unbekannter Künstler';

  @override
  String get unknownAlbum => 'Unbekanntes Album';

  @override
  String get importedFiles => 'Importierte Dateien';

  @override
  String get playFolder => 'Ordner abspielen';

  @override
  String get shuffleFolder => 'Ordner zufällig abspielen';

  @override
  String get playAll => 'Alle abspielen';

  @override
  String get includeSubfolders => 'Unterordner einschließen';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
      zero: '0 Titel',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Keine lokalen Lieder gefunden';

  @override
  String get searchLocalMusic => 'Lokale Musik suchen...';

  @override
  String get viewAsList => 'Als Liste anzeigen';

  @override
  String get viewAsGrid => 'Als Raster anzeigen';

  @override
  String get trackInfoPath => 'Pfad';

  @override
  String get trackInfoFormat => 'Format';

  @override
  String get trackInfoDuration => 'Dauer';

  @override
  String get aboutDescription => 'Ein kostenloser, quelloffener Mediaplayer.';

  @override
  String get aboutApp => 'Über PPPlayer';

  @override
  String get appTagline => 'Deine Musik. Auf deine Weise.';

  @override
  String get exploreApp => 'PPPlayer erkunden';

  @override
  String get viewSource => 'Quellcode anzeigen';

  @override
  String get seeWhatsNew => 'Was ist neu';

  @override
  String get getHelp => 'Hilfe erhalten';

  @override
  String versionInfo(Object version, Object build) {
    return 'Version $version (Build $build)';
  }

  @override
  String get createdBy => 'Erstellt von Lucas Coelho';

  @override
  String get website => 'Webseite';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Versionshinweise';

  @override
  String get support => 'Unterstützung';

  @override
  String get license => 'Lizenz';

  @override
  String get acknowledgments => 'Danksagungen';

  @override
  String get close => 'Schließen';

  @override
  String copyright(Object year) {
    return '© $year PPPlayer Mitwirkende';
  }

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodAfternoon => 'Guten Tag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Deine Musik wartet.';

  @override
  String dailyMix(Object number) {
    return 'Daily Mix $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'Deine Favoriten\nund neue Entdeckungen';

  @override
  String get discoverWeekly => 'Mix der Woche';

  @override
  String get releaseRadar => 'Release Radar';

  @override
  String get newMusicJustForYou => 'Neue Musik\nnur für dich';

  @override
  String get chillMix => 'Chill Mix';

  @override
  String get relaxAndUnwind => 'Entspannen und abschalten';

  @override
  String get focusMix => 'Focus Mix';

  @override
  String get deepFocusAndProductivity => 'Tiefer Fokus\nund Produktivität';

  @override
  String artistRadio(Object artist) {
    return '$artist Radio';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre Radio';
  }

  @override
  String get filterAll => 'Alle';

  @override
  String get filterPlaylists => 'Playlists';

  @override
  String get filterArtists => 'Künstler';

  @override
  String get filterAlbums => 'Alben';

  @override
  String get filterStations => 'Sender';

  @override
  String get filterStreams => 'Streams';

  @override
  String get localMusicCard => 'Lokale Musik';

  @override
  String get createPlaylistButton => 'Playlist erstellen';

  @override
  String get radioStations => 'Radiosender';

  @override
  String get discoverMusic => 'Musik entdecken';

  @override
  String get importLocalMusic => 'Lokale Musik importieren';

  @override
  String get importAudioFiles => 'Audiodateien importieren';

  @override
  String get importFolder => 'Ordner importieren';

  @override
  String get importFolderSubtitle => 'Wählen Sie einen Ordner mit Audiodateien';

  @override
  String get importPlaylist => 'Wiedergabeliste importieren';

  @override
  String get importPlaylistSubtitle => '.m3u oder .m3u8 Datei importieren';

  @override
  String get exportPlaylist => 'Wiedergabeliste exportieren';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Nicht unterstütztes Format oder beschädigte Datei';

  @override
  String get playbackErrorFileInaccessible =>
      'Datei unzugänglich oder nicht gefunden';

  @override
  String get localVideosCard => 'Lokale Videos';

  @override
  String get noLocalVideos => 'Keine Videos gefunden';

  @override
  String get searchLocalVideos => 'Lokale Videos durchsuchen';

  @override
  String get addVideos => 'Videos hinzufügen';

  @override
  String get subtitles => 'Untertitel';

  @override
  String get audioTracks => 'Audiospuren';

  @override
  String get loadSubtitleFile => 'Untertiteldatei laden...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Fehler beim Laden des Untertitels: $error';
  }

  @override
  String get off => 'Aus';

  @override
  String get playOn => 'Wiedergeben auf';

  @override
  String get thisDevice => 'Dieses Gerät';

  @override
  String get availableDevices => 'Verfügbare Geräte';

  @override
  String get searchingDevices => 'Geräte werden gesucht…';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get connecting => 'Verbindung wird hergestellt…';

  @override
  String connectingTo(String name) {
    return 'Verbindung mit $name wird hergestellt…';
  }

  @override
  String get connected => 'Verbunden';

  @override
  String get unsupportedOutput =>
      'Diese Quelle kann auf diesem Gerät nicht wiedergegeben werden.';

  @override
  String get airPlayAudioOutput => 'AirPlay und Audioausgabe';

  @override
  String get returnForAirPlay => 'Für AirPlay auf diesem Gerät wiedergeben.';

  @override
  String get openSoundSettings =>
      'Öffne die Toneinstellungen, um eine Ausgabe auszuwählen.';

  @override
  String get soundSettingsError =>
      'Die Toneinstellungen konnten nicht geöffnet werden.';

  @override
  String get systemOutput => 'Systemausgabe';

  @override
  String playingOn(String name) {
    return 'Wiedergabe auf $name';
  }

  @override
  String get chooseAirPlay =>
      'Tippe auf die AirPlay-Taste, um einen Lautsprecher oder Fernseher auszuwählen.';

  @override
  String get airPlayDevice => 'AirPlay-Gerät';

  @override
  String get playOnIphone => 'Auf diesem iPhone wiedergeben';

  @override
  String get chooseIphone =>
      'Wähle dieses iPhone mit der AirPlay-Taste unten aus.';

  @override
  String get profile => 'Profil';

  @override
  String get preferences => 'Einstellungen';

  @override
  String get themeColor => 'Designfarbe';

  @override
  String get yourMusic => 'Deine Musik';

  @override
  String get apiCredentials => 'API-Zugangsdaten';

  @override
  String get dataStorage => 'Daten und Speicher';

  @override
  String get editProfileHelp => 'Lege deinen Namen und Avatar fest';

  @override
  String get customProvider => 'Eigener Anbieter';

  @override
  String get defaultProvider => 'PPPlayer-Standard';

  @override
  String get proExperience => 'Pro-Erlebnis aktiv';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Wird geladen…';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get pause => 'Pause';

  @override
  String get repeat => 'Wiederholen';

  @override
  String get mute => 'Stummschalten';

  @override
  String get unmute => 'Ton einschalten';

  @override
  String get fitVideo => 'Einpassen';

  @override
  String get fillVideo => 'Ausfüllen';

  @override
  String get fullscreen => 'Vollbild';

  @override
  String get exitFullscreen => 'Vollbild verlassen';

  @override
  String get volume => 'Lautstärke';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get clear => 'Leeren';

  @override
  String get follow => 'Folgen';

  @override
  String get unfollow => 'Nicht mehr folgen';

  @override
  String get following => 'Gefolgt';

  @override
  String get showAll => 'Alle anzeigen';

  @override
  String get appearance => 'Darstellung';

  @override
  String get subtitleSize => 'Größe';

  @override
  String get subtitleBackground => 'Hintergrund';

  @override
  String get earlier => 'Früher';

  @override
  String get later => 'Später';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String subtitleDelay(String seconds) {
    return 'Verzögerung: $seconds s';
  }

  @override
  String get morePlaybackControls => 'Weitere Wiedergabesteuerungen';

  @override
  String get hideVideo => 'Video ausblenden';

  @override
  String get showVideo => 'Video anzeigen';

  @override
  String get closeQueue => 'Warteschlange schließen';

  @override
  String get enabled => 'Ein';

  @override
  String get openFile => 'Datei öffnen…';

  @override
  String get openFolder => 'Ordner öffnen…';

  @override
  String get openUrl => 'URL öffnen…';

  @override
  String get fileMenu => 'Datei';

  @override
  String get viewMenu => 'Ansicht';

  @override
  String get windowMenu => 'Fenster';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get themeAvatarColor => 'Design- und Avatarfarbe';

  @override
  String get networkStreams => 'Netzwerkstreams';

  @override
  String get networkStream => 'Netzwerkstream';

  @override
  String get openNetworkStream => 'Netzwerkstream öffnen';

  @override
  String get editPlaylist => 'Playlist bearbeiten';

  @override
  String get editStreamItem => 'Streameintrag bearbeiten';

  @override
  String get streamUrl => 'Stream-URL';

  @override
  String get platformType => 'Plattform / Typ';

  @override
  String get optionalTitle => 'Titel (optional)';

  @override
  String get optionalImageUrl => 'Bild-URL (optional)';

  @override
  String get myStream => 'Mein Stream';

  @override
  String get saveToLibrary => 'In Bibliothek speichern';

  @override
  String get justPlay => 'Nur wiedergeben';

  @override
  String get autoDetect => 'Automatisch erkennen';

  @override
  String get apiKeyRequired => 'API-Schlüssel erforderlich';

  @override
  String get customApiKey => 'Eigenen API-Schlüssel verwenden';

  @override
  String get clientId => 'Client-ID';

  @override
  String get clientSecret => 'Client-Geheimnis';

  @override
  String get saveCredentials => 'Zugangsdaten speichern';

  @override
  String get searchStrategy => 'Suchstrategie';

  @override
  String get credentialsLocalOnly =>
      'Sicher auf diesem Gerät gespeichert. Wird nie an PPPlayer gesendet.';

  @override
  String get scrapingHelp =>
      'Kein API-Schlüssel oder Kontingent nötig. Kann langsamer oder weniger zuverlässig sein.';

  @override
  String get streamHelp =>
      'Gib eine HTTP(S)-URL oder einen M3U-Playlist-Link ein.';

  @override
  String get deletePlaylistConfirm => 'Diese Playlist endgültig löschen?';

  @override
  String get clearCacheConfirm =>
      'Zwischengespeicherte Daten löschen? Bibliothek und Favoriten bleiben unverändert.';

  @override
  String get clearHistoryConfirm => 'Deinen Hörverlauf endgültig löschen?';

  @override
  String get addedToQueue => 'Zur Warteschlange hinzugefügt';

  @override
  String get addedVideo => 'Video hinzugefügt';

  @override
  String addedChannels(String count) {
    return 'Hinzugefügte Kanäle: $count';
  }

  @override
  String get removedFromPlaylist => 'Aus der Playlist entfernt';

  @override
  String get exportCancelled => 'Export abgebrochen';

  @override
  String exportComplete(String count) {
    return 'Playlist exportiert. Übersprungene Einträge: $count';
  }

  @override
  String get playlistExported => 'Playlist exportiert';

  @override
  String get live => 'Live';

  @override
  String get sponsored => 'Gesponsert';

  @override
  String get removeFromPlaylist => 'Aus Playlist entfernen';

  @override
  String get likedSongsHelp => 'Speichere Songs, um sie hier zu sehen';

  @override
  String get apiSingleVideoHint =>
      'Du kannst dieses Video hinzufügen, ohne die Playlist zu importieren.';

  @override
  String get linkCopied => 'Link kopiert';

  @override
  String get willPlayNext => 'Wird als Nächstes abgespielt';

  @override
  String get checkItOut => 'Ansehen';

  @override
  String get loadFailed =>
      'Der Inhalt konnte nicht geladen werden. Versuche es erneut.';
}
