import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_constants.dart';
import '../providers/app_controller.dart';
import '../services/biometric_service.dart';
import '../utils/app_strings.dart';

Future<void> showSettingsScreen(BuildContext context, AppController controller) async {
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SettingsScreen(controller: controller)));
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _auth = BiometricService();
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(title: Text(context.dp('Settings'), style: TextStyle(fontWeight: FontWeight.w800)), leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          _GroupTitle(context.dp('Your profile')),
          _SettingsCard(children: [
            _SettingRow(icon: Icons.person_rounded, title: context.dp('Your name'), subtitle: controller.name.isEmpty ? context.dp('Add your name for a personal greeting') : controller.name,
              onTap: _editName),
          ]),
          _GroupTitle(context.dp('Appearance')),
          _SettingsCard(children: [
            Padding(padding: const EdgeInsets.fromLTRB(15, 15, 15, 8), child: Text(context.dp('Theme'), style: Theme.of(context).textTheme.titleMedium)),
            Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 14), child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_rounded, size: 16), label: Text(context.dp('Light'))),
                ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode_rounded, size: 16), label: Text(context.dp('Dark'))),
                ButtonSegment(value: 'system', icon: Icon(Icons.settings_suggest_rounded, size: 16), label: Text(context.dp('System'))),
              ],
              selected: {controller.theme},
              onSelectionChanged: (value) => controller.setTheme(value.first),
            )),
            const Divider(height: 1),
            _SettingRow(icon: Icons.translate_rounded, title: context.dp('Language'), subtitle: controller.language,
              trailing: DropdownButton<String>(value: controller.language, underline: const SizedBox(), items: const [DropdownMenuItem(value: 'English', child: Text('English')), DropdownMenuItem(value: 'Tamil', child: Text('தமிழ்'))], onChanged: (value) { if (value != null) controller.setLanguage(value); }),
              onTap: () {}),
          ]),
          _GroupTitle(context.dp('Reminders')),
          _SettingsCard(children: [
            SwitchListTile.adaptive(
              secondary: const _IconBox(icon: Icons.notifications_active_rounded, color: AppColors.yellow, pale: AppColors.yellowPale),
              title: Text(context.dp('Notifications'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              subtitle: Text(context.dp('Allow local reminders for tasks, habits and events'), style: TextStyle(fontSize: 10)),
              value: controller.notificationsEnabled,
              onChanged: (value) async {
                if (value) {
                  final ok = await controller.requestNotificationPermissions();
                  if (!ok && mounted) _message('Android notification permission was not granted.');
                }
                await controller.setNotificationsEnabled(value);
              },
            ),
            ListTile(leading: const _IconBox(icon: Icons.alarm_on_rounded, color: AppColors.blue, pale: AppColors.bluePale), title: Text(context.dp('Test notification access'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text(context.dp('Open Android permission prompts'), style: TextStyle(fontSize: 10)), onTap: () async { final granted = await controller.requestNotificationPermissions(); if (mounted) _message(granted ? 'Notification permission request completed.' : 'Notifications are not allowed on this device.'); }),
          ]),
          _GroupTitle(context.dp('Privacy & security')),
          _SettingsCard(children: [
            _SettingRow(icon: Icons.password_rounded, title: context.dp(controller.hasPin ? 'Change app PIN' : 'Set app PIN'), subtitle: context.dp(controller.hasPin ? 'PIN lock is enabled' : 'Add an optional PIN lock'), onTap: _editPin),
            const Divider(height: 1),
            SwitchListTile.adaptive(
              secondary: const _IconBox(icon: Icons.fingerprint_rounded, color: AppColors.mint, pale: AppColors.mintPale),
              title: Text(context.dp('Biometric unlock'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              subtitle: Text(context.dp('Use fingerprint or face unlock when supported'), style: TextStyle(fontSize: 10)),
              value: controller.biometricEnabled,
              onChanged: (value) => _toggleBiometric(value),
            ),
            if (controller.hasPin) ListTile(leading: const _IconBox(icon: Icons.lock_open_rounded, color: AppColors.coral, pale: AppColors.coralPale), title: Text(context.dp('Remove app PIN'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), onTap: _removePin),
          ]),
          _GroupTitle(context.dp('Data & backup')),
          _SettingsCard(children: [
            _SettingRow(icon: Icons.file_upload_outlined, title: context.dp('Export backup'), subtitle: context.dp('Create a portable JSON copy of your records'), onTap: _exportBackup),
            const Divider(height: 1),
            _SettingRow(icon: Icons.file_download_outlined, title: context.dp('Restore backup'), subtitle: context.dp('Import a DayPilot JSON backup'), onTap: _importBackup),
          ]),
          _GroupTitle(context.dp('About')),
          _SettingsCard(children: [
            ListTile(leading: const _IconBox(icon: Icons.sailing_rounded, color: AppColors.blue, pale: AppColors.bluePale), title: Text(context.dp('DayPilot'), style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(context.dp('Version 1.0.0 · Offline-first personal planner'), style: TextStyle(fontSize: 10))),
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: Text(context.dp('Your personal data stays on this device unless you explicitly export a backup.'), style: TextStyle(fontSize: 10, color: AppColors.muted, height: 1.4))),
          ]),
          if (_working) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: widget.controller.name);
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: Text(context.dp('Your name')),
      content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Enter your name')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.dp('Cancel'))), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(context.dp('Save')))],
    ));
    if (result != null) await widget.controller.setName(result);
    controller.dispose();
  }

  Future<void> _editPin() async {
    final first = TextEditingController();
    final second = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: Text(context.dp(widget.controller.hasPin ? 'Change app PIN' : 'Set app PIN')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: first, keyboardType: TextInputType.number, obscureText: true, maxLength: 8, decoration: InputDecoration(labelText: context.dp('New PIN (4–8 digits)'))),
        TextField(controller: second, keyboardType: TextInputType.number, obscureText: true, maxLength: 8, decoration: const InputDecoration(labelText: context.dp('Confirm PIN'))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.dp('Cancel'))), FilledButton(onPressed: () {
        if (first.text.length < 4 || first.text.length > 8 || first.text != second.text || int.tryParse(first.text) == null) return;
        Navigator.pop(context, first.text);
      }, child: Text(context.dp('Save PIN')))],
    ));
    if (result != null) { await widget.controller.setPin(result); if (mounted) _message('Your app PIN has been saved.'); }
    first.dispose(); second.dispose();
  }

  Future<void> _removePin() async {
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(context.dp('Remove app PIN?')),
      content: Text(context.dp('Anyone using this device will be able to open DayPilot.')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.dp('Keep PIN'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.dp('Remove')))],
    ));
    if (yes == true) await widget.controller.removePin();
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (!enable) { await widget.controller.setBiometricEnabled(false); return; }
    try {
      final available = await _auth.isAvailable();
      if (!available) { if (mounted) _message('No enrolled biometric is available on this device.'); return; }
      final passed = await _auth.authenticate(reason: 'Confirm to enable DayPilot biometric unlock');
      if (passed) await widget.controller.setBiometricEnabled(true);
    } catch (error) {
      if (mounted) _message('Biometric setup is not available: $error');
    }
  }

  Future<void> _exportBackup() async {
    final passphrase = TextEditingController();
    final confirmPassphrase = TextEditingController();
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.dp('Protect your backup')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.dp('Choose a password of at least 8 characters. You will need it to restore this backup.'), style: TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          TextField(controller: passphrase, obscureText: true, decoration: const InputDecoration(labelText: context.dp('Backup password'))),
          const SizedBox(height: 8),
          TextField(controller: confirmPassphrase, obscureText: true, decoration: const InputDecoration(labelText: context.dp('Confirm password'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.dp('Cancel'))),
          FilledButton(onPressed: () {
            if (passphrase.text.length < 8 || passphrase.text != confirmPassphrase.text) return;
            Navigator.pop(context, passphrase.text);
          }, child: Text(context.dp('Encrypt backup'))),
        ],
      ),
    );
    passphrase.dispose();
    confirmPassphrase.dispose();
    if (chosen == null) return;
    setState(() => _working = true);
    try {
      final data = await widget.controller.exportEncryptedBackup(chosen);
      await Clipboard.setData(ClipboardData(text: data));
      if (mounted) _message('Encrypted backup copied. Keep your password safe; it cannot be recovered.');
    } catch (error) {
      if (mounted) _message('Could not create backup: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _importBackup() async {
    final source = TextEditingController();
    final passphrase = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.dp('Restore backup')),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: source, minLines: 5, maxLines: 8, decoration: InputDecoration(hintText: context.dp('Paste your DayPilot backup JSON here')), style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 10),
            TextField(controller: passphrase, obscureText: true, decoration: const InputDecoration(labelText: context.dp('Backup password (encrypted backups)'))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.dp('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.dp('Restore'))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _working = true);
      try {
        await widget.controller.importEncryptedBackup(source.text, passphrase.text);
        if (mounted) _message('Backup restored.');
      } catch (error) {
        if (mounted) _message('Could not restore backup. Check the password and backup file.');
      } finally {
        if (mounted) setState(() => _working = false);
      }
    }
    source.dispose();
    passphrase.dispose();
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(3, 21, 3, 9), child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w800)));
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20)), child: Column(children: children));
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title, required this.subtitle, required this.onTap, this.trailing});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: _IconBox(icon: icon, color: AppColors.blue, pale: AppColors.bluePale),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      );
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color, required this.pale});
  final IconData icon;
  final Color color;
  final Color pale;
  @override
  Widget build(BuildContext context) => Container(width: 38, height: 38, decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 18));
}
