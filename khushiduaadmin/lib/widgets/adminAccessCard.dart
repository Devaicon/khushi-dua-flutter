import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/colors.dart';
import '../constants/firebaseRef.dart';
import '../controllers/authController.dart';
import '../models/managementModel.dart';
import 'customSnackbar.dart';

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
      CustomSnackbar.show("Error", error, isSuccess: false);
      return;
    }
    CustomSnackbar.show(
        "Success", "Invited $email. They can now sign in with Google.");
    _email.clear();
    _firstName.clear();
    _lastName.clear();
    setState(() => _role = 'Admin');
  }

  Future<void> _confirmRevoke(AuthController auth, ManagementModel admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: rBg,
        title: const Text("Remove admin access?",
            style: TextStyle(color: rWhite, fontWeight: FontWeight.bold)),
        content: Text(
          "${admin.email} will be signed out and lose access to the admin panel.",
          style: const TextStyle(color: rWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: rHint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove access", style: TextStyle(color: rRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await auth.revokeAdmin(admin.id);
    CustomSnackbar.show(
      error == null ? "Success" : "Error",
      error ?? "Removed ${admin.email}.",
      isSuccess: error == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (auth) {
        final me = auth.adminModel;
        final isSuper = me.isSuperAdmin;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: rBg,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Admin access",
                  style: TextStyle(
                      color: rWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                isSuper
                    ? "Invite people by their Google email. They get access the first time they sign in."
                    : "Only a super admin can invite or remove admins.",
                style: const TextStyle(color: rHint),
              ),
              if (isSuper) ...[
                const SizedBox(height: 20),
                _inviteForm(auth),
                const SizedBox(height: 28),
                const _SectionLabel("Pending invites"),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: adminInvitesRef.snapshots(),
                  builder: (context, snapshot) {
                    final invites = snapshot.data?.docs ?? const [];
                    if (invites.isEmpty) {
                      return const _Note("No pending invites.");
                    }
                    return Column(
                      children: [
                        for (final invite in invites)
                          _PersonRow(
                            title: (invite.data()['email'] ?? invite.id)
                                .toString(),
                            subtitle:
                                (invite.data()['role'] ?? 'Admin').toString(),
                            action: TextButton(
                              onPressed: () async {
                                final error =
                                    await auth.cancelInvite(invite.id);
                                if (error != null) {
                                  CustomSnackbar.show("Error", error,
                                      isSuccess: false);
                                }
                              },
                              child: const Text("Cancel invite",
                                  style: TextStyle(color: rRed)),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 28),
              const _SectionLabel("Admins"),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: managementRef.snapshots(),
                builder: (context, snapshot) {
                  final admins = [
                    for (final doc in snapshot.data?.docs ?? const [])
                      ManagementModel.fromMap({...doc.data(), 'id': doc.id}),
                  ]..sort((a, b) => a.email.compareTo(b.email));
                  if (admins.isEmpty) return const _Note("Loading admins…");
                  return Column(
                    children: [
                      for (final admin in admins)
                        _PersonRow(
                          title: "${admin.firstName} ${admin.lastName}"
                                  .trim()
                                  .isEmpty
                              ? admin.email
                              : "${admin.firstName} ${admin.lastName}".trim(),
                          subtitle:
                              "${admin.email} · ${admin.role}${admin.id == me.id ? ' · you' : ''}",
                          action: isSuper && admin.id != me.id
                              ? TextButton(
                                  onPressed: () => _confirmRevoke(auth, admin),
                                  child: const Text("Remove",
                                      style: TextStyle(color: rRed)),
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
        children: [
          TextFormField(
            controller: _email,
            style: const TextStyle(color: rWhite),
            decoration: _decoration("Google email"),
            validator: (value) => _emailPattern.hasMatch((value ?? '').trim())
                ? null
                : "Enter a valid email address",
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstName,
                  style: const TextStyle(color: rWhite),
                  decoration: _decoration("First name"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastName,
                  style: const TextStyle(color: rWhite),
                  decoration: _decoration("Last name"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            dropdownColor: rBg,
            style: const TextStyle(color: rWhite),
            decoration: _decoration("Role"),
            items: const [
              DropdownMenuItem(value: 'Admin', child: Text("Admin")),
              DropdownMenuItem(
                  value: 'Super_Admin',
                  child: Text("Super admin (can manage admins)")),
            ],
            onChanged: (value) => setState(() => _role = value ?? 'Admin'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _sending ? null : () => _invite(auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: rGreen,
                foregroundColor: rWhite,
              ),
              child: Text(_sending ? "Sending…" : "Send invite"),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: rHint),
        filled: true,
        fillColor: rBlack,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: rHint.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rGreen),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rRed),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: rWhite, fontSize: 16, fontWeight: FontWeight.bold)),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: rHint));
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: rWhite)),
                Text(subtitle,
                    style: const TextStyle(color: rHint, fontSize: 12)),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
