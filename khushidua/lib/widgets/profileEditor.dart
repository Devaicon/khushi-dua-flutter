import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/colors.dart';
import '../constants/theme.dart';
import '../controllers/userController.dart';
import 'profileAvatar.dart';

/// The avatars a reader can pick, by asset path. Empty means initials.
const List<String> kAvatarChoices = [
  'assets/images/male.png',
  'assets/images/female.png',
];

/// A bottom sheet for the optional name and avatar. Nothing in the app needs
/// either; they only personalise the greeting, and stay on this phone.
Future<void> showProfileEditor() {
  return Get.bottomSheet(
    const _ProfileEditorSheet(),
    isScrollControlled: true,
  );
}

class _ProfileEditorSheet extends StatefulWidget {
  const _ProfileEditorSheet();

  @override
  State<_ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<_ProfileEditorSheet> {
  final UserController _user = Get.find<UserController>();
  late final TextEditingController _name = TextEditingController(
    text: _user.userName,
  );
  late String _avatar = _user.avatar;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _user.setUserName(_name.text);
    if (_avatar != _user.avatar) await _user.setAvatar(_avatar);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppSurface.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.xl,
              AppSpace.xl,
              AppSpace.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Your profile".tr,
                  style: TextStyle(
                    color: rbluedark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  "Optional. Saved only on this phone.".tr,
                  style: TextStyle(color: AppText.onPageMuted, fontSize: 13),
                ),
                const SizedBox(height: AppSpace.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final path in ['', ...kAvatarChoices])
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.sm,
                        ),
                        child: _AvatarChoice(
                          path: path,
                          name: _name.text,
                          selected: _avatar == path,
                          onTap: () => setState(() => _avatar = path),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: "Your name".tr,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text("Cancel".tr),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: brandFill,
                      ),
                      child: Text("Save".tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.path,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String path;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: path.isEmpty
          ? "No picture".tr
          : isGirlAvatar(path)
          ? "Girl".tr
          : "Boy".tr,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? brandFill : Colors.transparent,
              width: 3,
            ),
          ),
          child: AvatarImage(path: path, name: name, size: 64),
        ),
      ),
    );
  }
}
