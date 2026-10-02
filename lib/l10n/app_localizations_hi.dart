// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'एल्बम';

  @override
  String get api => 'API';

  @override
  String get artists => 'कलाकार';

  @override
  String get artwork => 'आर्टवर्क';

  @override
  String get appVersion => 'ऐप वर्ज़न';

  @override
  String get artist => 'कलाकार';

  @override
  String get artistsYouFollow => 'कलाकार जिन्हें आप फॉलो करते हैं';

  @override
  String get autoplay => 'ऑटोप्ले';

  @override
  String get becauseYouListenedTo => 'क्योंकि आपने सुना';

  @override
  String get browseAll => 'सभी ब्राउज़ करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get clearAppCache => 'ऐप कैश साफ़ करें?';

  @override
  String get clearCache => 'कैश साफ़ करें';

  @override
  String get clearHistory => 'इतिहास साफ़ करें?';

  @override
  String get clearRecentlyPlayed => 'हाल ही में चलाए गए साफ़ करें';

  @override
  String get contentMarket => 'कंटेंट मार्केट';

  @override
  String get continueListening => 'सुनना जारी रखें';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'छोटी विंडो में वीडियो प्लेबैक जारी रखें';

  @override
  String get create => 'बनाएं';

  @override
  String get createAPlaylistToGetStarted =>
      'शुरू करने के लिए एक प्लेलिस्ट बनाएं';

  @override
  String currentSelectedcountry(Object country) {
    return 'वर्तमान: $country';
  }

  @override
  String get deletePlaylist => 'प्लेलिस्ट हटाएं';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String errorLoadingMarkets(Object err) {
    return 'बाज़ार लोड करने में त्रुटि: $err';
  }

  @override
  String error(Object error) {
    return 'त्रुटि: $error';
  }

  @override
  String explore(Object genre) {
    return '$genre एक्सप्लोर करें';
  }

  @override
  String get fansAlsoLike => 'प्रशंसकों को यह भी पसंद है';

  @override
  String featuringTouppercase(Object artist) {
    return '$artist की विशेषता';
  }

  @override
  String get featuredPlaylists => 'विशेष प्लेलिस्ट';

  @override
  String get followArtistsToSeeThemHere =>
      'कलाकारों को यहां देखने के लिए उन्हें फॉलो करें';

  @override
  String get followStationsToSeeThemHere =>
      'स्टेशनों को यहां देखने के लिए उन्हें फॉलो करें';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'डेटा बचाने के लिए केवल ऑडियो स्ट्रीम को फ़ोर्स करें';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'स्थान खाली करता है और अगले लोड पर ताज़ा डेटा को फ़ोर्स करता है';

  @override
  String get fromYourFavorites => 'आपके पसंदीदा से';

  @override
  String get goBack => 'वापस जाएं';

  @override
  String inspiredByName(Object name) {
    return '$name से प्रेरित';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'कतार समाप्त होने पर समान ट्रैक बजाना जारी रखें';

  @override
  String get library => 'लाइब्रेरी';

  @override
  String get likeAlbumsToSeeThemHere =>
      'एल्बम को यहां देखने के लिए उन्हें पसंद करें';

  @override
  String get likedSongs => 'पसंद किए गए गाने';

  @override
  String get lowDataMode => 'लो डेटा मोड';

  @override
  String get madeForYou => 'आपके लिए बनाया गया';

  @override
  String moreLikeName(Object name) {
    return '$name के समान और';
  }

  @override
  String get moreOptions => 'अधिक विकल्प';

  @override
  String get nameYourMasterpiece => 'अपनी उत्कृष्ट कृति का नाम दें...';

  @override
  String get newPlaylist => 'नई प्लेलिस्ट';

  @override
  String get newReleases => 'नई रिलीज़';

  @override
  String get next => 'अगला';

  @override
  String get noAlbumsFound => 'कोई एल्बम नहीं मिला';

  @override
  String get noArtistsFollowed => 'किसी भी कलाकार को फॉलो नहीं किया गया';

  @override
  String get noArtistsFound => 'कोई कलाकार नहीं मिला';

  @override
  String get noLikedAlbums => 'कोई पसंदीदा एल्बम नहीं';

  @override
  String get noPlaylistsFound => 'कोई प्लेलिस्ट नहीं मिली';

  @override
  String get noPlaylistsYet => 'अभी तक कोई प्लेलिस्ट नहीं';

  @override
  String get noResultsFound => 'कोई परिणाम नहीं मिला';

  @override
  String get noStationsFollowed => 'किसी भी स्टेशन को फॉलो नहीं किया गया';

  @override
  String get noTrackPlaying => 'कोई ट्रैक नहीं चल रहा है';

  @override
  String get noTracksFound => 'कोई ट्रैक नहीं मिला';

  @override
  String get playlists => 'प्लेलिस्ट';

  @override
  String get popular => 'लोकप्रिय';

  @override
  String get permanentlyRemoveListeningHistory =>
      'सुनने का इतिहास स्थायी रूप से निकालें';

  @override
  String get pictureinpicturePip => 'पिक्चर-इन-पिक्चर (PiP)';

  @override
  String get popularAlbums => 'लोकप्रिय एल्बम';

  @override
  String get popularArtists => 'लोकप्रिय कलाकार';

  @override
  String get popularGenres => 'लोकप्रिय शैलियां';

  @override
  String get popularSongs => 'लोकप्रिय गाने';

  @override
  String get popularTracks => 'लोकप्रिय ट्रैक';

  @override
  String get popularHitsRightNow => 'अभी के लोकप्रिय हिट';

  @override
  String get previous => 'पिछला';

  @override
  String get queue => 'कतार';

  @override
  String get recentSearches => 'हाल की खोजें';

  @override
  String get recommendedForYou => 'आपके लिए अनुशंसित';

  @override
  String get scraping => 'स्क्रैपिंग';

  @override
  String get search => 'खोजें';

  @override
  String get searchInAlbum => 'एल्बम में खोजें...';

  @override
  String get searchInLibrary => 'लाइब्रेरी में खोजें...';

  @override
  String get searchInPlaylist => 'प्लेलिस्ट में खोजें';

  @override
  String get searchLikedSongs => 'पसंद किए गए गानों में खोजें...';

  @override
  String get searchPopularSongs => 'लोकप्रिय गानों में खोजें...';

  @override
  String get selectMarket => 'बाज़ार चुनें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get showVideoPlayer => 'वीडियो प्लेयर दिखाएं';

  @override
  String get shuffle => 'शफ़ल करें';

  @override
  String get spotifyCredentials => 'स्पॉटिफ़ाई क्रेडेंशियल';

  @override
  String get suggestedStations => 'सुझाए गए स्टेशन';

  @override
  String get tracks => 'ट्रैक';

  @override
  String get trending => 'ट्रेंडिंग';

  @override
  String get tryAgain => 'पुनः प्रयास करें';

  @override
  String get tryADifferentSearchTerm => 'एक अलग खोज शब्द आज़माएं';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'उपलब्ध होने पर YouTube प्लेयर का उपयोग करें';

  @override
  String get video => 'वीडियो';

  @override
  String get whatDoYouWantToListenTo => 'आप क्या सुनना चाहते हैं?';

  @override
  String get youtubeCredentials => 'यूट्यूब क्रेडेंशियल';

  @override
  String get yourLibrary => 'आपकी लाइब्रेरी';

  @override
  String get playerscreenviewswitch => 'प्लेयर_स्क्रीन_व्यू_स्विच';

  @override
  String get addToPlaylist => 'प्लेलिस्ट में जोड़ें';

  @override
  String get addToQueue => 'कतार में जोड़ें';

  @override
  String get copyId => 'ID कॉपी करें';

  @override
  String get copyLink => 'लिंक कॉपी करें';

  @override
  String get discover => 'खोजें';

  @override
  String get enterYourName => 'अपना नाम दर्ज करें';

  @override
  String get favorites => 'पसंदीदा';

  @override
  String get goToAlbum => 'एल्बम पर जाएं';

  @override
  String get goToArtist => 'कलाकार पर जाएं';

  @override
  String get goToArtistRadio => 'कलाकार रेडियो पर जाएं';

  @override
  String get goToPlaylist => 'प्लेलिस्ट पर जाएं';

  @override
  String get goToSongRadio => 'गाना रेडियो पर जाएं';

  @override
  String get home => 'होम';

  @override
  String get myAwesomePlaylist => 'मेरी शानदार प्लेलिस्ट';

  @override
  String get myPlaylist => 'मेरी प्लेलिस्ट';

  @override
  String get newPlaylist1 => 'नई प्लेलिस्ट';

  @override
  String get play => 'चलाएं';

  @override
  String get playStation => 'स्टेशन चलाएं';

  @override
  String get playNext => 'अगला चलाएं';

  @override
  String get playlist => 'प्लेलिस्ट';

  @override
  String get playlistName => 'प्लेलिस्ट का नाम';

  @override
  String get playlists1 => 'प्लेलिस्ट';

  @override
  String get queue1 => 'कतार';

  @override
  String get recentlyPlayed => 'हाल ही में चलाए गए';

  @override
  String get removeFromQueue => 'कतार से निकालें';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get searchMusicArtistsAlbums => 'संगीत, कलाकार, एल्बम खोजें...';

  @override
  String get share => 'साझा करें';

  @override
  String featuringArtist(String artistName) {
    return '$artistName की विशेषता';
  }

  @override
  String currentCountry(String country) {
    return 'वर्तमान: $country';
  }

  @override
  String get queueTooltip => 'कतार';

  @override
  String get searchHint => 'संगीत, कलाकार, एल्बम खोजें...';

  @override
  String get language => 'भाषा';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get songsTab => 'गाने';

  @override
  String get foldersTab => 'फ़ोल्डर';

  @override
  String get artistsTab => 'कलाकार';

  @override
  String get albumsTab => 'एल्बम';

  @override
  String get genresTab => 'शैलियां';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'प्लेबैक गति';

  @override
  String get addMusic => 'संगीत जोड़ें';

  @override
  String get addFiles => 'फ़ाइलें जोड़ें';

  @override
  String get addFolder => 'फ़ोल्डर जोड़ें';

  @override
  String get rescanLibrary => 'लाइब्रेरी को फिर से स्कैन करें';

  @override
  String get sortTitle => 'शीर्षक के अनुसार क्रमित करें';

  @override
  String get sortArtist => 'कलाकार के अनुसार क्रमित करें';

  @override
  String get sortAlbum => 'एल्बम के अनुसार क्रमित करें';

  @override
  String get sortDuration => 'अवधि के अनुसार क्रमित करें';

  @override
  String get sortDateAdded => 'जोड़ने की तिथि के अनुसार क्रमित करें';

  @override
  String get sortBy => 'क्रमबद्ध करें';

  @override
  String get trackInformation => 'ट्रैक की जानकारी';

  @override
  String get removeFromLibrary => 'लाइब्रेरी से हटाएं';

  @override
  String get showInFolder => 'फ़ोल्डर में दिखाएं';

  @override
  String get unknownArtist => 'अज्ञात कलाकार';

  @override
  String get unknownAlbum => 'अज्ञात एल्बम';

  @override
  String get importedFiles => 'आयातित फ़ाइलें';

  @override
  String get playFolder => 'फ़ोल्डर चलाएं';

  @override
  String get shuffleFolder => 'फ़ोल्डर शफ़ल करें';

  @override
  String get playAll => 'सभी चलाएं';

  @override
  String get includeSubfolders => 'उपफ़ोल्डर शामिल करें';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रैक',
      one: '1 ट्रैक',
      zero: '0 ट्रैक',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'कोई स्थानीय गाने नहीं मिले';

  @override
  String get searchLocalMusic => 'स्थानीय संगीत खोजें...';

  @override
  String get viewAsList => 'सूची के रूप में देखें';

  @override
  String get viewAsGrid => 'ग्रिड के रूप में देखें';

  @override
  String get trackInfoPath => 'पथ';

  @override
  String get trackInfoFormat => 'प्रारूप';

  @override
  String get trackInfoDuration => 'अवधि';

  @override
  String get aboutDescription => 'एक मुफ्त, ओपन-सोर्स मीडिया प्लेयर।';

  @override
  String get aboutApp => 'PPPlayer के बारे में';

  @override
  String get appTagline => 'आपका संगीत। आपके तरीके से।';

  @override
  String get exploreApp => 'PPPlayer का अन्वेषण करें';

  @override
  String get viewSource => 'स्रोत देखें';

  @override
  String get seeWhatsNew => 'नया क्या है देखें';

  @override
  String get getHelp => 'सहायता प्राप्त करें';

  @override
  String versionInfo(Object version, Object build) {
    return 'संस्करण $version (बिल्ड $build)';
  }

  @override
  String get createdBy => 'Lucas Coelho द्वारा निर्मित';

  @override
  String get website => 'वेबसाइट';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'रिलीज़ नोट्स';

  @override
  String get support => 'समर्थन';

  @override
  String get license => 'लाइसेंस';

  @override
  String get acknowledgments => 'आभार';

  @override
  String get close => 'बंद करें';

  @override
  String copyright(Object year) {
    return '© $year PPPlayer योगदानकर्ता';
  }

  @override
  String get goodMorning => 'सुप्रभात';

  @override
  String get goodAfternoon => 'शुभ दोपहर';

  @override
  String get goodEvening => 'शुभ संध्या';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'आपका संगीत आपकी प्रतीक्षा कर रहा है।';

  @override
  String dailyMix(Object number) {
    return 'डेली मिक्स $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries => 'आपके पसंदीदा\nऔर नई खोजें';

  @override
  String get discoverWeekly => 'साप्ताहिक खोजें';

  @override
  String get releaseRadar => 'रिलीज़ रडार';

  @override
  String get newMusicJustForYou => 'नया संगीत\nसिर्फ आपके लिए';

  @override
  String get chillMix => 'चिल मिक्स';

  @override
  String get relaxAndUnwind => 'आराम करें';

  @override
  String get focusMix => 'फोकस मिक्स';

  @override
  String get deepFocusAndProductivity => 'गहरा ध्यान\nऔर उत्पादकता';

  @override
  String artistRadio(Object artist) {
    return '$artist रेडियो';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre रेडियो';
  }

  @override
  String get filterAll => 'सभी';

  @override
  String get filterPlaylists => 'प्लेलिस्ट';

  @override
  String get filterArtists => 'कलाकार';

  @override
  String get filterAlbums => 'एल्बम';

  @override
  String get filterStations => 'स्टेशन';

  @override
  String get filterStreams => 'स्ट्रीम';

  @override
  String get localMusicCard => 'स्थानीय संगीत';

  @override
  String get createPlaylistButton => 'प्लेलिस्ट बनाएं';

  @override
  String get radioStations => 'रेडियो स्टेशन';

  @override
  String get discoverMusic => 'संगीत खोजें';

  @override
  String get importLocalMusic => 'स्थानीय संगीत आयात करें';

  @override
  String get importAudioFiles => 'ऑडियो फ़ाइलें आयात करें';

  @override
  String get importFolder => 'फ़ोल्डर आयात करें';

  @override
  String get importFolderSubtitle => 'ऑडियो फ़ाइलों वाले एक फ़ोल्डर को चुनें';

  @override
  String get importPlaylist => 'प्लेलिस्ट आयात करें';

  @override
  String get importPlaylistSubtitle => '.m3u या .m3u8 फ़ाइलें आयात करें';

  @override
  String get exportPlaylist => 'प्लेलिस्ट निर्यात करें';

  @override
  String get playbackErrorUnsupportedFormat =>
      'असमर्थित प्रारूप या भ्रष्ट फ़ाइल';

  @override
  String get playbackErrorFileInaccessible => 'फ़ाइल अगम्य या नहीं मिली';

  @override
  String get localVideosCard => 'स्थानीय वीडियो';

  @override
  String get noLocalVideos => 'कोई वीडियो नहीं मिला';

  @override
  String get searchLocalVideos => 'स्थानीय वीडियो खोजें';

  @override
  String get addVideos => 'वीडियो जोड़ें';

  @override
  String get subtitles => 'उपशीर्षक';

  @override
  String get audioTracks => 'ऑडियो ट्रैक';

  @override
  String get loadSubtitleFile => 'उपशीर्षक फ़ाइल लोड करें...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'सबटाइटल लोड करने में त्रुटि: $error';
  }

  @override
  String get off => 'बंद';

  @override
  String get playOn => 'इस पर चलाएँ';

  @override
  String get thisDevice => 'यह डिवाइस';

  @override
  String get availableDevices => 'उपलब्ध डिवाइस';

  @override
  String get searchingDevices => 'डिवाइस खोजे जा रहे हैं…';

  @override
  String get refresh => 'रिफ्रेश करें';

  @override
  String get connecting => 'कनेक्ट हो रहा है…';

  @override
  String connectingTo(String name) {
    return '$name से कनेक्ट हो रहा है…';
  }

  @override
  String get connected => 'कनेक्ट हो गया';

  @override
  String get unsupportedOutput => 'यह स्रोत इस आउटपुट पर नहीं चलाया जा सकता।';

  @override
  String get airPlayAudioOutput => 'AirPlay और ऑडियो आउटपुट';

  @override
  String get returnForAirPlay =>
      'AirPlay इस्तेमाल करने के लिए इस डिवाइस पर चलाएँ।';

  @override
  String get openSoundSettings => 'आउटपुट चुनने के लिए ध्वनि सेटिंग खोलें।';

  @override
  String get soundSettingsError => 'ध्वनि सेटिंग नहीं खुल सकीं।';

  @override
  String get systemOutput => 'सिस्टम आउटपुट';

  @override
  String playingOn(String name) {
    return '$name पर चल रहा है';
  }

  @override
  String get chooseAirPlay =>
      'स्पीकर या टीवी चुनने के लिए AirPlay बटन टैप करें।';

  @override
  String get airPlayDevice => 'AirPlay डिवाइस';

  @override
  String get playOnIphone => 'इस iPhone पर चलाएँ';

  @override
  String get chooseIphone => 'नीचे दिए AirPlay बटन से इस iPhone को चुनें।';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get preferences => 'प्राथमिकताएँ';

  @override
  String get themeColor => 'थीम का रंग';

  @override
  String get yourMusic => 'आपका संगीत';

  @override
  String get apiCredentials => 'API क्रेडेंशियल';

  @override
  String get dataStorage => 'डेटा और स्टोरेज';

  @override
  String get editProfileHelp => 'अपना नाम और अवतार सेट करें';

  @override
  String get customProvider => 'कस्टम प्रदाता';

  @override
  String get defaultProvider => 'PPPlayer डिफ़ॉल्ट';

  @override
  String get proExperience => 'Pro अनुभव सक्रिय';

  @override
  String get beta => 'बीटा';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get pause => 'रोकें';

  @override
  String get repeat => 'दोहराएँ';

  @override
  String get mute => 'आवाज़ बंद करें';

  @override
  String get unmute => 'आवाज़ चालू करें';

  @override
  String get fitVideo => 'फ़िट करें';

  @override
  String get fillVideo => 'भरें';

  @override
  String get fullscreen => 'पूर्ण स्क्रीन';

  @override
  String get exitFullscreen => 'पूर्ण स्क्रीन से बाहर निकलें';

  @override
  String get volume => 'आवाज़';

  @override
  String get save => 'सहेजें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get follow => 'फ़ॉलो करें';

  @override
  String get unfollow => 'अनफ़ॉलो करें';

  @override
  String get following => 'फ़ॉलो कर रहे हैं';

  @override
  String get showAll => 'सभी दिखाएँ';

  @override
  String get appearance => 'रूप';

  @override
  String get subtitleSize => 'आकार';

  @override
  String get subtitleBackground => 'पृष्ठभूमि';

  @override
  String get earlier => 'पहले';

  @override
  String get later => 'बाद में';

  @override
  String get reset => 'रीसेट करें';

  @override
  String subtitleDelay(String seconds) {
    return 'देरी: $seconds सेकंड';
  }

  @override
  String get morePlaybackControls => 'अधिक प्लेबैक नियंत्रण';

  @override
  String get hideVideo => 'वीडियो छिपाएँ';

  @override
  String get showVideo => 'वीडियो दिखाएँ';

  @override
  String get closeQueue => 'कतार बंद करें';

  @override
  String get enabled => 'चालू';

  @override
  String get openFile => 'फ़ाइल खोलें…';

  @override
  String get openFolder => 'फ़ोल्डर खोलें…';

  @override
  String get openUrl => 'URL खोलें…';

  @override
  String get fileMenu => 'फ़ाइल';

  @override
  String get viewMenu => 'देखें';

  @override
  String get windowMenu => 'विंडो';

  @override
  String get saveChanges => 'बदलाव सहेजें';

  @override
  String get themeAvatarColor => 'थीम और अवतार का रंग';

  @override
  String get networkStreams => 'नेटवर्क स्ट्रीम';

  @override
  String get networkStream => 'नेटवर्क स्ट्रीम';

  @override
  String get openNetworkStream => 'नेटवर्क स्ट्रीम खोलें';

  @override
  String get editPlaylist => 'प्लेलिस्ट संपादित करें';

  @override
  String get editStreamItem => 'स्ट्रीम आइटम संपादित करें';

  @override
  String get streamUrl => 'स्ट्रीम URL';

  @override
  String get platformType => 'प्लेटफ़ॉर्म / प्रकार';

  @override
  String get optionalTitle => 'शीर्षक (वैकल्पिक)';

  @override
  String get optionalImageUrl => 'चित्र का URL (वैकल्पिक)';

  @override
  String get myStream => 'मेरी स्ट्रीम';

  @override
  String get saveToLibrary => 'लाइब्रेरी में सहेजें';

  @override
  String get justPlay => 'सिर्फ चलाएँ';

  @override
  String get autoDetect => 'अपने आप पहचानें';

  @override
  String get apiKeyRequired => 'API कुंजी आवश्यक';

  @override
  String get customApiKey => 'अपनी API कुंजी इस्तेमाल करें';

  @override
  String get clientId => 'क्लाइंट ID';

  @override
  String get clientSecret => 'क्लाइंट सीक्रेट';

  @override
  String get saveCredentials => 'क्रेडेंशियल सहेजें';

  @override
  String get searchStrategy => 'खोज रणनीति';

  @override
  String get credentialsLocalOnly =>
      'इस डिवाइस पर सुरक्षित रूप से रखे जाते हैं। PPPlayer को कभी नहीं भेजे जाते।';

  @override
  String get scrapingHelp =>
      'API कुंजी या कोटा ज़रूरी नहीं। धीमा या कम भरोसेमंद हो सकता है।';

  @override
  String get streamHelp => 'HTTP(S) URL या M3U प्लेलिस्ट का लिंक डालें।';

  @override
  String get deletePlaylistConfirm => 'यह प्लेलिस्ट हमेशा के लिए हटाएँ?';

  @override
  String get clearCacheConfirm =>
      'कैश डेटा हटाएँ? आपकी लाइब्रेरी और पसंदीदा नहीं बदलेंगे।';

  @override
  String get clearHistoryConfirm => 'सुनने का इतिहास हमेशा के लिए हटाएँ?';

  @override
  String get addedToQueue => 'कतार में जोड़ा गया';

  @override
  String get addedVideo => 'वीडियो जोड़ा गया';

  @override
  String addedChannels(String count) {
    return 'जोड़े गए चैनल: $count';
  }

  @override
  String get removedFromPlaylist => 'प्लेलिस्ट से हटाया गया';

  @override
  String get exportCancelled => 'निर्यात रद्द';

  @override
  String exportComplete(String count) {
    return 'प्लेलिस्ट निर्यात हुई। छोड़े गए आइटम: $count';
  }

  @override
  String get playlistExported => 'प्लेलिस्ट निर्यात हुई';

  @override
  String get live => 'लाइव';

  @override
  String get sponsored => 'प्रायोजित';

  @override
  String get removeFromPlaylist => 'प्लेलिस्ट से हटाएँ';

  @override
  String get likedSongsHelp => 'यहाँ देखने के लिए गाने सहेजें';

  @override
  String get apiSingleVideoHint =>
      'आप प्लेलिस्ट आयात किए बिना यह वीडियो जोड़ सकते हैं।';

  @override
  String get linkCopied => 'लिंक कॉपी हुआ';

  @override
  String get willPlayNext => 'अगला चलाया जाएगा';

  @override
  String get checkItOut => 'देखें';

  @override
  String get loadFailed => 'सामग्री लोड नहीं हो सकी। कृपया फिर से कोशिश करें।';
}
