// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'ALBUMS';

  @override
  String get api => 'API';

  @override
  String get artists => 'ARTISTES';

  @override
  String get artwork => 'POCHETTE';

  @override
  String get appVersion => 'Version de l\'application';

  @override
  String get artist => 'Artiste';

  @override
  String get artistsYouFollow => 'Artistes que vous suivez';

  @override
  String get autoplay => 'Lecture automatique';

  @override
  String get becauseYouListenedTo => 'Parce que vous avez écouté';

  @override
  String get browseAll => 'Tout parcourir';

  @override
  String get cancel => 'Annuler';

  @override
  String get clearAppCache => 'Effacer le cache de l\'application ?';

  @override
  String get clearCache => 'Effacer le cache';

  @override
  String get clearHistory => 'Effacer l\'historique ?';

  @override
  String get clearRecentlyPlayed => 'Effacer les écoutes récentes';

  @override
  String get contentMarket => 'Marché du contenu';

  @override
  String get continueListening => 'Continuer l\'écoute';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Continuer la lecture vidéo dans une petite fenêtre';

  @override
  String get create => 'Créer';

  @override
  String get createAPlaylistToGetStarted => 'Créez une playlist pour commencer';

  @override
  String currentSelectedcountry(Object country) {
    return 'Actuel : $country';
  }

  @override
  String get deletePlaylist => 'Supprimer la playlist';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Erreur lors du chargement des marchés : $err';
  }

  @override
  String error(Object error) {
    return 'Erreur : $error';
  }

  @override
  String explore(Object genre) {
    return 'Explorer $genre';
  }

  @override
  String get fansAlsoLike => 'LES FANS AIMENT AUSSI';

  @override
  String featuringTouppercase(Object artist) {
    return 'AVEC $artist';
  }

  @override
  String get featuredPlaylists => 'Playlists en vedette';

  @override
  String get followArtistsToSeeThemHere =>
      'Suivez des artistes pour les voir ici';

  @override
  String get followStationsToSeeThemHere =>
      'Suivez des stations pour les voir ici';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Forcer les flux audio uniquement pour économiser les données';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Libère de l\'espace et force les nouvelles données au prochain chargement';

  @override
  String get fromYourFavorites => 'De vos favoris';

  @override
  String get goBack => 'Retour';

  @override
  String inspiredByName(Object name) {
    return 'Inspiré par $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Continuer à lire des titres similaires à la fin de la file d\'attente';

  @override
  String get library => 'Bibliothèque';

  @override
  String get likeAlbumsToSeeThemHere => 'Aimez des albums pour les voir ici';

  @override
  String get likedSongs => 'Titres likés';

  @override
  String get lowDataMode => 'Mode économie de données';

  @override
  String get madeForYou => 'Fait pour vous';

  @override
  String moreLikeName(Object name) {
    return 'Plus comme $name';
  }

  @override
  String get moreOptions => 'Plus d\'options';

  @override
  String get nameYourMasterpiece => 'Nommez votre chef-d\'œuvre...';

  @override
  String get newPlaylist => 'Nouvelle playlist';

  @override
  String get newReleases => 'Nouvelles sorties';

  @override
  String get next => 'Suivant';

  @override
  String get noAlbumsFound => 'Aucun album trouvé';

  @override
  String get noArtistsFollowed => 'Aucun artiste suivi';

  @override
  String get noArtistsFound => 'Aucun artiste trouvé';

  @override
  String get noLikedAlbums => 'Aucun album liké';

  @override
  String get noPlaylistsFound => 'Aucune playlist trouvée';

  @override
  String get noPlaylistsYet => 'Pas encore de playlist';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get noStationsFollowed => 'Aucune station suivie';

  @override
  String get noTrackPlaying => 'Aucun titre en cours de lecture';

  @override
  String get noTracksFound => 'Aucun titre trouvé';

  @override
  String get playlists => 'LISTES DE LECTURE';

  @override
  String get popular => 'POPULAIRE';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Supprimer définitivement l\'historique d\'écoute';

  @override
  String get pictureinpicturePip => 'Image dans l\'image (PiP)';

  @override
  String get popularAlbums => 'Albums populaires';

  @override
  String get popularArtists => 'Artistes populaires';

  @override
  String get popularGenres => 'Genres populaires';

  @override
  String get popularSongs => 'Chansons populaires';

  @override
  String get popularTracks => 'Titres populaires';

  @override
  String get popularHitsRightNow => 'Hits populaires du moment';

  @override
  String get previous => 'Précédent';

  @override
  String get queue => 'FILE D\'ATTENTE';

  @override
  String get recentSearches => 'Recherches récentes';

  @override
  String get recommendedForYou => 'Recommandé pour vous';

  @override
  String get scraping => 'Récupération en cours';

  @override
  String get search => 'Rechercher';

  @override
  String get searchInAlbum => 'Rechercher dans l\'album...';

  @override
  String get searchInLibrary => 'Rechercher dans la bibliothèque...';

  @override
  String get searchInPlaylist => 'Rechercher dans la playlist';

  @override
  String get searchLikedSongs => 'Rechercher dans les titres likés...';

  @override
  String get searchPopularSongs => 'Rechercher des chansons populaires...';

  @override
  String get selectMarket => 'Sélectionner le marché';

  @override
  String get settings => 'Paramètres';

  @override
  String get showVideoPlayer => 'Afficher le lecteur vidéo';

  @override
  String get shuffle => 'Aléatoire';

  @override
  String get spotifyCredentials => 'Identifiants Spotify';

  @override
  String get suggestedStations => 'Stations suggérées';

  @override
  String get tracks => 'TITRES';

  @override
  String get trending => 'Tendances';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get tryADifferentSearchTerm => 'Essayez un autre terme de recherche';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Utiliser le lecteur YouTube si disponible';

  @override
  String get video => 'VIDÉO';

  @override
  String get whatDoYouWantToListenTo => 'Que voulez-vous écouter ?';

  @override
  String get youtubeCredentials => 'Identifiants YouTube';

  @override
  String get yourLibrary => 'Votre bibliothèque';

  @override
  String get playerscreenviewswitch => 'basculer_vue_ecran_joueur';

  @override
  String get addToPlaylist => 'Ajouter à la playlist';

  @override
  String get addToQueue => 'Ajouter à la file d\'attente';

  @override
  String get copyId => 'Copier l\'ID';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get discover => 'Découvrir';

  @override
  String get enterYourName => 'Entrez votre nom';

  @override
  String get favorites => 'Favoris';

  @override
  String get goToAlbum => 'Aller à l\'album';

  @override
  String get goToArtist => 'Aller à l\'artiste';

  @override
  String get goToArtistRadio => 'Aller à la radio de l\'artiste';

  @override
  String get goToPlaylist => 'Aller à la playlist';

  @override
  String get goToSongRadio => 'Aller à la radio de la chanson';

  @override
  String get home => 'Accueil';

  @override
  String get myAwesomePlaylist => 'Ma super playlist';

  @override
  String get myPlaylist => 'Ma playlist';

  @override
  String get newPlaylist1 => 'Nouvelle playlist';

  @override
  String get play => 'Lecture';

  @override
  String get playStation => 'Lire la station';

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get playlist => 'Playlist';

  @override
  String get playlistName => 'Nom de la playlist';

  @override
  String get playlists1 => 'Listes de lecture';

  @override
  String get queue1 => 'File d\'attente';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueUpNext => 'Up next';

  @override
  String get recentlyPlayed => 'Écoutés récemment';

  @override
  String get removeFromQueue => 'Retirer de la file';

  @override
  String get retry => 'Réessayer';

  @override
  String get searchMusicArtistsAlbums =>
      'Rechercher musique, artistes, albums...';

  @override
  String get share => 'Partager';

  @override
  String featuringArtist(String artistName) {
    return 'AVEC $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Actuel: $country';
  }

  @override
  String get queueTooltip => 'File d\'attente';

  @override
  String get searchHint =>
      'Rechercher de la musique, des artistes, des albums...';

  @override
  String get language => 'Langue';

  @override
  String get systemDefault => 'Par défaut du système';

  @override
  String get songsTab => 'Chansons';

  @override
  String get foldersTab => 'Dossiers';

  @override
  String get artistsTab => 'Artistes';

  @override
  String get albumsTab => 'Albums';

  @override
  String get genresTab => 'Genres';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String get addMusic => 'Ajouter de la musique';

  @override
  String get addFiles => 'Ajouter des fichiers';

  @override
  String get addFolder => 'Ajouter un dossier';

  @override
  String get rescanLibrary => 'Réanalyser la bibliothèque';

  @override
  String get sortTitle => 'Trier par titre';

  @override
  String get sortArtist => 'Trier par artiste';

  @override
  String get sortAlbum => 'Trier par album';

  @override
  String get sortDuration => 'Trier par durée';

  @override
  String get sortDateAdded => 'Trier par date d\'ajout';

  @override
  String get sortBy => 'Trier par';

  @override
  String get trackInformation => 'Informations sur la piste';

  @override
  String get removeFromLibrary => 'Supprimer de la bibliothèque';

  @override
  String get showInFolder => 'Afficher dans le dossier';

  @override
  String get unknownArtist => 'Artiste inconnu';

  @override
  String get unknownAlbum => 'Album inconnu';

  @override
  String get importedFiles => 'Fichiers importés';

  @override
  String get playFolder => 'Lire le dossier';

  @override
  String get shuffleFolder => 'Lecture aléatoire du dossier';

  @override
  String get playAll => 'Tout lire';

  @override
  String get includeSubfolders => 'Inclure les sous-dossiers';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistes',
      one: '1 piste',
      zero: '0 piste',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Aucune chanson locale trouvée';

  @override
  String get searchLocalMusic => 'Rechercher de la musique locale...';

  @override
  String get viewAsList => 'Afficher en liste';

  @override
  String get viewAsGrid => 'Afficher en grille';

  @override
  String get trackInfoPath => 'Chemin';

  @override
  String get trackInfoFormat => 'Format';

  @override
  String get trackInfoDuration => 'Durée';

  @override
  String get aboutDescription =>
      'Un lecteur multimédia gratuit et open source.';

  @override
  String get aboutApp => 'À propos de PPPlayer';

  @override
  String get appTagline => 'Votre musique. À votre façon.';

  @override
  String get exploreApp => 'Explorer PPPlayer';

  @override
  String get viewSource => 'Voir le code source';

  @override
  String get seeWhatsNew => 'Nouveautés';

  @override
  String get getHelp => 'Obtenir de l\'aide';

  @override
  String versionInfo(Object version, Object build) {
    return 'Version $version (Build $build)';
  }

  @override
  String get createdBy => 'Créé par Lucas Coelho';

  @override
  String get website => 'Site web';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Notes de version';

  @override
  String get support => 'Assistance';

  @override
  String get license => 'Licence';

  @override
  String get acknowledgments => 'Remerciements';

  @override
  String get close => 'Fermer';

  @override
  String copyright(Object year) {
    return '© $year Contributeurs de PPPlayer';
  }

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Votre musique vous attend.';

  @override
  String dailyMix(Object number) {
    return 'Mix du jour $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'Vos favoris\net de nouvelles découvertes';

  @override
  String get discoverWeekly => 'Découvertes de la semaine';

  @override
  String get releaseRadar => 'Radar des sorties';

  @override
  String get newMusicJustForYou => 'De la nouvelle musique\nrien que pour vous';

  @override
  String get chillMix => 'Mix détente';

  @override
  String get relaxAndUnwind => 'Détente et relaxation';

  @override
  String get focusMix => 'Mix concentration';

  @override
  String get deepFocusAndProductivity =>
      'Concentration profonde\net productivité';

  @override
  String artistRadio(Object artist) {
    return 'Radio $artist';
  }

  @override
  String genreRadio(Object genre) {
    return 'Radio $genre';
  }

  @override
  String get filterAll => 'Tout';

  @override
  String get filterPlaylists => 'Playlists';

  @override
  String get filterArtists => 'Artistes';

  @override
  String get filterAlbums => 'Albums';

  @override
  String get filterStations => 'Stations';

  @override
  String get filterStreams => 'Flux';

  @override
  String get localMusicCard => 'Musique locale';

  @override
  String get createPlaylistButton => 'Créer une playlist';

  @override
  String get radioStations => 'Stations de radio';

  @override
  String get discoverMusic => 'Découvrir la musique';

  @override
  String get importLocalMusic => 'Importer de la musique locale';

  @override
  String get importAudioFiles => 'Importer des fichiers audio';

  @override
  String get importFolder => 'Importer un dossier';

  @override
  String get importFolderSubtitle =>
      'Choisissez un dossier contenant des fichiers audio';

  @override
  String get importPlaylist => 'Importer la playlist';

  @override
  String get importPlaylistSubtitle => 'Importer des fichiers .m3u ou .m3u8';

  @override
  String get exportPlaylist => 'Exporter la playlist';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Format non pris en charge ou fichier corrompu';

  @override
  String get playbackErrorFileInaccessible =>
      'Fichier inaccessible ou introuvable';

  @override
  String get localVideosCard => 'Vidéos locales';

  @override
  String get noLocalVideos => 'Aucune vidéo trouvée';

  @override
  String get searchLocalVideos => 'Rechercher des vidéos locales';

  @override
  String get addVideos => 'Ajouter des vidéos';

  @override
  String get subtitles => 'Sous-titres';

  @override
  String get audioTracks => 'Pistes audio';

  @override
  String get loadSubtitleFile => 'Charger un fichier de sous-titres...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Erreur lors du chargement des sous-titres : $error';
  }

  @override
  String get off => 'Désactivé';

  @override
  String get playOn => 'Lire sur';

  @override
  String get thisDevice => 'Cet appareil';

  @override
  String get availableDevices => 'Appareils disponibles';

  @override
  String get searchingDevices => 'Recherche d’appareils…';

  @override
  String get refresh => 'Actualiser';

  @override
  String get connecting => 'Connexion…';

  @override
  String connectingTo(String name) {
    return 'Connexion à $name…';
  }

  @override
  String get connected => 'Connecté';

  @override
  String get unsupportedOutput =>
      'Cette source ne peut pas être lue sur cette sortie.';

  @override
  String get airPlayAudioOutput => 'AirPlay et sortie audio';

  @override
  String get returnForAirPlay =>
      'Lancez la lecture sur cet appareil pour utiliser AirPlay.';

  @override
  String get openSoundSettings =>
      'Ouvrez les réglages du son pour choisir une sortie.';

  @override
  String get soundSettingsError => 'Impossible d’ouvrir les réglages du son.';

  @override
  String get systemOutput => 'Sortie système';

  @override
  String playingOn(String name) {
    return 'Lecture sur $name';
  }

  @override
  String get chooseAirPlay =>
      'Touchez le bouton AirPlay pour choisir une enceinte ou un téléviseur.';

  @override
  String get airPlayDevice => 'Appareil AirPlay';

  @override
  String get playOnIphone => 'Lire sur cet iPhone';

  @override
  String get chooseIphone =>
      'Choisissez cet iPhone avec le bouton AirPlay ci-dessous.';

  @override
  String get profile => 'Profil';

  @override
  String get preferences => 'Préférences';

  @override
  String get themeColor => 'Couleur du thème';

  @override
  String get yourMusic => 'Votre musique';

  @override
  String get apiCredentials => 'Identifiants API';

  @override
  String get dataStorage => 'Données et stockage';

  @override
  String get editProfileHelp => 'Définissez votre nom et votre avatar';

  @override
  String get customProvider => 'Fournisseur personnalisé';

  @override
  String get defaultProvider => 'Par défaut de PPPlayer';

  @override
  String get proExperience => 'Expérience Pro active';

  @override
  String get beta => 'Bêta';

  @override
  String get loading => 'Chargement…';

  @override
  String get unknown => 'Inconnu';

  @override
  String get pause => 'Pause';

  @override
  String get repeat => 'Répéter';

  @override
  String get mute => 'Couper le son';

  @override
  String get unmute => 'Activer le son';

  @override
  String get fitVideo => 'Ajuster';

  @override
  String get fillVideo => 'Remplir';

  @override
  String get fullscreen => 'Plein écran';

  @override
  String get exitFullscreen => 'Quitter le plein écran';

  @override
  String get volume => 'Volume';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get clear => 'Effacer';

  @override
  String get follow => 'Suivre';

  @override
  String get unfollow => 'Ne plus suivre';

  @override
  String get following => 'Suivi';

  @override
  String get showAll => 'Tout afficher';

  @override
  String get appearance => 'Apparence';

  @override
  String get subtitleSize => 'Taille';

  @override
  String get subtitleBackground => 'Arrière-plan';

  @override
  String get earlier => 'Plus tôt';

  @override
  String get later => 'Plus tard';

  @override
  String get reset => 'Réinitialiser';

  @override
  String subtitleDelay(String seconds) {
    return 'Décalage : $seconds s';
  }

  @override
  String get morePlaybackControls => 'Autres commandes de lecture';

  @override
  String get hideVideo => 'Masquer la vidéo';

  @override
  String get showVideo => 'Afficher la vidéo';

  @override
  String get closeQueue => 'Fermer la file';

  @override
  String get enabled => 'Activé';

  @override
  String get openFile => 'Ouvrir un fichier…';

  @override
  String get openFolder => 'Ouvrir un dossier…';

  @override
  String get openUrl => 'Ouvrir une URL…';

  @override
  String get fileMenu => 'Fichier';

  @override
  String get viewMenu => 'Affichage';

  @override
  String get windowMenu => 'Fenêtre';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get themeAvatarColor => 'Couleur du thème et de l’avatar';

  @override
  String get networkStreams => 'Flux réseau';

  @override
  String get networkStream => 'Flux réseau';

  @override
  String get openNetworkStream => 'Ouvrir un flux réseau';

  @override
  String get editPlaylist => 'Modifier la playlist';

  @override
  String get editStreamItem => 'Modifier l’élément du flux';

  @override
  String get streamUrl => 'URL du flux';

  @override
  String get platformType => 'Plateforme / type';

  @override
  String get optionalTitle => 'Titre (facultatif)';

  @override
  String get optionalImageUrl => 'URL de l’image (facultative)';

  @override
  String get myStream => 'Mon flux';

  @override
  String get saveToLibrary => 'Enregistrer dans la bibliothèque';

  @override
  String get justPlay => 'Lire uniquement';

  @override
  String get autoDetect => 'Détection automatique';

  @override
  String get apiKeyRequired => 'Clé API requise';

  @override
  String get customApiKey => 'Utiliser une clé API personnalisée';

  @override
  String get clientId => 'Identifiant client';

  @override
  String get clientSecret => 'Secret client';

  @override
  String get saveCredentials => 'Enregistrer les identifiants';

  @override
  String get searchStrategy => 'Stratégie de recherche';

  @override
  String get credentialsLocalOnly =>
      'Stockés en sécurité sur cet appareil. Jamais envoyés à PPPlayer.';

  @override
  String get scrapingHelp =>
      'Aucune clé API ni quota requis. Peut être plus lent ou moins fiable.';

  @override
  String get streamHelp =>
      'Saisissez une URL HTTP(S) ou un lien de playlist M3U.';

  @override
  String get deletePlaylistConfirm =>
      'Supprimer définitivement cette playlist ?';

  @override
  String get clearCacheConfirm =>
      'Supprimer les données en cache ? Votre bibliothèque et vos favoris restent inchangés.';

  @override
  String get clearHistoryConfirm =>
      'Supprimer définitivement votre historique d’écoute ?';

  @override
  String get addedToQueue => 'Ajouté à la file';

  @override
  String get addedVideo => 'Vidéo ajoutée';

  @override
  String addedChannels(String count) {
    return 'Chaînes ajoutées : $count';
  }

  @override
  String get removedFromPlaylist => 'Retiré de la playlist';

  @override
  String get exportCancelled => 'Export annulé';

  @override
  String exportComplete(String count) {
    return 'Playlist exportée. Éléments ignorés : $count';
  }

  @override
  String get playlistExported => 'Playlist exportée';

  @override
  String get live => 'En direct';

  @override
  String get sponsored => 'Sponsorisé';

  @override
  String get removeFromPlaylist => 'Retirer de la playlist';

  @override
  String get likedSongsHelp => 'Enregistrez des morceaux pour les voir ici';

  @override
  String get apiSingleVideoHint =>
      'Vous pouvez ajouter cette vidéo sans importer la playlist.';

  @override
  String get linkCopied => 'Lien copié';

  @override
  String get willPlayNext => 'Sera lu ensuite';

  @override
  String get checkItOut => 'Découvrir';

  @override
  String get loadFailed => 'Impossible de charger le contenu. Réessayez.';
}
