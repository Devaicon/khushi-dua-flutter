/// Which duas a reader sees, and which sections of a category they have
/// unlocked.
///
/// Kept free of Flutter and GetX so it can be unit tested. A dua counts as
/// listened once its audio plays to the end while the reader is logged in
/// (see `AudioController`), which adds its id to the user's `readDuas`.
library;

import '../models/duaModel.dart';

/// Whether [dua] appears in the dua list for [ageGroup]
/// (0 little kids, 1 older kids, 2 grown-ups).
bool isDuaShownFor(DuaModel dua, int ageGroup) {
  if (!dua.isEnabled) return false;
  if (ageGroup == 0) return dua.littleKids;
  if (ageGroup == 1) return dua.olderKids;
  return dua.grownUps;
}

/// Whether every dua the reader can see in [sectionId] has been listened to.
///
/// Only visible duas count: a disabled dua, or one meant for another age
/// group, can never be opened, so requiring it would lock the next sections
/// forever. A section with nothing visible is not complete.
bool isSectionComplete(
  String sectionId,
  Iterable<DuaModel> allDuas,
  Set<String> listenedDuaIds,
  int ageGroup,
) {
  var hasVisible = false;
  for (final dua in allDuas) {
    if (!dua.subCategoryIds.contains(sectionId)) continue;
    if (!isDuaShownFor(dua, ageGroup)) continue;
    hasVisible = true;
    if (!listenedDuaIds.contains(dua.id)) return false;
  }
  return hasVisible;
}

/// The unlock state of one category's sections, in display order.
///
/// The first half (rounded up) is always open. The rest open once every
/// section in the first half is complete.
class SectionProgress {
  const SectionProgress._({
    required this.restricted,
    required this.freeSectionCount,
    required this.completedFreeSections,
  });

  factory SectionProgress.compute({
    required List<String> sectionIds,
    required Iterable<DuaModel> allDuas,
    required Set<String> listenedDuaIds,
    required int ageGroup,
    required bool restricted,
  }) {
    final free = (sectionIds.length / 2).ceil();
    var completed = 0;
    if (restricted) {
      for (final id in sectionIds.take(free)) {
        if (isSectionComplete(id, allDuas, listenedDuaIds, ageGroup)) {
          completed++;
        }
      }
    }
    return SectionProgress._(
      restricted: restricted,
      freeSectionCount: free,
      completedFreeSections: completed,
    );
  }

  /// False for members and guests, who see every section.
  final bool restricted;

  /// Sections that are open without listening to anything.
  final int freeSectionCount;

  /// How many of the free sections are complete.
  final int completedFreeSections;

  bool get allUnlocked =>
      !restricted || completedFreeSections >= freeSectionCount;

  bool isUnlocked(int index) => index < freeSectionCount || allUnlocked;
}
