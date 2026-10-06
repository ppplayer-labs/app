// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'PPPlayer';

  @override
  String titleSubtitle(Object title, Object subtitle) {
    return '$title, $subtitle';
  }

  @override
  String get albums => 'ÁLBUNS';

  @override
  String get api => 'API';

  @override
  String get artists => 'ARTISTAS';

  @override
  String get artwork => 'CAPA';

  @override
  String get appVersion => 'Versão do aplicativo';

  @override
  String get artist => 'Artista';

  @override
  String get artistsYouFollow => 'Artistas que você segue';

  @override
  String get autoplay => 'Reprodução automática';

  @override
  String get becauseYouListenedTo => 'Porque você ouviu';

  @override
  String get browseAll => 'Navegar por tudo';

  @override
  String get cancel => 'Cancelar';

  @override
  String get clearAppCache => 'Limpar cache do aplicativo?';

  @override
  String get clearCache => 'Limpar Cache';

  @override
  String get clearHistory => 'Limpar histórico?';

  @override
  String get clearRecentlyPlayed => 'Limpar reproduzidos recentemente';

  @override
  String get contentMarket => 'Mercado de Conteúdo';

  @override
  String get continueListening => 'Continuar ouvindo';

  @override
  String get continueVideoPlaybackInASmallWindow =>
      'Continuar reprodução de vídeo em janela pequena';

  @override
  String get create => 'Criar';

  @override
  String get createAPlaylistToGetStarted => 'Crie uma playlist para começar';

  @override
  String currentSelectedcountry(Object country) {
    return 'Atual: $country';
  }

  @override
  String get deletePlaylist => 'Excluir Playlist';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String errorLoadingMarkets(Object err) {
    return 'Erro ao carregar mercados: $err';
  }

  @override
  String error(Object error) {
    return 'Erro: $error';
  }

  @override
  String explore(Object genre) {
    return 'Explorar $genre';
  }

  @override
  String get fansAlsoLike => 'OS FÃS TAMBÉM GOSTAM';

  @override
  String featuringTouppercase(Object artist) {
    return 'COM $artist';
  }

  @override
  String get featuredPlaylists => 'Playlists em destaque';

  @override
  String get followArtistsToSeeThemHere => 'Siga artistas para vê-los aqui';

  @override
  String get followStationsToSeeThemHere => 'Siga estações para vê-las aqui';

  @override
  String get forceAudioonlyStreamsToSaveData =>
      'Forçar streams apenas de áudio para economizar dados';

  @override
  String get freesUpSpaceAndForcesFreshDataOnNextLoad =>
      'Libera espaço e força dados novos no próximo carregamento';

  @override
  String get fromYourFavorites => 'Dos seus favoritos';

  @override
  String get goBack => 'Voltar';

  @override
  String inspiredByName(Object name) {
    return 'Inspirado em $name';
  }

  @override
  String get keepPlayingSimilarTracksWhenQueueEnds =>
      'Continuar tocando faixas similares quando a fila acabar';

  @override
  String get library => 'Biblioteca';

  @override
  String get likeAlbumsToSeeThemHere => 'Curta álbuns para vê-los aqui';

  @override
  String get likedSongs => 'Músicas Curtidas';

  @override
  String get lowDataMode => 'Modo de Economia de Dados';

  @override
  String get madeForYou => 'Feito para você';

  @override
  String moreLikeName(Object name) {
    return 'Mais como $name';
  }

  @override
  String get moreOptions => 'Mais opções';

  @override
  String get nameYourMasterpiece => 'Dê um nome à sua obra-prima...';

  @override
  String get newPlaylist => 'Nova Playlist';

  @override
  String get newReleases => 'Novos Lançamentos';

  @override
  String get next => 'Próximo';

  @override
  String get noAlbumsFound => 'Nenhum álbum encontrado';

  @override
  String get noArtistsFollowed => 'Nenhum artista seguido';

  @override
  String get noArtistsFound => 'Nenhum artista encontrado';

  @override
  String get noLikedAlbums => 'Nenhum álbum curtido';

  @override
  String get noPlaylistsFound => 'Nenhuma playlist encontrada';

  @override
  String get noPlaylistsYet => 'Nenhuma playlist ainda';

  @override
  String get noResultsFound => 'Nenhum resultado encontrado';

  @override
  String get noStationsFollowed => 'Nenhuma estação seguida';

  @override
  String get noTrackPlaying => 'Nenhuma faixa tocando';

  @override
  String get noTracksFound => 'Nenhuma faixa encontrada';

  @override
  String get playlists => 'LISTAS DE REPRODUÇÃO';

  @override
  String get popular => 'POPULAR';

  @override
  String get permanentlyRemoveListeningHistory =>
      'Remover histórico de escuta permanentemente';

  @override
  String get pictureinpicturePip => 'Imagem na imagem (PiP)';

  @override
  String get popularAlbums => 'Álbuns populares';

  @override
  String get popularArtists => 'Artistas populares';

  @override
  String get popularGenres => 'Gêneros populares';

  @override
  String get popularSongs => 'Músicas populares';

  @override
  String get popularTracks => 'Faixas populares';

  @override
  String get popularHitsRightNow => 'Sucessos populares agora';

  @override
  String get previous => 'Anterior';

  @override
  String get queue => 'FILA';

  @override
  String get recentSearches => 'Buscas recentes';

  @override
  String get recommendedForYou => 'Recomendado para você';

  @override
  String get scraping => 'Obtendo dados';

  @override
  String get search => 'Buscar';

  @override
  String get searchInAlbum => 'Buscar no álbum...';

  @override
  String get searchInLibrary => 'Buscar na biblioteca...';

  @override
  String get searchInPlaylist => 'Buscar na playlist';

  @override
  String get searchLikedSongs => 'Buscar nas músicas curtidas...';

  @override
  String get searchPopularSongs => 'Buscar músicas populares...';

  @override
  String get selectMarket => 'Selecionar mercado';

  @override
  String get settings => 'Configurações';

  @override
  String get showVideoPlayer => 'Mostrar player de vídeo';

  @override
  String get shuffle => 'Ordem Aleatória';

  @override
  String get spotifyCredentials => 'Credenciais do Spotify';

  @override
  String get suggestedStations => 'Estações Sugeridas';

  @override
  String get tracks => 'FAIXAS';

  @override
  String get trending => 'Em Alta';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get tryADifferentSearchTerm => 'Tente um termo de busca diferente';

  @override
  String get useYoutubePlayerWhenAvailable =>
      'Usar player do YouTube quando disponível';

  @override
  String get video => 'VÍDEO';

  @override
  String get whatDoYouWantToListenTo => 'O que você quer ouvir?';

  @override
  String get youtubeCredentials => 'Credenciais do YouTube';

  @override
  String get yourLibrary => 'Sua Biblioteca';

  @override
  String get playerscreenviewswitch => 'alternar_visualizacao_tela_jogador';

  @override
  String get addToPlaylist => 'Adicionar à playlist';

  @override
  String get addToQueue => 'Adicionar à fila';

  @override
  String get copyId => 'Copiar ID';

  @override
  String get copyLink => 'Copiar link';

  @override
  String get discover => 'Descobrir';

  @override
  String get enterYourName => 'Digite seu nome';

  @override
  String get favorites => 'Favoritos';

  @override
  String get goToAlbum => 'Ir para o álbum';

  @override
  String get goToArtist => 'Ir para o artista';

  @override
  String get goToArtistRadio => 'Ir para a rádio do artista';

  @override
  String get goToPlaylist => 'Ir para a playlist';

  @override
  String get goToSongRadio => 'Ir para a rádio da música';

  @override
  String get home => 'Início';

  @override
  String get myAwesomePlaylist => 'Minha Playlist Incrível';

  @override
  String get myPlaylist => 'Minha Playlist';

  @override
  String get newPlaylist1 => 'Nova playlist';

  @override
  String get play => 'Tocar';

  @override
  String get playStation => 'Tocar estação';

  @override
  String get playNext => 'Tocar a seguir';

  @override
  String get playlist => 'Playlist';

  @override
  String get playlistName => 'Nome da playlist';

  @override
  String get playlists1 => 'Listas de Reprodução';

  @override
  String get queue1 => 'Fila';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueUpNext => 'Up next';

  @override
  String get recentlyPlayed => 'Tocadas Recentemente';

  @override
  String get removeFromQueue => 'Remover da fila';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get searchMusicArtistsAlbums => 'Buscar músicas, artistas, álbuns...';

  @override
  String get share => 'Compartilhar';

  @override
  String featuringArtist(String artistName) {
    return 'COM $artistName';
  }

  @override
  String currentCountry(String country) {
    return 'Atual: $country';
  }

  @override
  String get queueTooltip => 'Fila';

  @override
  String get searchHint => 'Buscar música, artistas, álbuns...';

  @override
  String get language => 'Idioma';

  @override
  String get systemDefault => 'Padrão do sistema';

  @override
  String get songsTab => 'Músicas';

  @override
  String get foldersTab => 'Pastas';

  @override
  String get artistsTab => 'Artistas';

  @override
  String get albumsTab => 'Álbuns';

  @override
  String get genresTab => 'Gêneros';

  @override
  String get noLocalGenres => 'No local genres found';

  @override
  String get playbackSpeed => 'Velocidade de reprodução';

  @override
  String get addMusic => 'Adicionar música';

  @override
  String get addFiles => 'Adicionar arquivos';

  @override
  String get addFolder => 'Adicionar pasta';

  @override
  String get rescanLibrary => 'Reescanear biblioteca';

  @override
  String get sortTitle => 'Ordenar por título';

  @override
  String get sortArtist => 'Ordenar por artista';

  @override
  String get sortAlbum => 'Ordenar por álbum';

  @override
  String get sortDuration => 'Ordenar por duração';

  @override
  String get sortDateAdded => 'Ordenar por data de adição';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get trackInformation => 'Informações da faixa';

  @override
  String get removeFromLibrary => 'Remover da biblioteca';

  @override
  String get showInFolder => 'Mostrar na pasta';

  @override
  String get unknownArtist => 'Artista desconhecido';

  @override
  String get unknownAlbum => 'Álbum desconhecido';

  @override
  String get importedFiles => 'Arquivos importados';

  @override
  String get playFolder => 'Reproduzir pasta';

  @override
  String get shuffleFolder => 'Misturar pasta';

  @override
  String get playAll => 'Reproduzir tudo';

  @override
  String get includeSubfolders => 'Incluir subpastas';

  @override
  String trackCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas',
      one: '1 faixa',
      zero: '0 faixas',
    );
    return '$_temp0';
  }

  @override
  String get noLocalSongs => 'Nenhuma música local encontrada';

  @override
  String get searchLocalMusic => 'Procurar música local...';

  @override
  String get viewAsList => 'Ver como lista';

  @override
  String get viewAsGrid => 'Ver como grade';

  @override
  String get trackInfoPath => 'Caminho';

  @override
  String get trackInfoFormat => 'Formato';

  @override
  String get trackInfoDuration => 'Duração';

  @override
  String get aboutDescription =>
      'Um reprodutor de mídia gratuito e de código aberto.';

  @override
  String get aboutApp => 'Sobre o PPPlayer';

  @override
  String get appTagline => 'Sua música. Do seu jeito.';

  @override
  String get exploreApp => 'Explorar o PPPlayer';

  @override
  String get viewSource => 'Ver código fonte';

  @override
  String get seeWhatsNew => 'Novidades';

  @override
  String get getHelp => 'Obter ajuda';

  @override
  String versionInfo(Object version, Object build) {
    return 'Versão $version (Build $build)';
  }

  @override
  String get createdBy => 'Criado por Lucas Coelho';

  @override
  String get website => 'Site';

  @override
  String get github => 'GitHub';

  @override
  String get releaseNotes => 'Notas de lançamento';

  @override
  String get support => 'Suporte';

  @override
  String get license => 'Licença';

  @override
  String get acknowledgments => 'Agradecimentos';

  @override
  String get close => 'Fechar';

  @override
  String copyright(Object year) {
    return '© $year Contribuidores do PPPlayer';
  }

  @override
  String get goodMorning => 'Bom dia';

  @override
  String get goodAfternoon => 'Boa tarde';

  @override
  String get goodEvening => 'Boa noite';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get yourMusicIsWaiting => 'Sua música está esperando.';

  @override
  String dailyMix(Object number) {
    return 'Daily Mix $number';
  }

  @override
  String get yourFavoritesAndNewDiscoveries =>
      'Seus favoritos\ne novas descobertas';

  @override
  String get discoverWeekly => 'Descobertas da Semana';

  @override
  String get releaseRadar => 'Radar de Lançamentos';

  @override
  String get newMusicJustForYou => 'Música nova\nsó para você';

  @override
  String get chillMix => 'Chill Mix';

  @override
  String get relaxAndUnwind => 'Relaxe e descanse';

  @override
  String get focusMix => 'Focus Mix';

  @override
  String get deepFocusAndProductivity => 'Foco profundo\ne produtividade';

  @override
  String artistRadio(Object artist) {
    return 'Rádio de $artist';
  }

  @override
  String genreRadio(Object genre) {
    return 'Rádio de $genre';
  }

  @override
  String get filterAll => 'Tudo';

  @override
  String get filterPlaylists => 'Playlists';

  @override
  String get filterArtists => 'Artistas';

  @override
  String get filterAlbums => 'Álbuns';

  @override
  String get filterStations => 'Estações';

  @override
  String get filterStreams => 'Streams';

  @override
  String get localMusicCard => 'Música Local';

  @override
  String get createPlaylistButton => 'Criar Playlist';

  @override
  String get radioStations => 'Estações de Rádio';

  @override
  String get discoverMusic => 'Descobrir Música';

  @override
  String get importLocalMusic => 'Importar Música Local';

  @override
  String get importAudioFiles => 'Importar Arquivos de Áudio';

  @override
  String get importFolder => 'Importar Pasta';

  @override
  String get importFolderSubtitle =>
      'Escolha uma pasta que contenha arquivos de áudio';

  @override
  String get importPlaylist => 'Importar Playlist';

  @override
  String get importPlaylistSubtitle => 'Importar arquivos .m3u ou .m3u8';

  @override
  String get exportPlaylist => 'Exportar Playlist';

  @override
  String get playbackErrorUnsupportedFormat =>
      'Formato não suportado ou arquivo corrompido';

  @override
  String get playbackErrorFileInaccessible =>
      'Arquivo inacessível ou não encontrado';

  @override
  String get localVideosCard => 'Vídeos Locais';

  @override
  String get noLocalVideos => 'Nenhum vídeo encontrado';

  @override
  String get searchLocalVideos => 'Pesquisar vídeos locais';

  @override
  String get addVideos => 'Adicionar Vídeos';

  @override
  String get subtitles => 'Legendas';

  @override
  String get audioTracks => 'Faixas de Áudio';

  @override
  String get loadSubtitleFile => 'Carregar arquivo de legenda...';

  @override
  String errorLoadingSubtitle(String error) {
    return 'Erro ao carregar legenda: $error';
  }

  @override
  String get off => 'Desativado';

  @override
  String get playOn => 'Reproduzir em';

  @override
  String get thisDevice => 'Este dispositivo';

  @override
  String get availableDevices => 'Dispositivos disponíveis';

  @override
  String get searchingDevices => 'Buscando dispositivos…';

  @override
  String get refresh => 'Atualizar';

  @override
  String get connecting => 'Conectando…';

  @override
  String connectingTo(String name) {
    return 'Conectando a $name…';
  }

  @override
  String get connected => 'Conectado';

  @override
  String get unsupportedOutput =>
      'Esta fonte não pode ser reproduzida nesta saída.';

  @override
  String get airPlayAudioOutput => 'AirPlay e saída de áudio';

  @override
  String get returnForAirPlay =>
      'Reproduza neste dispositivo para usar o AirPlay.';

  @override
  String get openSoundSettings =>
      'Abra os ajustes de som para escolher uma saída.';

  @override
  String get soundSettingsError => 'Não foi possível abrir os ajustes de som.';

  @override
  String get systemOutput => 'Saída do sistema';

  @override
  String playingOn(String name) {
    return 'Reproduzindo em $name';
  }

  @override
  String get chooseAirPlay =>
      'Toque no botão do AirPlay para escolher uma caixa de som ou TV.';

  @override
  String get airPlayDevice => 'Dispositivo AirPlay';

  @override
  String get playOnIphone => 'Reproduzir neste iPhone';

  @override
  String get chooseIphone =>
      'Escolha este iPhone usando o botão do AirPlay abaixo.';

  @override
  String get profile => 'Perfil';

  @override
  String get preferences => 'Preferências';

  @override
  String get themeColor => 'Cor do tema';

  @override
  String get yourMusic => 'Sua música';

  @override
  String get apiCredentials => 'Credenciais de API';

  @override
  String get dataStorage => 'Dados e armazenamento';

  @override
  String get editProfileHelp => 'Defina seu nome e avatar';

  @override
  String get customProvider => 'Provedor personalizado';

  @override
  String get defaultProvider => 'Padrão do PPPlayer';

  @override
  String get proExperience => 'Experiência Pro ativa';

  @override
  String get beta => 'Beta';

  @override
  String get loading => 'Carregando…';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get pause => 'Pausar';

  @override
  String get repeat => 'Repetir';

  @override
  String get mute => 'Silenciar';

  @override
  String get unmute => 'Ativar som';

  @override
  String get fitVideo => 'Ajustar';

  @override
  String get fillVideo => 'Preencher';

  @override
  String get fullscreen => 'Tela cheia';

  @override
  String get exitFullscreen => 'Sair da tela cheia';

  @override
  String get volume => 'Volume';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Excluir';

  @override
  String get clear => 'Limpar';

  @override
  String get follow => 'Seguir';

  @override
  String get unfollow => 'Deixar de seguir';

  @override
  String get following => 'Seguindo';

  @override
  String get showAll => 'Mostrar tudo';

  @override
  String get appearance => 'Aparência';

  @override
  String get subtitleSize => 'Tamanho';

  @override
  String get subtitleBackground => 'Fundo';

  @override
  String get earlier => 'Mais cedo';

  @override
  String get later => 'Mais tarde';

  @override
  String get reset => 'Redefinir';

  @override
  String subtitleDelay(String seconds) {
    return 'Atraso: $seconds s';
  }

  @override
  String get morePlaybackControls => 'Mais controles de reprodução';

  @override
  String get hideVideo => 'Ocultar vídeo';

  @override
  String get showVideo => 'Mostrar vídeo';

  @override
  String get closeQueue => 'Fechar fila';

  @override
  String get enabled => 'Ativado';

  @override
  String get openFile => 'Abrir arquivo…';

  @override
  String get openFolder => 'Abrir pasta…';

  @override
  String get openUrl => 'Abrir URL…';

  @override
  String get fileMenu => 'Arquivo';

  @override
  String get viewMenu => 'Visualizar';

  @override
  String get windowMenu => 'Janela';

  @override
  String get saveChanges => 'Salvar alterações';

  @override
  String get themeAvatarColor => 'Cor do tema e avatar';

  @override
  String get networkStreams => 'Transmissões de rede';

  @override
  String get networkStream => 'Transmissão de rede';

  @override
  String get openNetworkStream => 'Abrir transmissão de rede';

  @override
  String get editPlaylist => 'Editar playlist';

  @override
  String get editStreamItem => 'Editar item da transmissão';

  @override
  String get streamUrl => 'URL da transmissão';

  @override
  String get platformType => 'Plataforma / tipo';

  @override
  String get optionalTitle => 'Título (opcional)';

  @override
  String get optionalImageUrl => 'URL da imagem (opcional)';

  @override
  String get myStream => 'Minha transmissão';

  @override
  String get saveToLibrary => 'Salvar na biblioteca';

  @override
  String get justPlay => 'Apenas reproduzir';

  @override
  String get autoDetect => 'Detectar automaticamente';

  @override
  String get apiKeyRequired => 'Chave de API necessária';

  @override
  String get customApiKey => 'Usar chave de API personalizada';

  @override
  String get clientId => 'ID do cliente';

  @override
  String get clientSecret => 'Segredo do cliente';

  @override
  String get saveCredentials => 'Salvar credenciais';

  @override
  String get searchStrategy => 'Estratégia de busca';

  @override
  String get credentialsLocalOnly =>
      'Armazenadas com segurança neste dispositivo. Nunca enviadas ao PPPlayer.';

  @override
  String get scrapingHelp =>
      'Não requer chave de API nem cota. Pode ser mais lento ou menos confiável.';

  @override
  String get streamHelp => 'Insira uma URL HTTP(S) ou um link de playlist M3U.';

  @override
  String get deletePlaylistConfirm => 'Excluir esta playlist permanentemente?';

  @override
  String get clearCacheConfirm =>
      'Excluir dados em cache? Sua biblioteca e favoritos não serão alterados.';

  @override
  String get clearHistoryConfirm =>
      'Excluir seu histórico de reprodução permanentemente?';

  @override
  String get addedToQueue => 'Adicionado à fila';

  @override
  String get addedVideo => 'Vídeo adicionado';

  @override
  String addedChannels(String count) {
    return 'Canais adicionados: $count';
  }

  @override
  String get removedFromPlaylist => 'Removido da playlist';

  @override
  String get exportCancelled => 'Exportação cancelada';

  @override
  String exportComplete(String count) {
    return 'Playlist exportada. Itens ignorados: $count';
  }

  @override
  String get playlistExported => 'Playlist exportada';

  @override
  String get live => 'Ao vivo';

  @override
  String get sponsored => 'Patrocinado';

  @override
  String get removeFromPlaylist => 'Remover da playlist';

  @override
  String get likedSongsHelp => 'Salve músicas para vê-las aqui';

  @override
  String get apiSingleVideoHint =>
      'Você pode adicionar este vídeo sem importar a playlist.';

  @override
  String get linkCopied => 'Link copiado';

  @override
  String get willPlayNext => 'Será reproduzido a seguir';

  @override
  String get checkItOut => 'Confira';

  @override
  String get loadFailed =>
      'Não foi possível carregar o conteúdo. Tente novamente.';
}
