/// Central brand and storage names used throughout the application.
///
/// Keep user-facing text separate from technical names so the visible brand
/// can include a space without producing awkward file or directory names.
abstract final class AppBrand {
  static const String name = 'GPS Mark';
  static const String technicalName = 'GPSMark';
  static const String galleryAlbum = name;
  static const String galleryPath = 'Pictures/$galleryAlbum';
  static const String galleryDisplayPath = 'Pictures / $galleryAlbum';
  static const String internalPhotoDirectory = technicalName;
  static const String photoFilePrefix = technicalName;
}
