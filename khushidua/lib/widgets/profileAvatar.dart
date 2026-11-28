import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/colors.dart';
import 'package:khushidua/constants/theme.dart';
import 'package:khushidua/controllers/themeController.dart';
import 'package:khushidua/controllers/userController.dart';

/// Whether an avatar asset is the girl's.
///
/// Matched on the file name: "female.png" contains "male", so the substring
/// check this replaces labelled both avatars "Boy".
bool isGirlAvatar(String path) => path.split('/').last.startsWith('female');

/// The reader's avatar, following their profile and age group.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final bool showBorder;

  const ProfileAvatar({super.key, this.size = 90, this.showBorder = true});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserController>(
      builder: (user) => AvatarImage(
        path: user.avatar,
        name: user.userName,
        size: size,
        showBorder: showBorder,
      ),
    );
  }
}

/// A round avatar: the chosen picture, else the name's initials, else a
/// person icon for a reader who has not given a name.
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.path,
    required this.name,
    this.size = 90,
    this.showBorder = false,
  });

  final String path;
  final String name;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final Color fill = switch (themeController.selectedAgeGroup) {
          0 => rpink,
          1 => rblue,
          _ => rgreen,
        };
        final initials = _initials(name);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showBorder ? Border.all(color: fill, width: 3) : null,
            boxShadow: AppElevation.card,
            // A plain fill: the avatar art is transparent, so this is the
            // colour that shows around the character.
            color: fill,
          ),
          child: path.isNotEmpty
              ? ClipOval(child: Image.asset(path, fit: BoxFit.cover))
              : Center(
                  child: initials.isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: size * 0.55,
                        )
                      : Text(
                          initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    final letters = parts.take(2).map((p) => p.characters.first);
    return letters.join().toUpperCase();
  }
}
