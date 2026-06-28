import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pressure_provider.dart';
import 'services/notification_service.dart';

class Przypomnienia extends ConsumerStatefulWidget {
  const Przypomnienia({super.key});

  @override
  ConsumerState<Przypomnienia> createState() => _PrzypomnieniaState();
}

class _PrzypomnieniaState extends ConsumerState<Przypomnienia> {
  bool _pressureReminderEnabled = false;
  bool _morningMedicationEnabled = false;
  bool _eveningMedicationEnabled = false;
  TimeOfDay _morningMedicationTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningMedicationTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ref.read(notificationServiceProvider);
    final pressureEnabled = await service.areRemindersEnabled();
    final medicationSettings = await service.getMedicationReminderSettings();

    if (!mounted) return;
    setState(() {
      _pressureReminderEnabled = pressureEnabled;
      _morningMedicationEnabled = medicationSettings.morningEnabled;
      _eveningMedicationEnabled = medicationSettings.eveningEnabled;
      _morningMedicationTime = _toTimeOfDay(medicationSettings.morningTime);
      _eveningMedicationTime = _toTimeOfDay(medicationSettings.eveningTime);
    });
  }

  Future<void> _setPressureReminder(bool enabled) async {
    setState(() {
      _isSaving = true;
    });

    final success = await ref
        .read(notificationServiceProvider)
        .setRemindersEnabled(enabled, entries: ref.read(pressureProvider));

    if (!mounted) return;
    setState(() {
      _pressureReminderEnabled = success ? enabled : _pressureReminderEnabled;
      _isSaving = false;
    });

    if (!success) {
      _showPermissionError();
    }
  }

  Future<void> _setMedicationReminder(
    MedicationReminderPeriod period,
    bool enabled,
  ) async {
    setState(() {
      _isSaving = true;
    });

    final success = await ref
        .read(notificationServiceProvider)
        .setMedicationReminderEnabled(period, enabled);

    if (!mounted) return;
    setState(() {
      if (success) {
        switch (period) {
          case MedicationReminderPeriod.morning:
            _morningMedicationEnabled = enabled;
          case MedicationReminderPeriod.evening:
            _eveningMedicationEnabled = enabled;
        }
      }
      _isSaving = false;
    });

    if (!success) {
      _showPermissionError();
    }
  }

  Future<void> _pickMedicationTime(MedicationReminderPeriod period) async {
    final currentTime = period == MedicationReminderPeriod.morning
        ? _morningMedicationTime
        : _eveningMedicationTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    if (picked == null) return;

    await ref
        .read(notificationServiceProvider)
        .setMedicationReminderTime(period, _toReminderTime(picked));

    if (!mounted) return;
    setState(() {
      switch (period) {
        case MedicationReminderPeriod.morning:
          _morningMedicationTime = picked;
        case MedicationReminderPeriod.evening:
          _eveningMedicationTime = picked;
      }
    });
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Nie udało się włączyć powiadomień. Sprawdź uprawnienia aplikacji.',
        ),
      ),
    );
  }

  ReminderTime _toReminderTime(TimeOfDay time) {
    return ReminderTime(hour: time.hour, minute: time.minute);
  }

  TimeOfDay _toTimeOfDay(ReminderTime time) {
    return TimeOfDay(hour: time.hour, minute: time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Przypomnienia'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              secondary: Icon(Icons.monitor_heart_outlined, color: Colors.black),
              title: Text('Przypomnienie o pomiarze',
                      style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
              ),
              subtitle: Text(
                'Powiadomienie o 18:00, jeśli danego dnia nie ma jeszcze wpisu.',
              ),
              value: _pressureReminderEnabled,
              onChanged: _isSaving ? null : _setPressureReminder,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Icon(Icons.medication_outlined),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Przypomnienie o lekach',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MedicationReminderTile(
                    title: 'Rano',
                    time: _morningMedicationTime,
                    enabled: _morningMedicationEnabled,
                    onTimeTap: () =>
                        _pickMedicationTime(MedicationReminderPeriod.morning),
                    onChanged: _isSaving
                        ? null
                        : (enabled) => _setMedicationReminder(
                            MedicationReminderPeriod.morning,
                            enabled,
                          ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _MedicationReminderTile(
                    title: 'Wieczorem',
                    time: _eveningMedicationTime,
                    enabled: _eveningMedicationEnabled,
                    onTimeTap: () =>
                        _pickMedicationTime(MedicationReminderPeriod.evening),
                    onChanged: _isSaving
                        ? null
                        : (enabled) => _setMedicationReminder(
                            MedicationReminderPeriod.evening,
                            enabled,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationReminderTile extends StatelessWidget {
  const _MedicationReminderTile({
    required this.title,
    required this.time,
    required this.enabled,
    required this.onTimeTap,
    required this.onChanged,
  });

  final String title;
  final TimeOfDay time;
  final bool enabled;
  final VoidCallback onTimeTap;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text('Godzina: ${time.format(context)}'),
      value: enabled,
      onChanged: onChanged,
      secondary: OutlinedButton.icon(
        onPressed: onTimeTap,
        icon: const Icon(Icons.schedule),
        label: Text(time.format(context)),
      ),
    );
  }
}
