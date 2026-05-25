/// All UI strings used in the app — centralized in one place for easy editing.
class AppStrings {
  AppStrings._();

  // ─── App ───────────────────────────────────────────────
  static const String appTitle = 'YouTube';
  static const String userAvatarLetter = 'U';

  // ─── Home / Feed ───────────────────────────────────────
  static const String categoryAll = 'Barcha';
  static const String categoryMusic = 'Musiqa';
  static const String categoryGames = "O'yinlar";
  static const String categoryNews = 'Yangiliklar';
  static const String categorySports = 'Sport';
  static const String categoryEducation = "Ta'lim";
  static const String categoryTech = 'Texnologiya';

  static const String searchHint = "Videolarni qidirish...";
  static const String endOfList = 'Oxiri';
  static const String errorTitle = 'Xatolik yuz berdi';
  static const String errorNetworkMessage =
      "Internet ulanishi tiklanganda ma'lumotlar avtomatik yangilanadi";
  static const String retryButton = 'Qayta urinish';
  static const String emptySearch = 'Videolar topilmadi';
  static const String emptyVideos = "Hozircha videolar yo'q";
  static const String loading = 'Yuklanmoqda...';

  // ─── Video meta ────────────────────────────────────────
  static const String views = "ko'rish";
  static const String subscriber = 'obunachi';

  // ─── Video player actions ──────────────────────────────
  static const String commentsTitle = 'Izohlar';
  static const String subscribeButton = 'Subscribe';
  static const String shareLabel = 'Share';
  static const String remixLabel = 'Remix';
  static const String downloadLabel = 'Download';
  static const String clipLabel = 'Clip';
  static const String dislikeLabel = 'Dislike';

  // ─── Comments ──────────────────────────────────────────
  static const String commentsDisabled = "Bu videoda izohlar o'chirilgan";
  static const String commentsEmpty = "Hozircha izohlar yo'q";
  static const String commentReply = 'javob';

  // ─── Native video player ───────────────────────────────
  // (uses AppStrings.retryButton for retry)

  // Shorts
  static const String shortsTitle = 'Shorts';
  static const String shortsNotFound = 'Shorts topilmadi';
  static const String shortsSubscribe = 'Subscribe';
  static const String shortsComment = 'Izoh';

  // ─── Subscriptions ─────────────────────────────────────
  static const String subscriptionsTitle = 'Obunalar';
  static const String subscriptionsSubtitle =
      "Tez orada — siz obuna bo'lgan kanallar shu yerda ko'rinadi";

  // ─── Library ───────────────────────────────────────────
  static const String libraryTitle = 'Kutubxona';
  static const String librarySubtitle =
      "Tez orada — tarix, keyinroq ko'rish, yoqtirilgan videolar";

  // ─── Bottom nav ────────────────────────────────────────
  static const String navHome = 'Asosiy';
  static const String navShorts = 'Shorts';
  static const String navSubscriptions = 'Obunalar';
  static const String navLibrary = 'Kutubxona';

  // ─── Channel ───────────────────────────────────────────
  static const String channelVideos = 'Videolar';
  static const String videoLabel = ' video';

  // ─── Avatar ────────────────────────────────────────────
  static const String fallbackAvatarChar = '?';

  // ─── Time ago (formatter) ──────────────────────────────
  static const String timeAgoYears = ' yil oldin';
  static const String timeAgoMonths = ' oy oldin';
  static const String timeAgoWeeks = ' hafta oldin';
  static const String timeAgoDays = ' kun oldin';
  static const String timeAgoHours = ' soat oldin';
  static const String timeAgoMinutes = ' daqiqa oldin';
  static const String timeAgoJustNow = 'Hozirgina';

  // ─── Compact count ─────────────────────────────────────
  static const String compactB = 'B';
  static const String compactM = 'M';
  static const String compactK = 'K';

  // ─── Video player ──────────────────────────────────────
  static const String videoStreamNotFound = 'Video stream topilmadi';
  static const String videoLoadErrorPrefix = 'Video yuklanmadi';

  // ─── UI separators ─────────────────────────────────────
  static const String separatorDash = ' - ';
  static const String separatorBullet = ' \u2022 ';
  static const String separatorTime = ' / ';
  static const String channelHandlePrefix = '@';
}
