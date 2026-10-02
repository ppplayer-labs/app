import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_localizations.dart';

/// Flutter supplies no framework catalogs for Guarani or Nigerian Pidgin.
/// These delegates translate the navigation, menus and text editing controls
/// used by PPPlayer. Calendar/time-picker strings are inherited; PPPlayer does
/// not expose those widgets.
final appLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  const _MaterialDelegate(),
  const _CupertinoDelegate(),
  ...AppLocalizations.localizationsDelegates,
];

bool _needsFrameworkCatalog(Locale locale) =>
    locale.languageCode == 'gn' || locale.languageCode == 'pcm';

class _MaterialDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialDelegate();
  @override
  bool isSupported(Locale locale) => _needsFrameworkCatalog(locale);
  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      _MaterialCatalog(await AppLocalizations.delegate.load(locale));
  @override
  bool shouldReload(_MaterialDelegate old) => false;
}

class _CupertinoDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoDelegate();
  @override
  bool isSupported(Locale locale) => _needsFrameworkCatalog(locale);
  @override
  Future<CupertinoLocalizations> load(Locale locale) async =>
      _CupertinoCatalog(await AppLocalizations.delegate.load(locale));
  @override
  bool shouldReload(_CupertinoDelegate old) => false;
}

class _EditingCatalog {
  const _EditingCatalog(this.strings);
  final AppLocalizations strings;
  bool get guarani => strings.localeName == 'gn';
  String get copy => guarani ? 'Embohasa' : 'Copy am';
  String get cut => guarani ? 'Eikytĩ' : 'Cut am';
  String get paste => guarani ? 'Emboja' : 'Paste am';
  String get selectAll => guarani ? 'Eiporavo opaite' : 'Choose all';
  String get lookUp => guarani ? 'Eheka heʼiséva' : 'Check meaning';
  String get searchWeb => guarani ? 'Eheka ñandutípe' : 'Search for web';
  String get alert => guarani ? 'Ñemomarandu' : 'Notice';
  String get dialog => guarani ? 'Ñomongeta' : 'Message box';
  String get menu => guarani ? 'Poravorã' : 'Menu';
}

class _MaterialCatalog extends DefaultMaterialLocalizations {
  _MaterialCatalog(this.strings) : editing = _EditingCatalog(strings);
  final AppLocalizations strings;
  final _EditingCatalog editing;
  @override
  String get backButtonTooltip => strings.goBack;
  @override
  String get closeButtonTooltip => strings.close;
  @override
  String get deleteButtonTooltip => strings.delete;
  @override
  String get clearButtonTooltip => strings.clear;
  @override
  String get moreButtonTooltip => strings.moreOptions;
  @override
  String get showMenuTooltip => editing.menu;
  @override
  String get drawerLabel => editing.menu;
  @override
  String get menuBarMenuLabel => editing.menu;
  @override
  String get popupMenuLabel => editing.menu;
  @override
  String get dialogLabel => editing.dialog;
  @override
  String get alertDialogLabel => editing.alert;
  @override
  String get bottomSheetLabel => editing.dialog;
  @override
  String get searchFieldLabel => strings.search;
  @override
  String get cancelButtonLabel => strings.cancel;
  @override
  String get closeButtonLabel => strings.close;
  @override
  String get continueButtonLabel =>
      editing.guarani ? 'Eho tenonde' : 'Continue dey go';
  @override
  String get okButtonLabel => editing.guarani ? 'Oĩ porã' : 'E good';
  @override
  String get copyButtonLabel => editing.copy;
  @override
  String get cutButtonLabel => editing.cut;
  @override
  String get pasteButtonLabel => editing.paste;
  @override
  String get selectAllButtonLabel => editing.selectAll;
  @override
  String get lookUpButtonLabel => editing.lookUp;
  @override
  String get searchWebButtonLabel => editing.searchWeb;
  @override
  String get scanTextButtonLabel =>
      editing.guarani ? 'Emoñeʼẽ jehaipyre' : 'Scan the text';
  @override
  String get shareButtonLabel => strings.share;
  @override
  String get licensesPageTitle => strings.license;
  @override
  String get viewLicensesButtonLabel => strings.license;
  @override
  String licensesPackageDetailText(int licenseCount) =>
      '${strings.license}: $licenseCount';
  @override
  String aboutListTileTitle(String applicationName) =>
      '${strings.aboutApp}: $applicationName';
  @override
  String get modalBarrierDismissLabel => strings.close;
  @override
  String get menuDismissLabel => strings.close;
  @override
  String get scrimLabel => editing.dialog;
  @override
  String scrimOnTapHint(String modalRouteContentName) =>
      '${strings.close}: $modalRouteContentName';
  @override
  String get refreshIndicatorSemanticLabel => strings.refresh;
}

class _CupertinoCatalog extends DefaultCupertinoLocalizations {
  _CupertinoCatalog(this.strings) : editing = _EditingCatalog(strings);
  final AppLocalizations strings;
  final _EditingCatalog editing;
  @override
  String get alertDialogLabel => editing.alert;
  @override
  String get cutButtonLabel => editing.cut;
  @override
  String get copyButtonLabel => editing.copy;
  @override
  String get pasteButtonLabel => editing.paste;
  @override
  String get selectAllButtonLabel => editing.selectAll;
  @override
  String get clearButtonLabel => strings.clear;
  @override
  String get lookUpButtonLabel => editing.lookUp;
  @override
  String get searchWebButtonLabel => editing.searchWeb;
  @override
  String get shareButtonLabel => strings.share;
  @override
  String get searchTextFieldPlaceholderLabel => strings.search;
  @override
  String get modalBarrierDismissLabel => strings.close;
  @override
  String get menuDismissLabel => strings.close;
  @override
  String get cancelButtonLabel => strings.cancel;
  @override
  String get backButtonLabel => strings.goBack;
  @override
  String get noSpellCheckReplacementsLabel => strings.noResultsFound;
}
