import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/authController.dart';
import '../../widgets/adminAccessCard.dart';
import '../../widgets/ui.dart';

/// Who is signed in, and who else can use the panel.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<AuthController>(
        builder: (auth) {
          final me = auth.adminModel;
          final name = '${me.firstName} ${me.lastName}'.trim();
          return AdminPage(
            title: 'Profile & admins',
            subtitle: 'Your account, and the people who can use this panel.',
            child: LayoutBuilder(
              builder: (context, box) {
                final profile = AdminCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Palette.brandSoft,
                        child: Text(
                          (name.isNotEmpty ? name : me.email).characters.firstOrNull?.toUpperCase() ?? 'A',
                          style: TextStyle(
                              color: Palette.brand, fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: Space.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.isEmpty ? 'Admin' : name, style: AdminText.cardTitle),
                            const SizedBox(height: 2),
                            Text(me.email, style: AdminText.muted),
                            const SizedBox(height: Space.sm),
                            StatusChip(
                              me.isSuperAdmin ? 'Super admin' : 'Admin',
                              tone: me.isSuperAdmin ? Tone.brand : Tone.neutral,
                              icon: me.isSuperAdmin
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.person_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                if (box.maxWidth < 900) {
                  return Column(children: [
                    profile,
                    const SizedBox(height: Space.lg),
                    const AdminAccessCard(),
                  ]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 360, child: profile),
                    const SizedBox(width: Space.lg),
                    const Expanded(child: AdminAccessCard()),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
