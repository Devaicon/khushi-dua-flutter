import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../constants/theme.dart';
import '../controllers/authController.dart';
import '../models/managementModel.dart';
import 'customSnackbar.dart';
import 'ui.dart';

/// Who can use the admin panel. Super admins invite people by Google email,
/// cancel pending invites, and remove admins; everyone else sees the list.
class AdminAccessCard extends StatefulWidget {
  const AdminAccessCard({super.key});

  @override
  State<AdminAccessCard> createState() => _AdminAccessCardState();
}

class _AdminAccessCardState extends State<AdminAccessCard> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  String _role = 'Admin';
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _invite(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final email = _email.text.trim();
    final error = await auth.inviteAdmin(
      email: email,
      role: _role,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (error != null) {
      CustomSnackbar.show("Couldn't invite", error, isSuccess: false);
      return;
    }
    CustomSnackbar.show(
        "Invited", "$email can now sign in with Google.");
    _email.clear();
    _firstName.clear();
    _lastName.clear();
    setState(() => _role = 'Admin');
  }

  Future<void> _confirmRevoke(AuthController auth, ManagementModel admin) async {
    if (!await confirmAction(
      context,
      title: 'Remove admin access?',
      message:
          '${admin.email} will be signed out and lose access to the admin panel.',
      confirmLabel: 'Remove access',
      danger: true,
    )) {
      return;
    }

    final error = await auth.revokeAdmin(admin.id);
    CustomSnackbar.show(
      error == null ? "Access removed" : "Couldn't remove",
      error ?? "${admin.email} can no longer sign in.",
      isSuccess: error == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (auth) {
        final me = auth.adminModel;
        final isSuper = me.isSuperAdmin;

        return AdminCard(
          title: 'Admin access',
          subtitle: isSuper
              ? 'Invite people by their Google email. They get access the first time they sign in.'
              : 'Only a super admin can invite or remove admins.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isSuper) ...[
                _inviteForm(auth),
                const SizedBox(height: Space.xl),
                const FieldLabel('Pending invites'),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: adminInvitesRef.snapshots(),
                  builder: (context, snapshot) {
                    final invites = snapshot.data?.docs ?? [];
                    if (invites.isEmpty) {
                      return Text("No pending invites.", style: AdminText.muted);
                    }
                    return Column(
                      children: [
                        for (final invite in invites)
                          _PersonRow(
                            title: (invite.data()['email'] ?? invite.id).toString(),
                            subtitle: (invite.data()['role'] ?? 'Admin').toString(),
                            action: AdminButton.ghost(
                              label: 'Cancel invite',
                              dense: true,
                              onPressed: () async {
                                final error = await auth.cancelInvite(invite.id);
                                if (error != null) {
                                  CustomSnackbar.show("Couldn't cancel", error,
                                      isSuccess: false);
                                }
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: Space.xl),
              ],
              const FieldLabel('Admins'),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: managementRef.snapshots(),
                builder: (context, snapshot) {
                  final admins = [
                    for (final doc in snapshot.data?.docs ?? [])
                      ManagementModel.fromMap({...doc.data(), 'id': doc.id}),
                  ]..sort((a, b) => a.email.compareTo(b.email));
                  if (admins.isEmpty) {
                    return Text("Loading admins…", style: AdminText.muted);
                  }
                  return Column(
                    children: [
                      for (final admin in admins)
                        _PersonRow(
                          title: "${admin.firstName} ${admin.lastName}".trim().isEmpty
                              ? admin.email
                              : "${admin.firstName} ${admin.lastName}".trim(),
                          subtitle:
                              "${admin.email} · ${admin.isSuperAdmin ? 'Super admin' : 'Admin'}"
                              "${admin.id == me.id ? ' · you' : ''}",
                          action: isSuper && admin.id != me.id
                              ? AdminButton.ghost(
                                  label: 'Remove',
                                  dense: true,
                                  onPressed: () => _confirmRevoke(auth, admin),
                                )
                              : null,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _inviteForm(AuthController auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: "Google email"),
            validator: (value) => _emailPattern.hasMatch((value ?? '').trim())
                ? null
                : "Enter a valid email address",
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: "First name"),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: "Last name"),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: "Role"),
            items: const [
              DropdownMenuItem(value: 'Admin', child: Text("Admin")),
              DropdownMenuItem(
                  value: 'Super_Admin',
                  child: Text("Super admin (can manage admins)")),
            ],
            onChanged: (value) => setState(() => _role = value ?? 'Admin'),
          ),
          const SizedBox(height: Space.lg),
          Align(
            alignment: Alignment.centerRight,
            child: AdminButton(
              label: "Send invite",
              icon: Icons.person_add_alt_1_rounded,
              busy: _sending,
              onPressed: () => _invite(auth),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Palette.brandSoft,
            child: Text(title.characters.firstOrNull?.toUpperCase() ?? '?',
                style: TextStyle(color: Palette.brand, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: AdminText.muted),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
