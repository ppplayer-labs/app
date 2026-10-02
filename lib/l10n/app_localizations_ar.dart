// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title، $subtitle';
  }

  @override
  String get albums => 'ألبومات';

  @override
  String get api => 'API';

  @override
  String get artists => 'فنانين';

  @override
  String get artwork => 'صورة الغلاف';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get artist => 'فنان';

  @override
  String get artistsYouFollow => 'فنانون تتابعهم';

  @override
  String get autoplay => 'تشغيل تلقائي';

  @override
  String get becauseYouListenedTo => 'لأنك استمعت إلى';

  @override
  String get browseAll => 'تصفح الكل';

  @override
  String get cancel => 'إلغاء';

  @override
  String get clearAppCache => 'هل تريد مسح ذاكرة التخزين المؤقت للتطبيق؟';

  @override
  String get clearCache => 'مسح ذاكرة التخزين المؤقت';

  @override
  String get clearHistory => 'هل تريد مسح السجل؟';

  @override
  String get clearRecentlyPlayed => 'مسح المشغلة مؤخرًا';

  @override
  String get contentMarket => 'سوق المحتوى';

  @override
  String get continueListening => 'متابعة الاستماع';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'متابعة تشغيل الفيديو في نافذة صغيرة';

  @override
  String get create => 'إنشاء';

  @override
  String get createAPlaylistToGetStarted => 'أنشئ قائمة تشغيل للبدء';

  @override
  String currentSelectedcountry(Object country) {
    return 'الحالي: $country';
  }

  @override
  String get deletePlaylist => 'حذف قائمة التشغيل';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String errorLoadingMarkets(Object err) {
    return 'خطأ في تحميل الأسواق: $err';
  }

  @override
  String error(Object error) {
    return 'خطأ: $error';
  }

  @override
  String explore(Object genre) {
    return 'استكشف $genre';
  }

  @override
  String get fansAlsoLike => 'المعجبون يحبون أيضًا';

  @override
  String featuringTouppercase(Object artist) {
    return 'بمشاركة $artist';
  }

  @override
  String get featuredPlaylists => 'قوائم التشغيل المميزة';

  @override
  String get followArtistsToSeeThemHere => 'تابع الفنانين لرؤيتهم هنا';

  @override
  String get followStationsToSeeThemHere => 'تابع المحطات لرؤيتها هنا';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'فرض تشغيل الصوت فقط لتوفير البيانات';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'يوفر المساحة ويفرض تنزيل بيانات جديدة عند التحميل التالي';

  @override
  String get fromYourFavorites => 'من مفضلاتك';

  @override
  String get goBack => 'رجوع';

  @override
  String inspiredByName(Object name) {
    return 'مستوحى من $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'الاستمرار في تشغيل مقاطع مشابهة عند انتهاء قائمة الانتظار';

  @override
  String get library => 'المكتبة';

  @override
  String get likeAlbumsToSeeThemHere => 'أعجب بالألبومات لرؤيتها هنا';

  @override
  String get likedSongs => 'الأغاني التي أعجبتك';

  @override
  String get lowDataMode => 'وضع توفير البيانات';

  @override
  String get madeForYou => 'مخصص لك';

  @override
  String moreLikeName(Object name) {
    return 'المزيد مثل $name';
  }

  @override
  String get moreOptions => 'خيارات إضافية';

  @override
  String get nameYourMasterpiece => 'أعطِ اسمًا لتحفتك...';

  @override
  String get newPlaylist => 'قائمة تشغيل جديدة';

  @override
  String get newReleases => 'إصدارات جديدة';

  @override
  String get next => 'التالي';

  @override
  String get noAlbumsFound => 'لم يتم العثور على ألبومات';

  @override
  String get noArtistsFollowed => 'لم تتم متابعة أي فنان';

  @override
  String get noArtistsFound => 'لم يتم العثور على فنانين';

  @override
  String get noLikedAlbums => 'لا توجد ألبومات معجب بها';

  @override
  String get noPlaylistsFound => 'لم يتم العثور على قوائم تشغيل';

  @override
  String get noPlaylistsYet => 'لا توجد قوائم تشغيل بعد';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String get noStationsFollowed => 'لم تتم متابعة أي محطة';

  @override
  String get noTrackPlaying => 'لا يوجد مقطع قيد التشغيل';

  @override
  String get noTracksFound => 'لم يتم العثور على مقاطع';

  @override
  String get playlists => 'قوائم التشغيل';

  @override
  String get popular => 'شائع';

  @override
  String get permanentlyRemoveListeningHistory => 'حذف سجل الاستماع نهائيًا';

  @override
  String get pictureinpicturePip => 'صورة داخل صورة (PiP)';

  @override
  String get popularAlbums => 'ألبومات شائعة';

  @override
  String get popularArtists => 'فنانون شائعون';

  @override
  String get popularGenres => 'أنواع الموسيقى الشائعة';

  @override
  String get popularSongs => 'أغاني شائعة';

  @override
  String get popularTracks => 'مقاطع شائعة';

  @override
  String get popularHitsRightNow => 'أغاني ضاربة الآن';

  @override
  String get previous => 'السابق';

  @override
  String get queue => 'قائمة الانتظار';

  @override
  String get recentSearches => 'عمليات البحث الأخيرة';

  @override
  String get recommendedForYou => 'موصى به لك';

  @override
  String get scraping => 'جاري الاستخراج';

  @override
  String get search => 'بحث';

  @override
  String get searchInAlbum => 'ابحث في الألبوم...';

  @override
  String get searchInLibrary => 'ابحث في المكتبة...';

  @override
  String get searchInPlaylist => 'ابحث في قائمة التشغيل';

  @override
  String get searchLikedSongs => 'ابحث في الأغاني التي أعجبتك...';

  @override
  String get searchPopularSongs => 'ابحث عن الأغاني الشائعة...';

  @override
  String get selectMarket => 'اختر السوق';

  @override
  String get settings => 'الإعدادات';

  @override
  String get showVideoPlayer => 'إظهار مشغل الفيديو';

  @override
  String get shuffle => 'تشغيل عشوائي';

  @override
  String get spotifyCredentials => 'بيانات اعتماد Spotify';

  @override
  String get suggestedStations => 'محطات مقترحة';

  @override
  String get tracks => 'مقاطع';

  @override
  String get trending => 'رائج';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get tryADifferentSearchTerm => 'جرب مصطلح بحث مختلف';

  @override
  String get useYoutubePlayerWhenAvailable => 'استخدم مشغل YouTube عند توفره';

  @override
  String get video => 'فيديو';

  @override
  String get whatDoYouWantToListenTo => 'ماذا تريد أن تستمع إليه؟';

  @override
  String get youtubeCredentials => 'بيانات اعتماد YouTube';

  @override
  String get yourLibrary => 'مكتبتك';

  @override
  String get playerscreenviewswitch => 'تبديل_عرض_شاشة_اللاعب';

  @override
  String get addToPlaylist => 'أضف إلى قائمة التشغيل';

  @override
  String get addToQueue => 'أضف إلى قائمة الانتظار';

  @override
  String get copyId => 'نسخ المعرف';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get discover => 'اكتشف';

  @override
  String get enterYourName => 'أدخل اسمك';

  @override
  String get favorites => 'المفضلة';

  @override
  String get goToAlbum => 'انتقل إلى الألبوم';

  @override
  String get goToArtist => 'انتقل إلى الفنان';

  @override
  String get goToArtistRadio => 'انتقل إلى راديو الفنان';

  @override
  String get goToPlaylist => 'انتقل إلى قائمة التشغيل';

  @override
  String get goToSongRadio => 'انتقل إلى راديو الأغنية';

  @override
  String get home => 'الرئيسية';

  @override
  String get myAwesomePlaylist => 'قائمة تشغيل رائعة الخاصة بي';

  @override
  String get myPlaylist => 'قائمتي';

  @override
  String get newPlaylist1 => 'قائمة تشغيل جديدة';

  @override
  String get play => 'تشغيل';

  @override
  String get playStation => 'تشغيل المحطة';

  @override
  String get playNext => 'تشغيل التالي';

  @override
  String get playlist => 'قائمة تشغيل';

  @override
  String get playlistName => 'اسم قائمة التشغيل';

  @override
  String get playlists1 => 'قوائم التشغيل';

  @override
  String get queue1 => 'قائمة الانتظار';

  @override
  String get recentlyPlayed => 'تم تشغيلها مؤخرًا';

  @override
  String get removeFromQueue => 'إزالة من قائمة الانتظار';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get searchMusicArtistsAlbums =>
      'البحث عن الموسيقى، الفنانين، الألبومات...';

  @override
  String get share => 'مشاركة';

  @override
  String featuringArtist(String artistName) {
    return 'بمشاركة $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'الحالي: $country';
  }

  @override
  String get queueTooltip => 'قائمة الانتظار';

  @override
  String get searchHint => 'البحث عن الموسيقى والفنانين والألبومات...';

  @override
  String get language => 'اللغة';

  @override
  String get systemDefault => 'الافتراضي للنظام';

  @override
  String get songsTab => 'الأغاني';

  @override
  String get foldersTab => 'المجلدات';

  @override
  String get artistsTab => 'الفنانين';

  @override
  String get albumsTab => 'الألبومات';

  @override
  String get genresTab => 'الأنواع';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'سرعة التشغيل';

  @override
  String get addMusic => 'إضافة موسيقى';

  @override
  String get addFiles => 'إضافة ملفات';

  @override
  String get addFolder => 'إضافة مجلد';

  @override
  String get rescanLibrary => 'إعادة فحص المكتبة';

  @override
  String get sortTitle => 'الترتيب حسب العنوان';

  @override
  String get sortArtist => 'الترتيب حسب الفنان';

  @override
  String get sortAlbum => 'الترتيب حسب الألبوم';

  @override
  String get sortDuration => 'الترتيب حسب المدة';

  @override
  String get sortDateAdded => 'الترتيب حسب تاريخ الإضافة';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get trackInformation => 'معلومات المسار';

  @override
  String get removeFromLibrary => 'إزالة من المكتبة';

  @override
  String get showInFolder => 'عرض في المجلد';

  @override
  String get unknownArtist => 'فنان غير معروف';

  @override
  String get unknownAlbum => 'ألبوم غير معروف';

  @override
  String get importedFiles => 'الملفات المستوردة';

  @override
  String get playFolder => 'تشغيل المجلد';

  @override
  String get shuffleFolder => 'تشغيل المجلد عشوائياً';

  @override
  String get playAll => 'تشغيل الكل';

  @override
  String get includeSubfolders => 'تضمين المجلدات الفرعية';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقطع',
      many: '$count مقطعًا',
      few: '$count مقاطع',
      two: 'مقطعان',
      one: 'مقطع واحد',
      zero: '0 مقطع',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'لم يتم العثور على أغانٍ محلية';

  @override
  String get searchLocalMusic => 'البحث في الموسيقى المحلية...';

  @override
  String get viewAsList => 'عرض كقائمة';

  @override
  String get viewAsGrid => 'عرض كشبكة';

  @override
  String get trackInfoPath => 'المسار';

  @override
  String get trackInfoFormat => 'التنسيق';

  @override
  String get trackInfoDuration => 'المدة';

  @override
  String get aboutDescription => 'مشغل وسائط مجاني ومفتوح المصدر.';

  @override
  String get aboutApp => 'حول PPPlayer';

  @override
  String get appTagline => 'موسيقاك. على طريقتك.';

  @override
  String get exploreApp => 'استكشاف PPPlayer';

  @override
  String get viewSource => 'عرض المصدر';

  @override
  String get seeWhatsNew => 'ما الجديد';

  @override
  String get getHelp => 'الحصول على المساعدة';

  @override
  String versionInfo(Object version, Object build) {
    return 'الإصدار $version (النسخة $build)';
  }

  @override
  String get createdBy => 'تم الإنشاء بواسطة Lucas Coelho';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'ملاحظات الإصدار';

  @override
  String get support => 'الدعم';

  @override
  String get license => 'الترخيص';

  @override
  String get acknowledgments => 'شكر وتقدير';

  @override
  String get close => 'إغلاق';

  @override
  String copyright(Object year) {
    return '© $year مساهمو PPPlayer';
  }

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'موسيقاك في انتظارك.';

  @override
  String dailyMix(Object number) {
    return 'ميكس يومي $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries => 'مفضلاتك\nواكتشافات جديدة';

  @override
  String get discoverWeekly => 'اكتشف هذا الأسبوع';

  @override
  String get releaseRadar => 'رادار الإصدارات';

  @override
  String get newMusicJustForYou => 'موسيقى جديدة\nخصيصاً لك';

  @override
  String get chillMix => 'ميكس هادئ';

  @override
  String get relaxAndUnwind => 'استرخِ واستمتع';

  @override
  String get focusMix => 'ميكس للتركيز';

  @override
  String get deepFocusAndProductivity => 'تركيز عميق\nوإنتاجية';

  @override
  String artistRadio(Object artist) {
    return 'راديو $artist';
  }

  @override
  String genreRadio(Object genre) {
    return 'راديو $genre';
  }

  @override
  String get filterAll => 'الكل';

  @override
  String get filterPlaylists => 'قوائم التشغيل';

  @override
  String get filterArtists => 'الفنانون';

  @override
  String get filterAlbums => 'الألبومات';

  @override
  String get filterStations => 'المحطات';

  @override
  String get filterStreams => 'البث المباشر';

  @override
  String get localMusicCard => 'موسيقى محلية';

  @override
  String get createPlaylistButton => 'إنشاء قائمة تشغيل';

  @override
  String get radioStations => 'محطات الراديو';

  @override
  String get discoverMusic => 'اكتشاف الموسيقى';

  @override
  String get importLocalMusic => 'استيراد موسيقى محلية';

  @override
  String get importAudioFiles => 'استيراد ملفات صوتية';

  @override
  String get importFolder => 'استيراد مجلد';

  @override
  String get importFolderSubtitle => 'اختر مجلدًا يحتوي على ملفات صوتية';

  @override
  String get importPlaylist => 'استيراد قائمة تشغيل';

  @override
  String get importPlaylistSubtitle => 'استيراد ملفات .m3u أو .m3u8';

  @override
  String get exportPlaylist => 'تصدير قائمة تشغيل';

  @override
  String get playbackErrorUnsupportedFormat => 'تنسيق غير مدعوم أو ملف تالف';

  @override
  String get playbackErrorFileInaccessible =>
      'تعذر الوصول إلى الملف أو لم يتم العثور عليه';

  @override
  String get localVideosCard => 'مقاطع فيديو محلية';

  @override
  String get noLocalVideos => 'لم يتم العثور على مقاطع فيديو';

  @override
  String get searchLocalVideos => 'البحث في مقاطع الفيديو المحلية';

  @override
  String get addVideos => 'إضافة مقاطع فيديو';

  @override
  String get subtitles => 'الترجمات';

  @override
  String get audioTracks => 'المقاطع الصوتية';

  @override
  String get loadSubtitleFile => 'تحميل ملف ترجمة...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'حدث خطأ أثناء تحميل الترجمة: $error';
  }

  @override
  String get off => 'إيقاف';

  @override
  String get playOn => 'التشغيل على';

  @override
  String get thisDevice => 'هذا الجهاز';

  @override
  String get availableDevices => 'الأجهزة المتاحة';

  @override
  String get searchingDevices => 'جارٍ البحث عن أجهزة…';

  @override
  String get refresh => 'تحديث';

  @override
  String get connecting => 'جارٍ الاتصال…';

  @override
  String connectingTo(String name) {
    return 'جارٍ الاتصال بـ $name…';
  }

  @override
  String get connected => 'متصل';

  @override
  String get unsupportedOutput => 'لا يمكن تشغيل هذا المصدر على هذا المخرج.';

  @override
  String get airPlayAudioOutput => 'AirPlay ومخرج الصوت';

  @override
  String get returnForAirPlay => 'شغّل على هذا الجهاز لاستخدام AirPlay.';

  @override
  String get openSoundSettings => 'افتح إعدادات الصوت لاختيار مخرج.';

  @override
  String get soundSettingsError => 'تعذر فتح إعدادات الصوت.';

  @override
  String get systemOutput => 'مخرج النظام';

  @override
  String playingOn(String name) {
    return 'جارٍ التشغيل على $name';
  }

  @override
  String get chooseAirPlay => 'اضغط زر AirPlay لاختيار مكبر صوت أو تلفاز.';

  @override
  String get airPlayDevice => 'جهاز AirPlay';

  @override
  String get playOnIphone => 'التشغيل على هذا iPhone';

  @override
  String get chooseIphone => 'اختر هذا iPhone باستخدام زر AirPlay أدناه.';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get themeColor => 'لون السمة';

  @override
  String get yourMusic => 'موسيقاك';

  @override
  String get apiCredentials => 'بيانات اعتماد API';

  @override
  String get dataStorage => 'البيانات والتخزين';

  @override
  String get editProfileHelp => 'عيّن اسمك وصورتك الرمزية';

  @override
  String get customProvider => 'موفر مخصص';

  @override
  String get defaultProvider => 'الإعداد الافتراضي لـ PPPlayer';

  @override
  String get proExperience => 'تجربة Pro مفعّلة';

  @override
  String get beta => 'تجريبي';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get unknown => 'غير معروف';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get repeat => 'تكرار';

  @override
  String get mute => 'كتم الصوت';

  @override
  String get unmute => 'إلغاء الكتم';

  @override
  String get fitVideo => 'ملاءمة';

  @override
  String get fillVideo => 'ملء';

  @override
  String get fullscreen => 'ملء الشاشة';

  @override
  String get exitFullscreen => 'الخروج من ملء الشاشة';

  @override
  String get volume => 'مستوى الصوت';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get clear => 'مسح';

  @override
  String get follow => 'متابعة';

  @override
  String get unfollow => 'إلغاء المتابعة';

  @override
  String get following => 'تتم المتابعة';

  @override
  String get showAll => 'عرض الكل';

  @override
  String get appearance => 'المظهر';

  @override
  String get subtitleSize => 'الحجم';

  @override
  String get subtitleBackground => 'الخلفية';

  @override
  String get earlier => 'أبكر';

  @override
  String get later => 'لاحقًا';

  @override
  String get reset => 'إعادة ضبط';

  @override
  String subtitleDelay(String seconds) {
    return 'التأخير: $seconds ث';
  }

  @override
  String get morePlaybackControls => 'المزيد من عناصر التحكم بالتشغيل';

  @override
  String get hideVideo => 'إخفاء الفيديو';

  @override
  String get showVideo => 'عرض الفيديو';

  @override
  String get closeQueue => 'إغلاق قائمة الانتظار';

  @override
  String get enabled => 'مفعّل';

  @override
  String get openFile => 'فتح ملف…';

  @override
  String get openFolder => 'فتح مجلد…';

  @override
  String get openUrl => 'فتح URL…';

  @override
  String get fileMenu => 'ملف';

  @override
  String get viewMenu => 'عرض';

  @override
  String get windowMenu => 'نافذة';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get themeAvatarColor => 'لون السمة والصورة الرمزية';

  @override
  String get networkStreams => 'تدفقات الشبكة';

  @override
  String get networkStream => 'تدفق الشبكة';

  @override
  String get openNetworkStream => 'فتح تدفق شبكة';

  @override
  String get editPlaylist => 'تعديل قائمة التشغيل';

  @override
  String get editStreamItem => 'تعديل عنصر التدفق';

  @override
  String get streamUrl => 'رابط التدفق';

  @override
  String get platformType => 'المنصة / النوع';

  @override
  String get optionalTitle => 'العنوان (اختياري)';

  @override
  String get optionalImageUrl => 'رابط الصورة (اختياري)';

  @override
  String get myStream => 'تدفقي';

  @override
  String get saveToLibrary => 'حفظ في المكتبة';

  @override
  String get justPlay => 'تشغيل فقط';

  @override
  String get autoDetect => 'اكتشاف تلقائي';

  @override
  String get apiKeyRequired => 'مفتاح API مطلوب';

  @override
  String get customApiKey => 'استخدام مفتاح API مخصص';

  @override
  String get clientId => 'معرّف العميل';

  @override
  String get clientSecret => 'سر العميل';

  @override
  String get saveCredentials => 'حفظ بيانات الاعتماد';

  @override
  String get searchStrategy => 'استراتيجية البحث';

  @override
  String get credentialsLocalOnly =>
      'محفوظة بأمان على هذا الجهاز. لا تُرسل أبدًا إلى PPPlayer.';

  @override
  String get scrapingHelp =>
      'لا يتطلب مفتاح API أو حصة. قد يكون أبطأ أو أقل موثوقية.';

  @override
  String get streamHelp => 'أدخل رابط HTTP(S) أو رابط قائمة تشغيل M3U.';

  @override
  String get deletePlaylistConfirm => 'حذف قائمة التشغيل هذه نهائيًا؟';

  @override
  String get clearCacheConfirm =>
      'حذف البيانات المؤقتة؟ ستبقى مكتبتك ومفضلاتك دون تغيير.';

  @override
  String get clearHistoryConfirm => 'حذف سجل استماعك نهائيًا؟';

  @override
  String get addedToQueue => 'أُضيف إلى قائمة الانتظار';

  @override
  String get addedVideo => 'أُضيف الفيديو';

  @override
  String addedChannels(String count) {
    return 'القنوات المضافة: $count';
  }

  @override
  String get removedFromPlaylist => 'أُزيل من قائمة التشغيل';

  @override
  String get exportCancelled => 'أُلغي التصدير';

  @override
  String exportComplete(String count) {
    return 'صُدّرت قائمة التشغيل. العناصر المتجاوزة: $count';
  }

  @override
  String get playlistExported => 'صُدّرت قائمة التشغيل';

  @override
  String get live => 'مباشر';

  @override
  String get sponsored => 'برعاية';

  @override
  String get removeFromPlaylist => 'إزالة من قائمة التشغيل';

  @override
  String get likedSongsHelp => 'احفظ الأغاني لتراها هنا';

  @override
  String get apiSingleVideoHint =>
      'يمكنك إضافة هذا الفيديو دون استيراد قائمة التشغيل.';

  @override
  String get linkCopied => 'نُسخ الرابط';

  @override
  String get willPlayNext => 'سيُشغّل تاليًا';

  @override
  String get checkItOut => 'استكشف';

  @override
  String get loadFailed => 'تعذر تحميل المحتوى. حاول مرة أخرى.';
}
