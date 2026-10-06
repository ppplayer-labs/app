// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get artists => 'ARTISTS';

  @override
  String get artwork => 'ARTWORK';

  @override
  String get appVersion => 'App version';

  @override
  String get artist => 'Artist';

  @override
  String get artistsYouFollow => 'Artists you follow';

  @override
  String get autoplay => 'Autoplay';

  @override
  String get becauseYouListenedTo => 'Because you listened to';

  @override
  String get browseAll => 'Browse all';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearAppCache => 'Clear App Cache?';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearHistory => 'Clear History?';

  @override
  String get clearRecentlyPlayed => 'Clear Recently Played';

  @override
  String get contentMarket => 'Content Market';

  @override
  String get continueListening => 'Continue Listening';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Continue video playback in a small window';

  @override
  String get create => 'Create';

  @override
  String get createAPlaylistToGetStarted => 'Create a playlist to get started';

  @override
  String currentSelectedcountry(Object country) {
    return 'Current: $country';
  }

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Error loading markets: $err';
  }

  @override
  String error(Object error) {
    return 'Error: $error';
  }

  @override
  String explore(Object genre) {
    return 'Explore $genre';
  }

  @override
  String get fansAlsoLike => 'FANS ALSO LIKE';

  @override
  String featuringTouppercase(Object artist) {
    return 'FEATURING $artist';
  }

  @override
  String get featuredPlaylists => 'Featured Playlists';

  @override
  String get followArtistsToSeeThemHere => 'Follow artists to see them here';

  @override
  String get followStationsToSeeThemHere => 'Follow stations to see them here';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Force audio-only streams to save data';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Frees up space and forces fresh data on next load';

  @override
  String get fromYourFavorites => 'From your favorites';

  @override
  String get goBack => 'Go Back';

  @override
  String inspiredByName(Object name) {
    return 'Inspired by $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Keep playing similar tracks when queue ends';

  @override
  String get library => 'Library';

  @override
  String get likeAlbumsToSeeThemHere => 'Like albums to see them here';

  @override
  String get likedSongs => 'Liked Songs';

  @override
  String get lowDataMode => 'Low Data Mode';

  @override
  String get madeForYou => 'Made for you';

  @override
  String moreLikeName(Object name) {
    return 'More like $name';
  }

  @override
  String get moreOptions => 'More options';

  @override
  String get nameYourMasterpiece => 'Name your masterpiece...';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get newReleases => 'New Releases';

  @override
  String get next => 'Next';

  @override
  String get noAlbumsFound => 'No albums found';

  @override
  String get noArtistsFollowed => 'No artists followed';

  @override
  String get noArtistsFound => 'No artists found';

  @override
  String get noLikedAlbums => 'No liked albums';

  @override
  String get noPlaylistsFound => 'No playlists found';

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get noStationsFollowed => 'No stations followed';

  @override
  String get noTrackPlaying => 'No track playing';

  @override
  String get noTracksFound => 'No tracks found';

  @override
  String get playlists => 'PLAYLISTS';

  @override
  String get popular => 'POPULAR';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Permanently remove listening history';

  @override
  String get pictureinpicturePip => 'Picture-in-Picture (PiP)';

  @override
  String get popularAlbums => 'Popular Albums';

  @override
  String get popularArtists => 'Popular Artists';

  @override
  String get popularGenres => 'Popular Genres';

  @override
  String get popularSongs => 'Popular Songs';

  @override
  String get popularTracks => 'Popular Tracks';

  @override
  String get popularHitsRightNow => 'Popular hits right now';

  @override
  String get previous => 'Previous';

  @override
  String get queue => 'QUEUE';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get recommendedForYou => 'Recommended for You';

  @override
  String get scraping => 'Scraping';

  @override
  String get search => 'Search';

  @override
  String get searchInAlbum => 'Search in album...';

  @override
  String get searchInLibrary => 'Search in library...';

  @override
  String get searchInPlaylist => 'Search in playlist';

  @override
  String get searchLikedSongs => 'Search liked songs...';

  @override
  String get searchPopularSongs => 'Search popular songs...';

  @override
  String get selectMarket => 'Select Market';

  @override
  String get settings => 'Settings';

  @override
  String get showVideoPlayer => 'Show Video Player';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get spotifyCredentials => 'Spotify Credentials';

  @override
  String get suggestedStations => 'Suggested Stations';

  @override
  String get tracks => 'TRACKS';

  @override
  String get trending => 'Trending';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get tryADifferentSearchTerm => 'Try a different search term';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Use YouTube player when available';

  @override
  String get video => 'VIDEO';

  @override
  String get whatDoYouWantToListenTo => 'What do you want to listen to?';

  @override
  String get youtubeCredentials => 'YouTube Credentials';

  @override
  String get yourLibrary => 'Your Library';

  @override
  String get playerscreenviewswitch => 'player_screen_view_switch';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get copyId => 'Copy ID';

  @override
  String get copyLink => 'Copy link';

  @override
  String get discover => 'Discover';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get favorites => 'Favorites';

  @override
  String get goToAlbum => 'Go to album';

  @override
  String get goToArtist => 'Go to artist';

  @override
  String get goToArtistRadio => 'Go to artist radio';

  @override
  String get goToPlaylist => 'Go to playlist';

  @override
  String get goToSongRadio => 'Go to song radio';

  @override
  String get home => 'Home';

  @override
  String get myAwesomePlaylist => 'My Awesome Playlist';

  @override
  String get myPlaylist => 'My Playlist';

  @override
  String get newPlaylist1 => 'New playlist';

  @override
  String get play => 'Play';

  @override
  String get playStation => 'Play Station';

  @override
  String get playNext => 'Play next';

  @override
  String get playlist => 'Playlist';

  @override
  String get playlistName => 'Playlist Name';

  @override
  String get playlists1 => 'Playlists';

  @override
  String get queue1 => 'Queue';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueUpNext => 'Up next';

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get removeFromQueue => 'Remove from queue';

  @override
  String get retry => 'Retry';

  @override
  String get searchMusicArtistsAlbums => 'Search music, artists, albums...';

  @override
  String get share => 'Share';

  @override
  String featuringArtist(String artistName) {
    return 'FEATURING $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Current: $country';
  }

  @override
  String get queueTooltip => 'Queue';

  @override
  String get searchHint => 'Search music, artists, albums...';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get songsTab => 'Songs';

  @override
  String get foldersTab => 'Folders';

  @override
  String get artistsTab => 'Artists';

  @override
  String get albumsTab => 'Albums';

  @override
  String get genresTab => 'Genres';

  @override
  String get noLocalGenres => 'No genres found';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get addMusic => 'Add music';

  @override
  String get addFiles => 'Add files';

  @override
  String get addFolder => 'Add folder';

  @override
  String get rescanLibrary => 'Rescan library';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortArtist => 'Artist';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortDuration => 'Duration';

  @override
  String get sortDateAdded => 'Date Added';

  @override
  String get sortBy => 'Sort by';

  @override
  String get trackInformation => 'Track Information';

  @override
  String get removeFromLibrary => 'Remove from library';

  @override
  String get showInFolder => 'Show in folder';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get unknownAlbum => 'Unknown Album';

  @override
  String get importedFiles => 'Imported Files';

  @override
  String get playFolder => 'Play folder';

  @override
  String get shuffleFolder => 'Shuffle folder';

  @override
  String get playAll => 'Play all';

  @override
  String get includeSubfolders => 'Include subfolders';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
      zero: '0 tracks',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'No local songs imported';

  @override
  String get searchLocalMusic => 'Search local music';

  @override
  String get viewAsList => 'View as list';

  @override
  String get viewAsGrid => 'View as grid';

  @override
  String get trackInfoPath => 'Path';

  @override
  String get trackInfoFormat => 'Format';

  @override
  String get trackInfoDuration => 'Duration';

  @override
  String get aboutDescription => 'A free, open-source media player.';

  @override
  String get aboutApp => 'About PPPlayer';

  @override
  String get appTagline => 'Your music. Your way.';

  @override
  String get exploreApp => 'Explore PPPlayer';

  @override
  String get viewSource => 'View the source';

  @override
  String get seeWhatsNew => 'See what\'s new';

  @override
  String get getHelp => 'Get help';

  @override
  String versionInfo(Object version, Object build) {
    return 'Version $version (Build $build)';
  }

  @override
  String get createdBy => 'Created by Lucas Coelho';

  @override
  String get website => 'Website';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Release notes';

  @override
  String get support => 'Support';

  @override
  String get license => 'License';

  @override
  String get acknowledgments => 'Acknowledgments';

  @override
  String get close => 'Close';

  @override
  String copyright(Object year) {
    return '© $year PPPlayer contributors';
  }

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Your music is waiting.';

  @override
  String dailyMix(Object number) {
    return 'Daily Mix $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'Your favorites\nand new discoveries';

  @override
  String get discoverWeekly => 'Discover Weekly';

  @override
  String get releaseRadar => 'Release Radar';

  @override
  String get newMusicJustForYou => 'New music\njust for you';

  @override
  String get chillMix => 'Chill Mix';

  @override
  String get relaxAndUnwind => 'Relax and unwind';

  @override
  String get focusMix => 'Focus Mix';

  @override
  String get deepFocusAndProductivity => 'Deep focus\nand productivity';

  @override
  String artistRadio(Object artist) {
    return '$artist Radio';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre Radio';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterPlaylists => 'Playlists';

  @override
  String get filterArtists => 'Artists';

  @override
  String get filterAlbums => 'Albums';

  @override
  String get filterStations => 'Stations';

  @override
  String get filterStreams => 'Streams';

  @override
  String get localMusicCard => 'Local Music';

  @override
  String get createPlaylistButton => 'Create Playlist';

  @override
  String get radioStations => 'Radio Stations';

  @override
  String get discoverMusic => 'Discover Music';

  @override
  String get importLocalMusic => 'Import Local Music';

  @override
  String get importAudioFiles => 'Import Audio Files';

  @override
  String get importFolder => 'Import Folder';

  @override
  String get importFolderSubtitle =>
      'Note: Audio files are hidden in the folder picker. This is normal.';

  @override
  String get importPlaylist => 'Import Playlist';

  @override
  String get importPlaylistSubtitle => 'Import .m3u or .m3u8 files';

  @override
  String get exportPlaylist => 'Export Playlist';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Unsupported format or corrupted file';

  @override
  String get playbackErrorFileInaccessible => 'File inaccessible or not found';

  @override
  String get localVideosCard => 'Local Videos';

  @override
  String get noLocalVideos => 'No videos found';

  @override
  String get searchLocalVideos => 'Search local videos';

  @override
  String get addVideos => 'Add Videos';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get audioTracks => 'Audio Tracks';

  @override
  String get loadSubtitleFile => 'Load subtitle file...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Error loading subtitle: $error';
  }

  @override
  String get off => 'Off';

  @override
  String get playOn => 'Play On';

  @override
  String get thisDevice => 'This device';

  @override
  String get availableDevices => 'Available devices';

  @override
  String get searchingDevices => 'Searching for devices…';

  @override
  String get refresh => 'Refresh';

  @override
  String get connecting => 'Connecting…';

  @override
  String connectingTo(String name) {
    return 'Connecting to $name…';
  }

  @override
  String get connected => 'Connected';

  @override
  String get unsupportedOutput =>
      'This source cannot be played on this output.';

  @override
  String get airPlayAudioOutput => 'AirPlay & audio output';

  @override
  String get returnForAirPlay => 'Play on this device to use AirPlay.';

  @override
  String get openSoundSettings => 'Open Sound settings to choose an output.';

  @override
  String get soundSettingsError => 'Could not open Sound settings.';

  @override
  String get systemOutput => 'System output';

  @override
  String playingOn(String name) {
    return 'Playing on $name';
  }

  @override
  String get chooseAirPlay =>
      'Tap the AirPlay button to choose a speaker or TV.';

  @override
  String get airPlayDevice => 'AirPlay device';

  @override
  String get playOnIphone => 'Play on this iPhone';

  @override
  String get chooseIphone =>
      'Choose this iPhone using the AirPlay button below.';

  @override
  String get profile => 'Profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get themeColor => 'Theme color';

  @override
  String get yourMusic => 'Your music';

  @override
  String get apiCredentials => 'API credentials';

  @override
  String get dataStorage => 'Data & storage';

  @override
  String get editProfileHelp => 'Set your name and avatar';

  @override
  String get customProvider => 'Custom provider';

  @override
  String get defaultProvider => 'PPPlayer default';

  @override
  String get proExperience => 'Pro experience active';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Loading…';

  @override
  String get unknown => 'Unknown';

  @override
  String get pause => 'Pause';

  @override
  String get repeat => 'Repeat';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get fitVideo => 'Fit';

  @override
  String get fillVideo => 'Fill';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get volume => 'Volume';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get clear => 'Clear';

  @override
  String get follow => 'Follow';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get following => 'Following';

  @override
  String get showAll => 'Show all';

  @override
  String get appearance => 'Appearance';

  @override
  String get subtitleSize => 'Size';

  @override
  String get subtitleBackground => 'Background';

  @override
  String get earlier => 'Earlier';

  @override
  String get later => 'Later';

  @override
  String get reset => 'Reset';

  @override
  String subtitleDelay(String seconds) {
    return 'Delay: $seconds s';
  }

  @override
  String get morePlaybackControls => 'More playback controls';

  @override
  String get hideVideo => 'Hide video';

  @override
  String get showVideo => 'Show video';

  @override
  String get closeQueue => 'Close queue';

  @override
  String get enabled => 'On';

  @override
  String get openFile => 'Open file…';

  @override
  String get openFolder => 'Open folder…';

  @override
  String get openUrl => 'Open URL…';

  @override
  String get fileMenu => 'File';

  @override
  String get viewMenu => 'View';

  @override
  String get windowMenu => 'Window';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get themeAvatarColor => 'Theme and avatar color';

  @override
  String get networkStreams => 'Network streams';

  @override
  String get networkStream => 'Network stream';

  @override
  String get openNetworkStream => 'Open network stream';

  @override
  String get editPlaylist => 'Edit playlist';

  @override
  String get editStreamItem => 'Edit stream item';

  @override
  String get streamUrl => 'Stream URL';

  @override
  String get platformType => 'Platform / type';

  @override
  String get optionalTitle => 'Title (optional)';

  @override
  String get optionalImageUrl => 'Image URL (optional)';

  @override
  String get myStream => 'My stream';

  @override
  String get saveToLibrary => 'Save to library';

  @override
  String get justPlay => 'Just play';

  @override
  String get autoDetect => 'Auto-detect';

  @override
  String get apiKeyRequired => 'API key required';

  @override
  String get customApiKey => 'Use custom API key';

  @override
  String get clientId => 'Client ID';

  @override
  String get clientSecret => 'Client secret';

  @override
  String get saveCredentials => 'Save credentials';

  @override
  String get searchStrategy => 'Search strategy';

  @override
  String get credentialsLocalOnly =>
      'Stored securely on this device. Never sent to PPPlayer.';

  @override
  String get scrapingHelp =>
      'No API key or quota required. May be slower or less reliable.';

  @override
  String get streamHelp => 'Enter an HTTP(S) URL or M3U playlist link.';

  @override
  String get deletePlaylistConfirm => 'Delete this playlist permanently?';

  @override
  String get clearCacheConfirm =>
      'Delete cached data? Your library and favorites stay unchanged.';

  @override
  String get clearHistoryConfirm =>
      'Delete your listening history permanently?';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get addedVideo => 'Video added';

  @override
  String addedChannels(String count) {
    return 'Channels added: $count';
  }

  @override
  String get removedFromPlaylist => 'Removed from playlist';

  @override
  String get exportCancelled => 'Export cancelled';

  @override
  String exportComplete(String count) {
    return 'Playlist exported. Items skipped: $count';
  }

  @override
  String get playlistExported => 'Playlist exported';

  @override
  String get live => 'Live';

  @override
  String get sponsored => 'Sponsored';

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get likedSongsHelp => 'Save songs to see them here';

  @override
  String get apiSingleVideoHint =>
      'You can add this video without importing the playlist.';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get willPlayNext => 'Will play next';

  @override
  String get checkItOut => 'Check it out';

  @override
  String get loadFailed => 'Could not load content. Please try again.';
}
