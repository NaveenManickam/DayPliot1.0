import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/app_constants.dart';
import '../providers/app_controller.dart';
import '../screens/my_day_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/planner_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/settings_screen.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/record_editor.dart';
import '../widgets/soft_background.dart';

class DayPilotApp extends StatefulWidget {
  const DayPilotApp({super.key});

  @override
  State<DayPilotApp> createState() => _DayPilotAppState();
}

class _DayPilotAppState extends State<DayPilotApp> {
  late final AppController _controller;
  late final Future<void> _initialization;
  bool _lockOnLaunch = false;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    await _controller.initialize();
    _lockOnLaunch = _controller.hasPin || _controller.biometricEnabled;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _controller.themeMode,
          locale: Locale(_controller.language == 'Tamil' ? 'ta' : 'en'),
          supportedLocales: const [Locale('en'), Locale('ta')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: FutureBuilder<void>(
            future: _initialization,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done || !_controller.isReady) {
                return const _BootScreen();
              }
              if (_lockOnLaunch && !_unlocked) {
                return PinGate(controller: _controller, onUnlocked: () => setState(() => _unlocked = true));
              }
              return HomeShell(controller: _controller);
            },
          ),
        ),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final PageController _pages;
  int _tab = 0;
  bool _quickAddOpen = false;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.controller.language);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SoftBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 7, 18, 4),
              child: Row(children: [
                InkWell(
                  onTap: () => showSettingsScreen(context, widget.controller),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(width: 39, height: 39, decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.tune_rounded, size: 19, color: AppColors.ink)),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('DayPilot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -.3))),
                Container(
                  width: 38, height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.yellowPale, borderRadius: BorderRadius.circular(14)),
                  child: Text(widget.controller.name.isEmpty ? 'D' : widget.controller.name.characters.first.toUpperCase(), style: const TextStyle(color: Color(0xFFB98720), fontSize: 15, fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _tab = index),
                children: [
                  MyDayScreen(controller: widget.controller),
                  PlannerScreen(controller: widget.controller),
                  NotesScreen(controller: widget.controller),
                  ProgressScreen(controller: widget.controller),
                ],
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: _bottomBar(strings),
    );
  }

  Widget _bottomBar(AppStrings strings) => Container(
        padding: EdgeInsets.fromLTRB(12, 9, 12, MediaQuery.paddingOf(context).bottom > 0 ? 5 : 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 20, offset: const Offset(0, -6))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
        ),
        child: Row(children: [
          Expanded(child: _navItem(0, Icons.wb_sunny_rounded, strings.call('my_day'))),
          Expanded(child: _navItem(1, Icons.calendar_month_rounded, strings.call('planner'))),
          SizedBox(width: 60, height: 53, child: Center(child: AnimatedScale(
            scale: _quickAddOpen ? .95 : 1,
            duration: const Duration(milliseconds: 160),
            child: InkWell(
              onTap: _openQuickAdd,
              borderRadius: BorderRadius.circular(20),
              child: Container(width: 50, height: 50, decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: .3), blurRadius: 14, offset: const Offset(0, 5))]), child: const Icon(Icons.add_rounded, color: Colors.white, size: 28)),
            ),
          ))),
          Expanded(child: _navItem(2, Icons.sticky_note_2_rounded, strings.call('notes'))),
          Expanded(child: _navItem(3, Icons.insights_rounded, strings.call('progress'))),
        ]),
      );

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _tab == index;
    return InkWell(
      onTap: () { setState(() => _tab = index); _pages.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic); },
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: selected ? AppColors.bluePale : Colors.transparent, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: selected ? AppColors.blue : AppColors.muted, size: 19)),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? AppColors.blue : AppColors.muted)),
        ]),
      ),
    );
  }

  Future<void> _openQuickAdd() async {
    if (_quickAddOpen) return;
    setState(() => _quickAddOpen = true);
    final type = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      builder: (context) => QuickAddSheet(language: widget.controller.language),
    );
    if (mounted) setState(() => _quickAddOpen = false);
    if (type != null && mounted) {
      await showRecordEditor(context, widget.controller, type: type, initialDate: DateTime.now());
    }
  }
}

class PinGate extends StatefulWidget {
  const PinGate({super.key, required this.controller, required this.onUnlocked});
  final AppController controller;
  final VoidCallback onUnlocked;
  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  final _pin = TextEditingController();
  final _auth = BiometricService();
  String? _error;
  bool _busy = false;

  @override
  void dispose() { _pin.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SoftBackground(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(30), child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 26, offset: const Offset(0, 10))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 66, height: 66, decoration: BoxDecoration(color: AppColors.bluePale, borderRadius: BorderRadius.circular(21)), child: const Icon(Icons.lock_rounded, color: AppColors.blue, size: 31)),
            const SizedBox(height: 17),
            const Text('Welcome back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(widget.controller.hasPin
                ? 'Enter your DayPilot PIN to continue.'
                : 'Use your device biometrics to continue.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            if (widget.controller.hasPin) ...[
              const SizedBox(height: 20),
              TextField(controller: _pin, autofocus: true, obscureText: true, keyboardType: TextInputType.number, maxLength: 8, textAlign: TextAlign.center, decoration: const InputDecoration(counterText: '', hintText: '••••')),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.coral, fontSize: 11))),
              const SizedBox(height: 16),
              FilledButton(onPressed: _busy ? null : _unlockWithPin, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: AppColors.blue), child: _busy ? const CircularProgressIndicator(color: Colors.white) : const Text('Unlock')),
            ] else if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.coral, fontSize: 11))),
            if (widget.controller.biometricEnabled) TextButton.icon(onPressed: _busy ? null : _unlockWithBiometrics, icon: const Icon(Icons.fingerprint_rounded), label: const Text('Use biometrics')),
          ]),
        )))),
      );

  Future<void> _unlockWithPin() async {
    setState(() { _busy = true; _error = null; });
    final ok = await widget.controller.verifyPin(_pin.text);
    if (mounted) {
      setState(() { _busy = false; _error = ok ? null : 'Incorrect PIN. Please try again.'; });
      if (ok) widget.onUnlocked();
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() => _busy = true);
    try {
      final ok = await _auth.authenticate(reason: 'Unlock DayPilot');
      if (mounted) {
        if (ok) {
          widget.onUnlocked();
        } else {
          setState(() => _error = 'Biometric check was cancelled or not recognised.');
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Biometric authentication failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.canvas, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 74, height: 74, decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: .25), blurRadius: 20, offset: const Offset(0, 8))]), child: const Icon(Icons.sailing_rounded, color: Colors.white, size: 38)),
        const SizedBox(height: 14),
        const Text('DayPilot', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 20),
        const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.blue)),
      ])));
}
