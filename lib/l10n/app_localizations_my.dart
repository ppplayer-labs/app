// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class AppLocalizationsMy extends AppLocalizations {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title၊ $subtitle';
  }

  @override
  String get albums => 'အယ်လ်ဘမ်များ';

  @override
  String get api => 'API';

  @override
  String get artists => 'အနုပညာရှင်များ';

  @override
  String get artwork => 'အနုပညာလက်ရာ';

  @override
  String get appVersion => 'အက်ပ်ဗားရှင်း';

  @override
  String get artist => 'အနုပညာရှင်';

  @override
  String get artistsYouFollow => 'သင် follow ထားသော အနုပညာရှင်များ';

  @override
  String get autoplay => 'အလိုအလျောက်ဖွင့်မည်';

  @override
  String get becauseYouListenedTo => 'သင်နားဆင်ခဲ့သောကြောင့်';

  @override
  String get browseAll => 'အားလုံးကိုရှာဖွေရန်';

  @override
  String get cancel => 'ပယ်ဖျက်မည်';

  @override
  String get clearAppCache => 'အက်ပ် ကက်ရှ်ကို ရှင်းလင်းမလား။';

  @override
  String get clearCache => 'ကက်ရှ်ကို ရှင်းမည်';

  @override
  String get clearHistory => 'မှတ်တမ်းကို ရှင်းလင်းမလား။';

  @override
  String get clearRecentlyPlayed => 'လတ်တလော ဖွင့်ထားသည်များကို ရှင်းမည်';

  @override
  String get contentMarket => 'အကြောင်းအရာ ဈေးကွက်';

  @override
  String get continueListening => 'ဆက်လက်နားဆင်ရန်';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'ဗီဒီယိုကို ပြတင်းပေါက်ငယ်တွင် ဆက်ဖွင့်မည်';

  @override
  String get create => 'ဖန်တီးရန်';

  @override
  String get createAPlaylistToGetStarted => 'စတင်ရန် ဖွင့်စာရင်း ဖန်တီးပါ';

  @override
  String currentSelectedcountry(Object country) {
    return 'လက်ရှိ: $country';
  }

  @override
  String get deletePlaylist => 'ဖွင့်စာရင်းကို ဖျက်မည်';

  @override
  String get editProfile => 'ပရိုဖိုင်ကို ပြင်ဆင်ရန်';

  @override
  String errorLoadingMarkets(Object err) {
    return 'ဈေးကွက်များ တင်ရာတွင် အမှားဖြစ်နေပါသည်: $err';
  }

  @override
  String error(Object error) {
    return 'အမှား: $error';
  }

  @override
  String explore(Object genre) {
    return '$genre ကို ရှာဖွေပါ';
  }

  @override
  String get fansAlsoLike => 'ပရိသတ်များလည်း နှစ်သက်သည်';

  @override
  String featuringTouppercase(Object artist) {
    return '$artist ပါဝင်သည်';
  }

  @override
  String get featuredPlaylists => 'အထူးပြု ဖွင့်စာရင်းများ';

  @override
  String get followArtistsToSeeThemHere =>
      'အနုပညာရှင်များကို ဤနေရာတွင် မြင်တွေ့ရန် ၎င်းတို့ကို follow လုပ်ပါ';

  @override
  String get followStationsToSeeThemHere =>
      'စတေရှင်များကို ဤနေရာတွင် မြင်တွေ့ရန် ၎င်းတို့ကို follow လုပ်ပါ';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'ဒေတာသက်သာရန် အသံသီးသန့် ဖွင့်မည်';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'နေရာလွတ်ရစေပြီး နောက်တစ်ကြိမ်ဖွင့်ပါက ဒေတာအသစ်ပြန်ယူမည်';

  @override
  String get fromYourFavorites => 'သင်၏ အကြိုက်ဆုံးများမှ';

  @override
  String get goBack => 'နောက်သို့';

  @override
  String inspiredByName(Object name) {
    return '$name မှ စိတ်ကူးရယူထားသည်';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'တန်းစီထားသည်များ ပြီးဆုံးပါက အလားတူသီချင်းများကို ဆက်ဖွင့်မည်';

  @override
  String get library => 'စာကြည့်တိုက်';

  @override
  String get likeAlbumsToSeeThemHere =>
      'အယ်လ်ဘမ်များကို ဤနေရာတွင် မြင်တွေ့ရန် ၎င်းတို့ကို Like လုပ်ပါ';

  @override
  String get likedSongs => 'Like လုပ်ထားသော သီချင်းများ';

  @override
  String get lowDataMode => 'ဒေတာအနည်းဆုံးမုဒ်';

  @override
  String get madeForYou => 'သင့်အတွက် ပြုလုပ်ထားသည်';

  @override
  String moreLikeName(Object name) {
    return '$name နှင့် အလားတူများ';
  }

  @override
  String get moreOptions => 'နောက်ထပ် ရွေးချယ်စရာများ';

  @override
  String get nameYourMasterpiece => 'သင်၏ လက်ရာကို အမည်ပေးပါ...';

  @override
  String get newPlaylist => 'ဖွင့်စာရင်းအသစ်';

  @override
  String get newReleases => 'အသစ်ထွက်ရှိမှုများ';

  @override
  String get next => 'ရှေ့သို့';

  @override
  String get noAlbumsFound => 'အယ်လ်ဘမ်များ မတွေ့ပါ';

  @override
  String get noArtistsFollowed => 'Follow လုပ်ထားသော အနုပညာရှင် မရှိပါ';

  @override
  String get noArtistsFound => 'အနုပညာရှင် မတွေ့ပါ';

  @override
  String get noLikedAlbums => 'Like လုပ်ထားသော အယ်လ်ဘမ် မရှိပါ';

  @override
  String get noPlaylistsFound => 'ဖွင့်စာရင်း မတွေ့ပါ';

  @override
  String get noPlaylistsYet => 'ဖွင့်စာရင်း မရှိသေးပါ';

  @override
  String get noResultsFound => 'ရလဒ်များ မတွေ့ပါ';

  @override
  String get noStationsFollowed => 'Follow လုပ်ထားသော စတေရှင် မရှိပါ';

  @override
  String get noTrackPlaying => 'ဖွင့်နေသော သီချင်း မရှိပါ';

  @override
  String get noTracksFound => 'သီချင်းများ မတွေ့ပါ';

  @override
  String get playlists => 'ဖွင့်စာရင်းများ';

  @override
  String get popular => 'ရေပန်းစားသော';

  @override
  String get permanentlyRemoveListeningHistory =>
      'နားဆင်မှု မှတ်တမ်းကို အပြီးတိုင် ဖယ်ရှားမည်';

  @override
  String get pictureinpicturePip => 'ရုပ်ပုံတွင်း-ရုပ်ပုံ (PiP)';

  @override
  String get popularAlbums => 'ရေပန်းစားသော အယ်လ်ဘမ်များ';

  @override
  String get popularArtists => 'ရေပန်းစားသော အနုပညာရှင်များ';

  @override
  String get popularGenres => 'ရေပန်းစားသော ဂီတအမျိုးအစားများ';

  @override
  String get popularSongs => 'ရေပန်းစားသော သီချင်းများ';

  @override
  String get popularTracks => 'ရေပန်းစားသော သီချင်းများ';

  @override
  String get popularHitsRightNow => 'လက်ရှိ ရေပန်းစားနေသော သီချင်းများ';

  @override
  String get previous => 'နောက်သို့';

  @override
  String get queue => 'တန်းစီစာရင်း';

  @override
  String get recentSearches => 'လတ်တလော ရှာဖွေမှုများ';

  @override
  String get recommendedForYou => 'သင့်အတွက် အကြံပြုချက်';

  @override
  String get scraping => 'ခြစ်ယူခြင်း';

  @override
  String get search => 'ရှာဖွေရန်';

  @override
  String get searchInAlbum => 'အယ်လ်ဘမ်ထဲတွင် ရှာရန်...';

  @override
  String get searchInLibrary => 'စာကြည့်တိုက်ထဲတွင် ရှာရန်...';

  @override
  String get searchInPlaylist => 'ဖွင့်စာရင်းထဲတွင် ရှာရန်';

  @override
  String get searchLikedSongs => 'Like လုပ်ထားသော သီချင်းများတွင် ရှာရန်...';

  @override
  String get searchPopularSongs => 'ရေပန်းစားသော သီချင်းများတွင် ရှာရန်...';

  @override
  String get selectMarket => 'ဈေးကွက်ကို ရွေးချယ်ပါ';

  @override
  String get settings => 'ဆက်တင်များ';

  @override
  String get showVideoPlayer => 'ဗီဒီယို ပလေယာကို ပြမည်';

  @override
  String get shuffle => 'ရောနှောဖွင့်မည်';

  @override
  String get spotifyCredentials => 'Spotify အထောက်အထားများ';

  @override
  String get suggestedStations => 'အကြံပြုထားသော စတေရှင်များ';

  @override
  String get tracks => 'သီချင်းများ';

  @override
  String get trending => 'ရေပန်းစားနေသော';

  @override
  String get tryAgain => 'ထပ်မံကြိုးစားပါ';

  @override
  String get tryADifferentSearchTerm => 'အခြား ရှာဖွေမှုဝေါဟာရကို စမ်းကြည့်ပါ';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'ရရှိနိုင်ပါက YouTube ပလေယာကို အသုံးပြုမည်';

  @override
  String get video => 'ဗီဒီယို';

  @override
  String get whatDoYouWantToListenTo => 'ဘာကို နားဆင်ချင်ပါသလဲ။';

  @override
  String get youtubeCredentials => 'YouTube အထောက်အထားများ';

  @override
  String get yourLibrary => 'သင်၏ စာကြည့်တိုက်';

  @override
  String get playerscreenviewswitch =>
      'ကစားသမား_မျက်နှာပြင်_မြင်ကွင်း_ပြောင်းရန်';

  @override
  String get addToPlaylist => 'ဖွင့်စာရင်းသို့ ထည့်မည်';

  @override
  String get addToQueue => 'တန်းစီစာရင်းသို့ ထည့်မည်';

  @override
  String get copyId => 'ID ကို ကူးယူမည်';

  @override
  String get copyLink => 'လင့်ခ်ကို ကူးယူမည်';

  @override
  String get discover => 'ရှာဖွေတွေ့ရှိရန်';

  @override
  String get enterYourName => 'သင့်အမည်ကို ထည့်ပါ';

  @override
  String get favorites => 'အကြိုက်ဆုံးများ';

  @override
  String get goToAlbum => 'အယ်လ်ဘမ်သို့ သွားမည်';

  @override
  String get goToArtist => 'အနုပညာရှင်ထံ သွားမည်';

  @override
  String get goToArtistRadio => 'အနုပညာရှင် ရေဒီယိုသို့ သွားမည်';

  @override
  String get goToPlaylist => 'ဖွင့်စာရင်းသို့ သွားမည်';

  @override
  String get goToSongRadio => 'သီချင်း ရေဒီယိုသို့ သွားမည်';

  @override
  String get home => 'ပင်မစာမျက်နှာ';

  @override
  String get myAwesomePlaylist => 'ကျွန်ုပ်၏ အမိုက်စား ဖွင့်စာရင်း';

  @override
  String get myPlaylist => 'ကျွန်ုပ်၏ ဖွင့်စာရင်း';

  @override
  String get newPlaylist1 => 'ဖွင့်စာရင်းအသစ်';

  @override
  String get play => 'ဖွင့်မည်';

  @override
  String get playStation => 'စတေရှင်ကို ဖွင့်မည်';

  @override
  String get playNext => 'နောက်တစ်ခုကို ဖွင့်မည်';

  @override
  String get playlist => 'သီချင်းစာရင်း';

  @override
  String get playlistName => 'ဖွင့်စာရင်း အမည်';

  @override
  String get playlists1 => 'ဖွင့်စာရင်းများ';

  @override
  String get queue1 => 'တန်းစီစာရင်း';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueUpNext => 'Up next';

  @override
  String get recentlyPlayed => 'လတ်တလော ဖွင့်ထားသည်များ';

  @override
  String get removeFromQueue => 'တန်းစီစာရင်းမှ ဖယ်ရှားမည်';

  @override
  String get retry => 'ထပ်မံကြိုးစားမည်';

  @override
  String get searchMusicArtistsAlbums =>
      'ဂီတ၊ အနုပညာရှင်၊ အယ်လ်ဘမ်များကို ရှာရန်...';

  @override
  String get share => 'မျှဝေရန်';

  @override
  String featuringArtist(String artistName) {
    return '$artistName ပါဝင်သည်';
  }

  @override
  String currentCountry(String country) {
    return 'လက်ရှိ: $country';
  }

  @override
  String get queueTooltip => 'တန်းစီစာရင်း';

  @override
  String get searchHint => 'ဂီတ၊ အနုပညာရှင်၊ အယ်လ်ဘမ်များကို ရှာရန်...';

  @override
  String get language => 'ဘာသာစကား';

  @override
  String get systemDefault => 'စနစ် မူလသတ်မှတ်ချက်';

  @override
  String get songsTab => 'သီချင်းများ';

  @override
  String get foldersTab => 'ဖိုင်တွဲများ';

  @override
  String get artistsTab => 'အနုပညာရှင်များ';

  @override
  String get albumsTab => 'အယ်လ်ဘမ်များ';

  @override
  String get genresTab => 'အမျိုးအစားများ';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'ဖွင့်သည့်အမြန်နှုန်း';

  @override
  String get addMusic => 'တေးဂီတ ပေါင်းထည့်ရန်';

  @override
  String get addFiles => 'ဖိုင်များ ပေါင်းထည့်ရန်';

  @override
  String get addFolder => 'ဖိုင်တွဲ ပေါင်းထည့်ရန်';

  @override
  String get rescanLibrary => 'ဒစ်ဂျစ်တယ် စာကြည့်တိုက်ကို ပြန်လည်စကင်ဖတ်ရန်';

  @override
  String get sortTitle => 'ခေါင်းစဉ်အလိုက် စီရန်';

  @override
  String get sortArtist => 'အနုပညာရှင်အလိုက် စီရန်';

  @override
  String get sortAlbum => 'အယ်လ်ဘမ်အလိုက် စီရန်';

  @override
  String get sortDuration => 'ကြာချိန်အလိုက် စီရန်';

  @override
  String get sortDateAdded => 'ပေါင်းထည့်သည့်ရက်စွဲအလိုက် စီရန်';

  @override
  String get sortBy => 'စီစဥ်ရန်';

  @override
  String get trackInformation => 'တေးသွား အချက်အလက်';

  @override
  String get removeFromLibrary => 'ဒစ်ဂျစ်တယ် စာကြည့်တိုက်မှ ဖယ်ရှားရန်';

  @override
  String get showInFolder => 'ဖိုင်တွဲတွင် ပြရန်';

  @override
  String get unknownArtist => 'အမည်မသိ အနုပညာရှင်';

  @override
  String get unknownAlbum => 'အမည်မသိ အယ်လ်ဘမ်';

  @override
  String get importedFiles => 'တင်သွင်းထားသော ဖိုင်များ';

  @override
  String get playFolder => 'ဖိုင်တွဲ ဖွင့်ရန်';

  @override
  String get shuffleFolder => 'ဖိုင်တွဲ ရောမွှေရန်';

  @override
  String get playAll => 'အားလုံး ဖွင့်ရန်';

  @override
  String get includeSubfolders => 'ဖိုင်တွဲခွဲများ ပါဝင်ရန်';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count တေးသွား',
      one: '1 တေးသွား',
      zero: '0 တေးသွား',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'ဒေသန္တရ သီချင်းများ မတွေ့ပါ';

  @override
  String get searchLocalMusic => 'ဒေသန္တရ တေးဂီတကို ရှာရန်...';

  @override
  String get viewAsList => 'စာရင်းအဖြစ် ကြည့်ရန်';

  @override
  String get viewAsGrid => 'ဇယားကွက်အဖြစ် ကြည့်ရန်';

  @override
  String get trackInfoPath => 'လမ်းကြောင်း';

  @override
  String get trackInfoFormat => 'ဖော်မတ်';

  @override
  String get trackInfoDuration => 'ကြာချိန်';

  @override
  String get aboutDescription => 'အခမဲ့နှင့် open-source မီဒီယာဖွင့်စက်။';

  @override
  String get aboutApp => 'PPPlayer အကြောင်း';

  @override
  String get appTagline => 'သင်၏ တေးဂီတ။ သင်၏ စတိုင်။';

  @override
  String get exploreApp => 'PPPlayer ကို လေ့လာရန်';

  @override
  String get viewSource => 'အရင်းအမြစ်ကုဒ် ကြည့်ရန်';

  @override
  String get seeWhatsNew => 'အသစ်များကို ကြည့်ရန်';

  @override
  String get getHelp => 'အကူအညီ ရယူရန်';

  @override
  String versionInfo(Object version, Object build) {
    return 'ဗားရှင်း $version (တည်ဆောက်မှု $build)';
  }

  @override
  String get createdBy => 'Lucas Coelho မှ ဖန်တီးသည်';

  @override
  String get website => 'ဝဘ်ဆိုက်';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'ထုတ်ဝေမှု မှတ်စုများ';

  @override
  String get support => 'ပံ့ပိုးမှု';

  @override
  String get license => 'လိုင်စင်';

  @override
  String get acknowledgments => 'အသိအမှတ်ပြုမှုများ';

  @override
  String get close => 'ပိတ်ရန်';

  @override
  String copyright(Object year) {
    return '© $year PPPlayer ပါဝင်ကူညီသူများ';
  }

  @override
  String get goodMorning => 'မင်္ဂလာနံနက်ခင်းပါ';

  @override
  String get goodAfternoon => 'မင်္ဂလာမွန်းလွဲခင်းပါ';

  @override
  String get goodEvening => 'မင်္ဂလာညချမ်းပါ';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'သင့်သီချင်းများ စောင့်နေပါသည်။';

  @override
  String dailyMix(Object number) {
    return 'နေ့စဉ် Mix $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'သင်နှစ်သက်သော\nနှင့် အသစ်တွေ့ရှိမှုများ';

  @override
  String get discoverWeekly => 'အပတ်စဉ် ရှာဖွေပါ';

  @override
  String get releaseRadar => 'အသစ်ထွက်ရှိမှု';

  @override
  String get newMusicJustForYou => 'သင့်အတွက်သီးသန့်\nသီချင်းသစ်များ';

  @override
  String get chillMix => 'Chill Mix';

  @override
  String get relaxAndUnwind => 'အနားယူပါ';

  @override
  String get focusMix => 'Focus Mix';

  @override
  String get deepFocusAndProductivity =>
      'နက်ရှိုင်းသောအာရုံစိုက်မှု\nနှင့် ကုန်ထုတ်စွမ်းအား';

  @override
  String artistRadio(Object artist) {
    return '$artist ရေဒီယို';
  }

  @override
  String genreRadio(Object genre) {
    return '$genre ရေဒီယို';
  }

  @override
  String get filterAll => 'အားလုံး';

  @override
  String get filterPlaylists => 'အစီအစဉ်များ';

  @override
  String get filterArtists => 'အနုပညာရှင်များ';

  @override
  String get filterAlbums => 'အယ်လ်ဘမ်များ';

  @override
  String get filterStations => 'စခန်းများ';

  @override
  String get filterStreams => 'စထရင်းများ';

  @override
  String get localMusicCard => 'ပြည်တွင်းတေးဂီတ';

  @override
  String get createPlaylistButton => 'အစီအစဉ်ဖန်တီးရန်';

  @override
  String get radioStations => 'ရေဒီယိုစခန်းများ';

  @override
  String get discoverMusic => 'တေးဂီတရှာဖွေရန်';

  @override
  String get importLocalMusic => 'ပြည်တွင်းတေးဂီတသွင်းရန်';

  @override
  String get importAudioFiles => 'အသံဖိုင်များသွင်းရန်';

  @override
  String get importFolder => 'ဖိုင်တွဲသွင်းရန်';

  @override
  String get importFolderSubtitle => 'အသံဖိုင်များပါသော ဖိုင်တွဲကို ရွေးပါ';

  @override
  String get importPlaylist => 'ဖွင့်ရန်စာရင်းကို တင်သွင်းရန်';

  @override
  String get importPlaylistSubtitle =>
      '.m3u သို့မဟုတ် .m3u8 ဖိုင်ကို တင်သွင်းရန်';

  @override
  String get exportPlaylist => 'ဖွင့်ရန်စာရင်းကို ထုတ်ယူရန်';

  @override
  String get playbackErrorUnsupportedFormat =>
      'ပံ့ပိုးမထားသောဖော်မတ် သို့မဟုတ် ဖိုင်ပျက်စီးနေသည်';

  @override
  String get playbackErrorFileInaccessible =>
      'ဖိုင်ကိုဝင်သုံး၍မရပါ သို့မဟုတ် ရှာမတွေ့ပါ';

  @override
  String get localVideosCard => 'စက်တွင်း ဗီဒီယိုများ';

  @override
  String get noLocalVideos => 'ဗီဒီယိုများ မတွေ့ပါ';

  @override
  String get searchLocalVideos => 'စက်တွင်း ဗီဒီယိုများကို ရှာရန်';

  @override
  String get addVideos => 'ဗီဒီယိုများ ထည့်ရန်';

  @override
  String get subtitles => 'စာတန်းထိုးများ';

  @override
  String get audioTracks => 'အသံဖိုင်များ';

  @override
  String get loadSubtitleFile => 'စာတန်းထိုးဖိုင်ကို ထည့်သွင်းရန်...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'စာတန်းထိုး ဖွင့်ရာတွင် အမှားအယွင်းဖြစ်နေပါသည်: $error';
  }

  @override
  String get off => 'ပိတ်ရန်';

  @override
  String get playOn => 'ဤနေရာတွင် ဖွင့်ရန်';

  @override
  String get thisDevice => 'ဤစက်';

  @override
  String get availableDevices => 'အသုံးပြုနိုင်သော စက်များ';

  @override
  String get searchingDevices => 'စက်များ ရှာဖွေနေသည်…';

  @override
  String get refresh => 'ပြန်လည်ဖွင့်ရန်';

  @override
  String get connecting => 'ချိတ်ဆက်နေသည်…';

  @override
  String connectingTo(String name) {
    return '$name သို့ ချိတ်ဆက်နေသည်…';
  }

  @override
  String get connected => 'ချိတ်ဆက်ပြီး';

  @override
  String get unsupportedOutput => 'ဤရင်းမြစ်ကို ဤအထွက်တွင် ဖွင့်မရပါ။';

  @override
  String get airPlayAudioOutput => 'AirPlay နှင့် အသံအထွက်';

  @override
  String get returnForAirPlay => 'AirPlay သုံးရန် ဤစက်တွင် ဖွင့်ပါ။';

  @override
  String get openSoundSettings => 'အထွက်ရွေးရန် အသံဆက်တင်များကို ဖွင့်ပါ။';

  @override
  String get soundSettingsError => 'အသံဆက်တင်များကို ဖွင့်မရပါ။';

  @override
  String get systemOutput => 'စနစ်အသံအထွက်';

  @override
  String playingOn(String name) {
    return '$name တွင် ဖွင့်နေသည်';
  }

  @override
  String get chooseAirPlay =>
      'စပီကာ သို့မဟုတ် တီဗီရွေးရန် AirPlay ခလုတ်ကို နှိပ်ပါ။';

  @override
  String get airPlayDevice => 'AirPlay စက်';

  @override
  String get playOnIphone => 'ဤ iPhone တွင် ဖွင့်ရန်';

  @override
  String get chooseIphone => 'အောက်ရှိ AirPlay ခလုတ်ဖြင့် ဤ iPhone ကို ရွေးပါ။';

  @override
  String get profile => 'ပရိုဖိုင်';

  @override
  String get preferences => 'ဦးစားပေး ဆက်တင်များ';

  @override
  String get themeColor => 'အပြင်အဆင်အရောင်';

  @override
  String get yourMusic => 'သင့်တေးဂီတ';

  @override
  String get apiCredentials => 'API အထောက်အထားများ';

  @override
  String get dataStorage => 'ဒေတာနှင့် သိုလှောင်မှု';

  @override
  String get editProfileHelp => 'သင့်အမည်နှင့် ကိုယ်ပွားပုံ သတ်မှတ်ပါ';

  @override
  String get customProvider => 'စိတ်ကြိုက် ပံ့ပိုးသူ';

  @override
  String get defaultProvider => 'PPPlayer မူလသတ်မှတ်ချက်';

  @override
  String get proExperience => 'Pro အတွေ့အကြုံ ဖွင့်ထားသည်';

  @override
  String get beta => 'စမ်းသပ်ဗားရှင်း';

  @override
  String get loading => 'တင်နေသည်…';

  @override
  String get unknown => 'မသိရ';

  @override
  String get pause => 'ခေတ္တရပ်ရန်';

  @override
  String get repeat => 'ထပ်ဖွင့်ရန်';

  @override
  String get mute => 'အသံပိတ်ရန်';

  @override
  String get unmute => 'အသံဖွင့်ရန်';

  @override
  String get fitVideo => 'အံဝင်အောင်';

  @override
  String get fillVideo => 'ပြည့်အောင်';

  @override
  String get fullscreen => 'မျက်နှာပြင်အပြည့်';

  @override
  String get exitFullscreen => 'မျက်နှာပြင်အပြည့်မှ ထွက်ရန်';

  @override
  String get volume => 'အသံအတိုးအကျယ်';

  @override
  String get save => 'သိမ်းရန်';

  @override
  String get delete => 'ဖျက်ရန်';

  @override
  String get clear => 'ရှင်းရန်';

  @override
  String get follow => 'လိုက်ရန်';

  @override
  String get unfollow => 'မလိုက်တော့ရန်';

  @override
  String get following => 'လိုက်နေသည်';

  @override
  String get showAll => 'အားလုံးပြရန်';

  @override
  String get appearance => 'အသွင်အပြင်';

  @override
  String get subtitleSize => 'အရွယ်အစား';

  @override
  String get subtitleBackground => 'နောက်ခံ';

  @override
  String get earlier => 'စောစေရန်';

  @override
  String get later => 'နောက်ကျစေရန်';

  @override
  String get reset => 'ပြန်သတ်မှတ်ရန်';

  @override
  String subtitleDelay(String seconds) {
    return 'နှောင့်နှေးမှု: $seconds စက္ကန့်';
  }

  @override
  String get morePlaybackControls => 'နောက်ထပ် ဖွင့်ခြင်းထိန်းချုပ်မှုများ';

  @override
  String get hideVideo => 'ဗီဒီယိုဖျောက်ရန်';

  @override
  String get showVideo => 'ဗီဒီယိုပြရန်';

  @override
  String get closeQueue => 'အစီအစဉ်ပိတ်ရန်';

  @override
  String get enabled => 'ဖွင့်ထားသည်';

  @override
  String get openFile => 'ဖိုင်ဖွင့်ရန်…';

  @override
  String get openFolder => 'ဖိုင်တွဲဖွင့်ရန်…';

  @override
  String get openUrl => 'URL ဖွင့်ရန်…';

  @override
  String get fileMenu => 'ဖိုင်';

  @override
  String get viewMenu => 'မြင်ကွင်း';

  @override
  String get windowMenu => 'ဝင်းဒိုး';

  @override
  String get saveChanges => 'အပြောင်းအလဲများ သိမ်းရန်';

  @override
  String get themeAvatarColor => 'အပြင်အဆင်နှင့် ကိုယ်ပွားအရောင်';

  @override
  String get networkStreams => 'ကွန်ရက်စီးကြောင်းများ';

  @override
  String get networkStream => 'ကွန်ရက်စီးကြောင်း';

  @override
  String get openNetworkStream => 'ကွန်ရက်စီးကြောင်းဖွင့်ရန်';

  @override
  String get editPlaylist => 'အစီအစဉ်ပြင်ရန်';

  @override
  String get editStreamItem => 'စီးကြောင်းအရာ ပြင်ရန်';

  @override
  String get streamUrl => 'စီးကြောင်း URL';

  @override
  String get platformType => 'ပလက်ဖောင်း / အမျိုးအစား';

  @override
  String get optionalTitle => 'ခေါင်းစဉ် (မဖြစ်မနေ မလို)';

  @override
  String get optionalImageUrl => 'ပုံ URL (မဖြစ်မနေ မလို)';

  @override
  String get myStream => 'ကျွန်ုပ်၏စီးကြောင်း';

  @override
  String get saveToLibrary => 'စာကြည့်တိုက်တွင် သိမ်းရန်';

  @override
  String get justPlay => 'ဖွင့်ရုံသာ';

  @override
  String get autoDetect => 'အလိုအလျောက် ရှာဖွေရန်';

  @override
  String get apiKeyRequired => 'API သော့ လိုအပ်သည်';

  @override
  String get customApiKey => 'ကိုယ်ပိုင် API သော့သုံးရန်';

  @override
  String get clientId => 'ဖောက်သည် ID';

  @override
  String get clientSecret => 'ဖောက်သည် လျှို့ဝှက်သော့';

  @override
  String get saveCredentials => 'အထောက်အထားများ သိမ်းရန်';

  @override
  String get searchStrategy => 'ရှာဖွေနည်း';

  @override
  String get credentialsLocalOnly =>
      'ဤစက်တွင် လုံခြုံစွာ သိမ်းထားသည်။ PPPlayer သို့ လုံးဝ မပို့ပါ။';

  @override
  String get scrapingHelp =>
      'API သော့ သို့မဟုတ် သတ်မှတ်ပမာဏ မလိုပါ။ ပိုနှေး သို့မဟုတ် ယုံကြည်ရမှုနည်းနိုင်သည်။';

  @override
  String get streamHelp => 'HTTP(S) URL သို့မဟုတ် M3U အစီအစဉ်လင့်ခ် ထည့်ပါ။';

  @override
  String get deletePlaylistConfirm => 'ဤအစီအစဉ်ကို အပြီးဖျက်မလား?';

  @override
  String get clearCacheConfirm =>
      'ယာယီဒေတာ ဖျက်မလား? စာကြည့်တိုက်နှင့် နှစ်သက်ရာများ မပြောင်းပါ။';

  @override
  String get clearHistoryConfirm => 'နားထောင်မှုမှတ်တမ်း အပြီးဖျက်မလား?';

  @override
  String get addedToQueue => 'အစီအစဉ်ထဲ ထည့်ပြီး';

  @override
  String get addedVideo => 'ဗီဒီယိုထည့်ပြီး';

  @override
  String addedChannels(String count) {
    return 'ထည့်ထားသောလိုင်းများ: $count';
  }

  @override
  String get removedFromPlaylist => 'အစီအစဉ်မှ ဖယ်ပြီး';

  @override
  String get exportCancelled => 'ထုတ်ယူမှု ပယ်ဖျက်ပြီး';

  @override
  String exportComplete(String count) {
    return 'အစီအစဉ်ထုတ်ယူပြီး။ ကျော်ထားသည့်အရာများ: $count';
  }

  @override
  String get playlistExported => 'အစီအစဉ်ထုတ်ယူပြီး';

  @override
  String get live => 'တိုက်ရိုက်';

  @override
  String get sponsored => 'ပံ့ပိုးထားသည်';

  @override
  String get removeFromPlaylist => 'အစီအစဉ်မှ ဖယ်ရန်';

  @override
  String get likedSongsHelp => 'ဤနေရာတွင် မြင်ရန် သီချင်းများ သိမ်းပါ';

  @override
  String get apiSingleVideoHint =>
      'အစီအစဉ်မတင်သွင်းဘဲ ဤဗီဒီယိုကို ထည့်နိုင်သည်။';

  @override
  String get linkCopied => 'လင့်ခ်ကူးပြီး';

  @override
  String get willPlayNext => 'နောက်တစ်ခု ဖွင့်မည်';

  @override
  String get checkItOut => 'ကြည့်ရန်';

  @override
  String get loadFailed => 'အကြောင်းအရာကို မဖွင့်နိုင်ပါ။ ထပ်မံကြိုးစားပါ။';
}
