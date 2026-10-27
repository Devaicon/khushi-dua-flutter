/// Which duas a reader sees.
///
/// Kept free of Flutter and GetX so it can be unit tested. Sections used to
/// unlock as duas were listened to; every section is now open to everyone,
/// and listening (see `AudioController`) only tracks progress.
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
