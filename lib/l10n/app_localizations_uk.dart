// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'АЛЬБОМИ';

  @override
  String get api => 'API';

  @override
  String get artists => 'ВИКОНАВЦІ';

  @override
  String get artwork => 'ОБКЛАДИНКА';

  @override
  String get appVersion => 'Версія програми';

  @override
  String get artist => 'Виконавець';

  @override
  String get artistsYouFollow => 'Виконавці, за якими ви стежите';

  @override
  String get autoplay => 'Автозапуск';

  @override
  String get becauseYouListenedTo => 'Оскільки ви слухали';

  @override
  String get browseAll => 'Переглянути все';

  @override
  String get cancel => 'Скасувати';

  @override
  String get clearAppCache => 'Очистити кеш програми?';

  @override
  String get clearCache => 'Очистити кеш';

  @override
  String get clearHistory => 'Очистити історію?';

  @override
  String get clearRecentlyPlayed => 'Очистити нещодавно відтворене';

  @override
  String get contentMarket => 'Ринок контенту';

  @override
  String get continueListening => 'Продовжити слухати';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Продовжити відтворення відео в маленькому вікні';

  @override
  String get create => 'Створити';

  @override
  String get createAPlaylistToGetStarted =>
      'Створіть список відтворення, щоб почати';

  @override
  String currentSelectedcountry(Object country) {
    return 'Поточна: $country';
  }

  @override
  String get deletePlaylist => 'Видалити список відтворення';

  @override
  String get editProfile => 'Редагувати профіль';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Помилка завантаження ринків: $err';
  }

  @override
  String error(Object error) {
    return 'Помилка: $error';
  }

  @override
  String explore(Object genre) {
    return 'Огляд: $genre';
  }

  @override
  String get fansAlsoLike => 'ШАНУВАЛЬНИКАМ ТАКОЖ ПОДОБАЄТЬСЯ';

  @override
  String featuringTouppercase(Object artist) {
    return 'ЗА УЧАСТЮ $artist';
  }

  @override
  String get featuredPlaylists => 'Рекомендовані списки відтворення';

  @override
  String get followArtistsToSeeThemHere =>
      'Стежте за виконавцями, щоб бачити їх тут';

  @override
  String get followStationsToSeeThemHere =>
      'Стежте за станціями, щоб бачити їх тут';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Примусово використовувати аудіопотоки для економії даних';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Звільняє місце та примусово завантажує нові дані наступного разу';

  @override
  String get fromYourFavorites => 'З ваших улюблених';

  @override
  String get goBack => 'Назад';

  @override
  String inspiredByName(Object name) {
    return 'Натхненно $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Продовжувати відтворення схожих треків, коли черга закінчується';

  @override
  String get library => 'Медіатека';

  @override
  String get likeAlbumsToSeeThemHere => 'Вподобайте альбоми, щоб бачити їх тут';

  @override
  String get likedSongs => 'Улюблені пісні';

  @override
  String get lowDataMode => 'Режим економії даних';

  @override
  String get madeForYou => 'Створено для вас';

  @override
  String moreLikeName(Object name) {
    return 'Більше схожого на $name';
  }

  @override
  String get moreOptions => 'Більше опцій';

  @override
  String get nameYourMasterpiece => 'Назвіть свій шедевр...';

  @override
  String get newPlaylist => 'Новий список відтворення';

  @override
  String get newReleases => 'Нові випуски';

  @override
  String get next => 'Далі';

  @override
  String get noAlbumsFound => 'Альбомів не знайдено';

  @override
  String get noArtistsFollowed => 'Немає виконавців, за якими ви стежите';

  @override
  String get noArtistsFound => 'Виконавців не знайдено';

  @override
  String get noLikedAlbums => 'Немає улюблених альбомів';

  @override
  String get noPlaylistsFound => 'Списків відтворення не знайдено';

  @override
  String get noPlaylistsYet => 'Поки немає списків відтворення';

  @override
  String get noResultsFound => 'Результатів не знайдено';

  @override
  String get noStationsFollowed => 'Немає станцій, за якими ви стежите';

  @override
  String get noTrackPlaying => 'Трек не відтворюється';

  @override
  String get noTracksFound => 'Треків не знайдено';

  @override
  String get playlists => 'СПИСКИ ВІДТВОРЕННЯ';

  @override
  String get popular => 'ПОПУЛЯРНЕ';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Назавжди видалити історію прослуховування';

  @override
  String get pictureinpicturePip => 'Картинка в картинці (PiP)';

  @override
  String get popularAlbums => 'Популярні альбоми';

  @override
  String get popularArtists => 'Популярні виконавці';

  @override
  String get popularGenres => 'Популярні жанри';

  @override
  String get popularSongs => 'Популярні пісні';

  @override
  String get popularTracks => 'Популярні треки';

  @override
  String get popularHitsRightNow => 'Популярні хіти зараз';

  @override
  String get previous => 'Попередній';

  @override
  String get queue => 'ЧЕРГА';

  @override
  String get recentSearches => 'Останні пошуки';

  @override
  String get recommendedForYou => 'Рекомендовано для вас';

  @override
  String get scraping => 'Збір даних';

  @override
  String get search => 'Пошук';

  @override
  String get searchInAlbum => 'Шукати в альбомі...';

  @override
  String get searchInLibrary => 'Шукати в медіатеці...';

  @override
  String get searchInPlaylist => 'Шукати в списку відтворення';

  @override
  String get searchLikedSongs => 'Шукати в улюблених піснях...';

  @override
  String get searchPopularSongs => 'Шукати популярні пісні...';

  @override
  String get selectMarket => 'Вибрати ринок';

  @override
  String get settings => 'Налаштування';

  @override
  String get showVideoPlayer => 'Показати відеоплеєр';

  @override
  String get shuffle => 'У випадковому порядку';

  @override
  String get spotifyCredentials => 'Облікові дані Spotify';

  @override
  String get suggestedStations => 'Пропоновані станції';

  @override
  String get tracks => 'ТРЕКИ';

  @override
  String get trending => 'У тренді';

  @override
  String get tryAgain => 'Спробувати ще раз';

  @override
  String get tryADifferentSearchTerm => 'Спробуйте інший пошуковий запит';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Використовувати плеєр YouTube, якщо доступно';

  @override
  String get video => 'ВІДЕО';

  @override
  String get whatDoYouWantToListenTo => 'Що ви хочете послухати?';

  @override
  String get youtubeCredentials => 'Облікові дані YouTube';

  @override
  String get yourLibrary => 'Ваша медіатека';

  @override
  String get playerscreenviewswitch => 'player_screen_view_switch';

  @override
  String get addToPlaylist => 'Додати до списку відтворення';

  @override
  String get addToQueue => 'Додати до черги';

  @override
  String get copyId => 'Копіювати ID';

  @override
  String get copyLink => 'Копіювати посилання';

  @override
  String get discover => 'Огляд';

  @override
  String get enterYourName => 'Введіть своє ім\'я';

  @override
  String get favorites => 'Улюблене';

  @override
  String get goToAlbum => 'Перейти до альбому';

  @override
  String get goToArtist => 'Перейти до виконавця';

  @override
  String get goToArtistRadio => 'Перейти до радіо виконавця';

  @override
  String get goToPlaylist => 'Перейти до списку відтворення';

  @override
  String get goToSongRadio => 'Перейти до радіо пісні';

  @override
  String get home => 'Головна';

  @override
  String get myAwesomePlaylist => 'Мій чудовий список відтворення';

  @override
  String get myPlaylist => 'Мій список відтворення';

  @override
  String get newPlaylist1 => 'Новий список відтворення';

  @override
  String get play => 'Відтворити';

  @override
  String get playStation => 'Увімкнути станцію';

  @override
  String get playNext => 'Відтворити далі';

  @override
  String get playlist => 'Список відтворення';

  @override
  String get playlistName => 'Назва списку відтворення';

  @override
  String get playlists1 => 'Списки відтворення';

  @override
  String get queue1 => 'Черга';

  @override
  String get recentlyPlayed => 'Нещодавно відтворене';

  @override
  String get removeFromQueue => 'Видалити з черги';

  @override
  String get retry => 'Спробувати ще раз';

  @override
  String get searchMusicArtistsAlbums =>
      'Пошук музики, виконавців, альбомів...';

  @override
  String get share => 'Поділитися';

  @override
  String featuringArtist(String artistName) {
    return 'ЗА УЧАСТЮ $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Поточна: $country';
  }

  @override
  String get queueTooltip => 'Черга';

  @override
  String get searchHint => 'Пошук музики, виконавців, альбомів...';

  @override
  String get language => 'Мова';

  @override
  String get systemDefault => 'Системна за замовчуванням';

  @override
  String get songsTab => 'Пісні';

  @override
  String get foldersTab => 'Папки';

  @override
  String get artistsTab => 'Виконавці';

  @override
  String get albumsTab => 'Альбоми';

  @override
  String get genresTab => 'Жанри';

  @override
  String get noLocalGenres => 'Жанрів не знайдено';

  @override
  String get playbackSpeed => 'Швидкість відтворення';

  @override
  String get addMusic => 'Додати музику';

  @override
  String get addFiles => 'Додати файли';

  @override
  String get addFolder => 'Додати папку';

  @override
  String get rescanLibrary => 'Повторно сканувати медіатеку';

  @override
  String get sortTitle => 'За назвою';

  @override
  String get sortArtist => 'За виконавцем';

  @override
  String get sortAlbum => 'За альбомом';

  @override
  String get sortDuration => 'За тривалістю';

  @override
  String get sortDateAdded => 'За датою додавання';

  @override
  String get sortBy => 'Сортувати за';

  @override
  String get trackInformation => 'Інформація про трек';

  @override
  String get removeFromLibrary => 'Видалити з медіатеки';

  @override
  String get showInFolder => 'Показати в папці';

  @override
  String get unknownArtist => 'Невідомий виконавець';

  @override
  String get unknownAlbum => 'Невідомий альбом';

  @override
  String get importedFiles => 'Імпортовані файли';

  @override
  String get playFolder => 'Відтворити папку';

  @override
  String get shuffleFolder => 'Відтворити папку випадково';

  @override
  String get playAll => 'Відтворити все';

  @override
  String get includeSubfolders => 'Включити вкладені папки';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count треку',
      many: '$count треків',
      few: '$count треки',
      two: '2 треки',
      one: '1 трек',
      zero: '0 треків',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Немає імпортованих локальних пісень';

  @override
  String get searchLocalMusic => 'Пошук локальної музики';

  @override
  String get viewAsList => 'Перегляд списком';

  @override
  String get viewAsGrid => 'Перегляд сіткою';

  @override
  String get trackInfoPath => 'Шлях';

  @override
  String get trackInfoFormat => 'Формат';

  @override
  String get trackInfoDuration => 'Тривалість';

  @override
  String get aboutDescription =>
      'Безкоштовний медіаплеєр з відкритим вихідним кодом.';

  @override
  String get aboutApp => 'Про PPPlayer';

  @override
  String get appTagline => 'Ваша музика. Ваш вибір.';

  @override
  String get exploreApp => 'Огляд PPPlayer';

  @override
  String get viewSource => 'Переглянути вихідний код';

  @override
  String get seeWhatsNew => 'Що нового';

  @override
  String get getHelp => 'Отримати допомогу';

  @override
  String versionInfo(Object version, Object build) {
    return 'Версія $version (Збірка $build)';
  }

  @override
  String get createdBy => 'Створено Lucas Coelho';

  @override
  String get website => 'Вебсайт';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Примітки до випуску';

  @override
  String get support => 'Підтримка';

  @override
  String get license => 'Ліцензія';

  @override
  String get acknowledgments => 'Подяки';

  @override
  String get close => 'Закрити';

  @override
  String copyright(Object year) {
    return '© $year Учасники PPPlayer';
  }

  @override
  String get goodMorning => 'Доброго ранку';

  @override
  String get goodAfternoon => 'Доброго дня';

  @override
  String get goodEvening => 'Доброго вечора';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Ваша музика чекає.';

  @override
  String dailyMix(Object number) {
    return 'Щоденний мікс $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'Ваше улюблене\nта нові відкриття';

  @override
  String get discoverWeekly => 'Відкриття тижня';

  @override
  String get releaseRadar => 'Радар новинок';

  @override
  String get newMusicJustForYou => 'Нова музика\nспеціально для вас';

  @override
  String get chillMix => 'Чіл мікс';

  @override
  String get relaxAndUnwind => 'Розслабтеся і відпочиньте';

  @override
  String get focusMix => 'Мікс для фокусування';

  @override
  String get deepFocusAndProductivity => 'Глибокий фокус\nта продуктивність';

  @override
  String artistRadio(Object artist) {
    return 'Радіо: $artist';
  }

  @override
  String genreRadio(Object genre) {
    return 'Радіо: $genre';
  }

  @override
  String get filterAll => 'Усі';

  @override
  String get filterPlaylists => 'Списки відтворення';

  @override
  String get filterArtists => 'Виконавці';

  @override
  String get filterAlbums => 'Альбоми';

  @override
  String get filterStations => 'Станції';

  @override
  String get filterStreams => 'Потоки';

  @override
  String get localMusicCard => 'Локальна музика';

  @override
  String get createPlaylistButton => 'Створити список відтворення';

  @override
  String get radioStations => 'Радіостанції';

  @override
  String get discoverMusic => 'Знайти музику';

  @override
  String get importLocalMusic => 'Імпортувати локальну музику';

  @override
  String get importAudioFiles => 'Імпортувати аудіофайли';

  @override
  String get importFolder => 'Імпортувати папку';

  @override
  String get importFolderSubtitle =>
      'Примітка: Аудіофайли приховані в засобі вибору папок. Це нормально.';

  @override
  String get importPlaylist => 'Імпортувати список відтворення';

  @override
  String get importPlaylistSubtitle => 'Імпортувати файли .m3u або .m3u8';

  @override
  String get exportPlaylist => 'Експортувати список відтворення';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Непідтримуваний формат або пошкоджений файл';

  @override
  String get playbackErrorFileInaccessible =>
      'Файл недоступний або не знайдений';

  @override
  String get localVideosCard => 'Локальні відео';

  @override
  String get noLocalVideos => 'Відео не знайдено';

  @override
  String get searchLocalVideos => 'Шукати локальні відео';

  @override
  String get addVideos => 'Додати відео';

  @override
  String get subtitles => 'Субтитри';

  @override
  String get audioTracks => 'Аудіодоріжки';

  @override
  String get loadSubtitleFile => 'Завантажити файл субтитрів...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Помилка завантаження субтитрів: $error';
  }

  @override
  String get off => 'Вимкнено';

  @override
  String get playOn => 'Відтворювати на';

  @override
  String get thisDevice => 'Цей пристрій';

  @override
  String get availableDevices => 'Доступні пристрої';

  @override
  String get searchingDevices => 'Пошук пристроїв…';

  @override
  String get refresh => 'Оновити';

  @override
  String get connecting => 'Підключення…';

  @override
  String connectingTo(String name) {
    return 'Підключення до $name…';
  }

  @override
  String get connected => 'Підключено';

  @override
  String get unsupportedOutput =>
      'Це джерело не можна відтворити на цьому виході.';

  @override
  String get airPlayAudioOutput => 'AirPlay та аудіовихід';

  @override
  String get returnForAirPlay =>
      'Відтворюйте на цьому пристрої, щоб використовувати AirPlay.';

  @override
  String get openSoundSettings =>
      'Відкрийте налаштування звуку, щоб вибрати вихід.';

  @override
  String get soundSettingsError => 'Не вдалося відкрити налаштування звуку.';

  @override
  String get systemOutput => 'Системний вихід';

  @override
  String playingOn(String name) {
    return 'Відтворення на $name';
  }

  @override
  String get chooseAirPlay =>
      'Натисніть кнопку AirPlay, щоб вибрати колонку або телевізор.';

  @override
  String get airPlayDevice => 'Пристрій AirPlay';

  @override
  String get playOnIphone => 'Відтворювати на цьому iPhone';

  @override
  String get chooseIphone =>
      'Виберіть цей iPhone за допомогою кнопки AirPlay нижче.';

  @override
  String get profile => 'Профіль';

  @override
  String get preferences => 'Налаштування';

  @override
  String get themeColor => 'Колір теми';

  @override
  String get yourMusic => 'Ваша музика';

  @override
  String get apiCredentials => 'Облікові дані API';

  @override
  String get dataStorage => 'Дані та сховище';

  @override
  String get editProfileHelp => 'Укажіть ім’я та аватар';

  @override
  String get customProvider => 'Власний постачальник';

  @override
  String get defaultProvider => 'Типовий PPPlayer';

  @override
  String get proExperience => 'Режим Pro активний';

  @override
  String get beta => 'Бета';

  @override
  String get loading => 'Завантаження…';

  @override
  String get unknown => 'Невідомо';

  @override
  String get pause => 'Пауза';

  @override
  String get repeat => 'Повтор';

  @override
  String get mute => 'Вимкнути звук';

  @override
  String get unmute => 'Увімкнути звук';

  @override
  String get fitVideo => 'Вписати';

  @override
  String get fillVideo => 'Заповнити';

  @override
  String get fullscreen => 'Повний екран';

  @override
  String get exitFullscreen => 'Вийти з повного екрана';

  @override
  String get volume => 'Гучність';

  @override
  String get save => 'Зберегти';

  @override
  String get delete => 'Видалити';

  @override
  String get clear => 'Очистити';

  @override
  String get follow => 'Стежити';

  @override
  String get unfollow => 'Припинити стежити';

  @override
  String get following => 'Стежите';

  @override
  String get showAll => 'Показати все';

  @override
  String get appearance => 'Вигляд';

  @override
  String get subtitleSize => 'Розмір';

  @override
  String get subtitleBackground => 'Тло';

  @override
  String get earlier => 'Раніше';

  @override
  String get later => 'Пізніше';

  @override
  String get reset => 'Скинути';

  @override
  String subtitleDelay(String seconds) {
    return 'Затримка: $seconds с';
  }

  @override
  String get morePlaybackControls => 'Інші елементи керування';

  @override
  String get hideVideo => 'Приховати відео';

  @override
  String get showVideo => 'Показати відео';

  @override
  String get closeQueue => 'Закрити чергу';

  @override
  String get enabled => 'Увімк.';

  @override
  String get openFile => 'Відкрити файл…';

  @override
  String get openFolder => 'Відкрити папку…';

  @override
  String get openUrl => 'Відкрити URL…';

  @override
  String get fileMenu => 'Файл';

  @override
  String get viewMenu => 'Вигляд';

  @override
  String get windowMenu => 'Вікно';

  @override
  String get saveChanges => 'Зберегти зміни';

  @override
  String get themeAvatarColor => 'Колір теми й аватара';

  @override
  String get networkStreams => 'Мережеві потоки';

  @override
  String get networkStream => 'Мережевий потік';

  @override
  String get openNetworkStream => 'Відкрити мережевий потік';

  @override
  String get editPlaylist => 'Редагувати список відтворення';

  @override
  String get editStreamItem => 'Редагувати елемент потоку';

  @override
  String get streamUrl => 'URL потоку';

  @override
  String get platformType => 'Платформа / тип';

  @override
  String get optionalTitle => 'Назва (необов’язково)';

  @override
  String get optionalImageUrl => 'URL зображення (необов’язково)';

  @override
  String get myStream => 'Мій потік';

  @override
  String get saveToLibrary => 'Зберегти в бібліотеку';

  @override
  String get justPlay => 'Лише відтворити';

  @override
  String get autoDetect => 'Визначати автоматично';

  @override
  String get apiKeyRequired => 'Потрібен ключ API';

  @override
  String get customApiKey => 'Використовувати власний ключ API';

  @override
  String get clientId => 'Ідентифікатор клієнта';

  @override
  String get clientSecret => 'Секрет клієнта';

  @override
  String get saveCredentials => 'Зберегти облікові дані';

  @override
  String get searchStrategy => 'Спосіб пошуку';

  @override
  String get credentialsLocalOnly =>
      'Безпечно зберігаються на цьому пристрої. Ніколи не надсилаються до PPPlayer.';

  @override
  String get scrapingHelp =>
      'Ключ API та квота не потрібні. Може працювати повільніше або менш надійно.';

  @override
  String get streamHelp => 'Введіть URL HTTP(S) або посилання на список M3U.';

  @override
  String get deletePlaylistConfirm =>
      'Видалити цей список відтворення назавжди?';

  @override
  String get clearCacheConfirm =>
      'Видалити кеш? Бібліотека та улюблене залишаться без змін.';

  @override
  String get clearHistoryConfirm =>
      'Видалити історію прослуховування назавжди?';

  @override
  String get addedToQueue => 'Додано до черги';

  @override
  String get addedVideo => 'Відео додано';

  @override
  String addedChannels(String count) {
    return 'Додані канали: $count';
  }

  @override
  String get removedFromPlaylist => 'Видалено зі списку';

  @override
  String get exportCancelled => 'Експорт скасовано';

  @override
  String exportComplete(String count) {
    return 'Список експортовано. Пропущені елементи: $count';
  }

  @override
  String get playlistExported => 'Список експортовано';

  @override
  String get live => 'Наживо';

  @override
  String get sponsored => 'Реклама';

  @override
  String get removeFromPlaylist => 'Вилучити зі списку';

  @override
  String get likedSongsHelp => 'Збережіть пісні, щоб побачити їх тут';

  @override
  String get apiSingleVideoHint =>
      'Можна додати це відео без імпорту списку відтворення.';

  @override
  String get linkCopied => 'Посилання скопійовано';

  @override
  String get willPlayNext => 'Буде відтворено наступним';

  @override
  String get checkItOut => 'Переглянути';

  @override
  String get loadFailed => 'Не вдалося завантажити вміст. Спробуйте ще раз.';
}
