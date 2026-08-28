


/// Spacing, radius and sizing tokens for GeoStamp Camera, matched against
/// the mockup grid (card padding, button height, badge/pill radius, icon
/// sizes in the camera toolbar and bottom nav).
///
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Standard screen edge padding (used on every screen in the mockups).
  static const double screenPadding = 16;
}

abstract final class AppRadius {
  static const double sm = 8; // input fields, small chips
  static const double md = 12; // stamp overlay, list tiles, buttons
  static const double lg = 16; // cards (project card, photo card, ad card)
  static const double xl = 20; // large sheets / preview cards
  static const double pill = 999; // status badges, tab selector, GPS pill
}

abstract final class AppSizes {
  // ---- Controls ----
  static const double buttonHeight = 52;
  static const double inputHeight = 52;
  static const double switchScale = 0.9;

  // ---- Icons ----
  static const double iconXs = 14;
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;
  static const double iconXl = 36;

  // ---- Avatars / thumbnails ----
  static const double thumbnailSm = 48; // project card leading thumb
  static const double thumbnailMd = 72; // recent capture / gallery grid tile
  static const double mapPreviewSm = 44; // map pin thumbnail in GPS stamp
  static const double mapPreviewLg = 120; // Photo Details map preview

  // ---- Navigation ----
  static const double bottomNavHeight = 64;
  static const double cameraFabSize = 68;
  static const double topBarHeight = 56;

  // ---- Camera toolbar ----
  static const double cameraToolbarIcon = 40; // flash/timer/grid/ratio circles
  static const double shutterButtonSize = 72;
}