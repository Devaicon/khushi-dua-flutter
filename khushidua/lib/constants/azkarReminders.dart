/// Firestore category ids the Azkar reminders deep-link into.
///
/// TODO(client): fill these in once the client nominates the morning and
/// evening Azkar categories. While they are empty the notification still
/// fires and simply opens the app home instead of a category.
const String kMorningAzkarCategoryId = '';
const String kEveningAzkarCategoryId = '';

/// Defaults for a freshly enabled Azkar reminder.
const int kDefaultMorningHour = 6;
const int kDefaultMorningMinute = 30;
const int kDefaultEveningHour = 18;
const int kDefaultEveningMinute = 30;
