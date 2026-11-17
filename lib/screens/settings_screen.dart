import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_constants.dart';
import '../providers/app_controller.dart';
import '../services/biometric_service.dart';

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
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800)), leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          _GroupTitle('Your profile'),
          _SettingsCard(children: [
            _SettingRow(icon: Icons.person_rounded, title: 'Your name', subtitle: controller.name.isEmpty ? 'Add your name for a personal greeting' : controller.name,
              onTap: _editName),
          ]),
          _GroupTitle('Appearance'),
          _SettingsCard(children: [
            Padding(padding: const EdgeInsets.fromLTRB(15, 15, 15, 8), child: Text('Theme', style: Theme.of(context).textTheme.titleMedium)),
            Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 14), child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_rounded, size: 16), label: Text('Light')),
                ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode_rounded, size: 16), label: Text('Dark')),
                ButtonSegment(value: 'system', icon: Icon(Icons.settings_suggest_rounded, size: 16), label: Text('System')),
              ],
              selected: {controller.theme},
              onSelectionChanged: (value) => controller.setTheme(value.first),
            )),
            const Divider(height: 1),
            _SettingRow(icon: Icons.translate_rounded, title: 'Language', subtitle: controller.language,
              trailing: DropdownButton<String>(value: controller.language, underline: const SizedBox(), items: const [DropdownMenuItem(value: 'English', child: Text('English')), DropdownMenuItem(value: 'Tamil', child: Text('தமிழ்'))], onChanged: (value) { if (value != null) controller.setLanguage(value); }),
              onTap: () {}),
          ]),
          _GroupTitle('Reminders'),
          _SettingsCard(children: [
            SwitchListTile.adaptive(
              secondary: const _IconBox(icon: Icons.notifications_active_rounded, color: AppColors.yellow, pale: AppColors.yellowPale),
              title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              subtitle: const Text('Allow local reminders for tasks, habits and events', style: TextStyle(fontSize: 10)),
              value: controller.notificationsEnabled,
              onChanged: (value) async {
                if (value) {
                  final ok = await controller.requestNotificationPermissions();
                  if (!ok && mounted) _message('Android notification permission was not granted.');
                }
                await controller.setNotificationsEnabled(value);
              },
            ),
            ListTile(leading: const _IconBox(icon: Icons.alarm_on_rounded, color: AppColors.blue, pale: AppColors.bluePale), title: const Text('Test notification access', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: const Text('Open Android permission prompts', style: TextStyle(fontSize: 10)), onTap: () async { final granted = await controller.requestNotificationPermissions(); if (mounted) _message(granted ? 'Notification permission request completed.' : 'Notifications are not allowed on this device.'); }),
          ]),
          _GroupTitle('Privacy & security'),
          _SettingsCard(children: [
            _SettingRow(icon: Icons.password_rounded, title: controller.hasPin ? 'Change app PIN' : 'Set app PIN', subtitle: controller.hasPin ? 'PIN lock is enabled' : 'Add an optional PIN lock', onTap: _editPin),
            const Divider(height: 1),
            SwitchListTile.adaptive(
              secondary: const _IconBox(icon: Icons.fingerprint_rounded, color: AppColors.mint, pale: AppColors.mintPale),
              title: const Text('Biometric unlock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              subtitle: const Text('Use fingerprint or face unlock when supported', style: TextStyle(fontSize: 10)),
              value: controller.biometricEnabled,
              onChanged: (value) => _toggleBiometric(value),
            ),
            if (controller.hasPin) ListTile(leading: const _IconBox(icon: Icons.lock_open_rounded, color: AppColors.coral, pale: AppColors.coralPale), title: const Text('Remove app PIN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), onTap: _removePin),
          ]),
          _GroupTitle('Data & backup'),
          _SettingsCard(children: [
            _SettingRow(icon: Icons.file_upload_outlined, title: 'Export backup', subtitle: 'Create a portable JSON copy of your records', onTap: _exportBackup),
            const Divider(height: 1),
            _SettingRow(icon: Icons.file_download_outlined, title: 'Restore backup', subtitle: 'Import a DayPilot JSON backup', onTap: _importBackup),
          ]),
          _GroupTitle('About'),
          _SettingsCard(children: [
            const ListTile(leading: _IconBox(icon: Icons.sailing_rounded, color: AppColors.blue, pale: AppColors.bluePale), title: Text('DayPilot', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Version 1.0.0 · Offline-first personal planner', style: TextStyle(fontSize: 10))),
            const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 14), child: Text('Your personal data stays on this device unless you explicitly export a backup.', style: TextStyle(fontSize: 10, color: AppColors.muted, height: 1.4))),
          ]),
          if (_working) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: widget.controller.name);
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Your name'),
      content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Enter your name')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save'))],
    ));
    if (result != null) await widget.controller.setName(result);
    controller.dispose();
  }

  Future<void> _editPin() async {
    final first = TextEditingController();
    final second = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: Text(widget.controller.hasPin ? 'Change app PIN' : 'Set app PIN'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: first, keyboardType: TextInputType.number, obscureText: true, maxLength: 8, decoration: const InputDecoration(labelText: 'New PIN (4–8 digits)')),
        TextField(controller: second, keyboardType: TextInputType.number, obscureText: true, maxLength: 8, decoration: const InputDecoration(labelText: 'Confirm PIN')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () {
        if (first.text.length < 4 || first.text.length > 8 || first.text != second.text || int.tryParse(first.text) == null) return;
        Navigator.pop(context, first.text);
      }, child: const Text('Save PIN'))],
    ));
    if (result != null) { await widget.controller.setPin(result); if (mounted) _message('Your app PIN has been saved.'); }
    first.dispose(); second.dispose();
  }

  Future<void> _removePin() async {
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Remove app PIN?'),
      content: const Text('Anyone using this device will be able to open DayPilot.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep PIN')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove'))],
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
    final data = widget.controller.exportBackup();
    await showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: const Text('DayPilot backup'),
      content: SizedBox(width: double.maxFinite, height: 300, child: SingleChildScrollView(child: SelectableText(data, style: const TextStyle(fontSize: 10)))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')), FilledButton.icon(onPressed: () async { await Clipboard.setData(ClipboardData(text: data)); if (context.mounted) Navigator.pop(context); if (mounted) _message('Backup JSON copied. Save it somewhere safe.'); }, icon: const Icon(Icons.copy_rounded, size: 16), label: const Text('Copy JSON'))],
    ));
  }

  Future<void> _importBackup() async {
    final source = TextEditingController();
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Restore backup'),
      content: SizedBox(width: double.maxFinite, child: TextField(controller: source, minLines: 5, maxLines: 9, decoration: const InputDecoration(hintText: 'Paste your DayPilot backup JSON here'), style: const TextStyle(fontSize: 11))),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore'))],
    ));
    if (confirm == true) {
      setState(() => _working = true);
      try { await widget.controller.importBackup(source.text); if (mounted) _message('Backup restored.'); }
      catch (error) { if (mounted) _message('Could not restore backup: $error'); }
      finally { if (mounted) setState(() => _working = false); }
    }
    source.dispose();
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
