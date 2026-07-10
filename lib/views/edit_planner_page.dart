import 'package:flutter/material.dart';
import '../sabloane/planner_sablon.dart';
import '../sabloane/locatie_sablon.dart';
import '../service/locatie_service.dart';
import '../service/planner_service.dart';

class EditPlannerPage extends StatefulWidget {
  final PlannerSablon planner;

  const EditPlannerPage({super.key, required this.planner});

  @override
  State<EditPlannerPage> createState() => _EditPlannerPageState();
}

class _EditPlannerPageState extends State<EditPlannerPage> {
  final _titleController = TextEditingController();

  final LocatieService _locatieService = LocatieService();
  final PlannerService _plannerService = PlannerService();

  DateTime? _dataInceput;
  DateTime? _dataFinal;

  List<SablonLocatie> _allLocations = [];
  final List<SablonLocatie> _selectedLocations = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.planner.titlu;
    _dataInceput = widget.planner.dataInceput;
    _dataFinal = widget.planner.dataFinal;

    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locatii = await _locatieService.getAllLocatii();

    final selectedIds = widget.planner.locatii
        .map((locatie) => locatie['uid'].toString())
        .toList();

    final selected = locatii
        .where((locatie) => selectedIds.contains(locatie.id))
        .toList();

    if (!mounted) return;

    setState(() {
      _allLocations = locatii;
      _selectedLocations.addAll(selected);
      _loading = false;
    });
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataInceput ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        _dataInceput = date;

        if (_dataFinal != null && _dataFinal!.isBefore(date)) {
          _dataFinal = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataFinal ?? _dataInceput ?? DateTime.now(),
      firstDate: _dataInceput ?? DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        _dataFinal = date;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Alege data';

    final zi = date.day.toString().padLeft(2, '0');
    final luna = date.month.toString().padLeft(2, '0');
    final an = date.year.toString();

    return '$zi.$luna.$an';
  }

  void _toggleLocation(SablonLocatie locatie) {
    final alreadySelected = _selectedLocations.any(
      (item) => item.id == locatie.id,
    );

    setState(() {
      if (alreadySelected) {
        _selectedLocations.removeWhere((item) => item.id == locatie.id);
      } else {
        _selectedLocations.add(locatie);
      }
    });
  }

  Future<void> _saveChanges() async {
    final titlu = _titleController.text.trim();

    if (titlu.isEmpty || _dataInceput == null || _dataFinal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completează titlul și perioada.')),
      );
      return;
    }

    if (_selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alege cel puțin o locație.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final locatii = _selectedLocations
        .map((locatie) => {'uid': locatie.id, 'titlu': locatie.nume})
        .toList();

    await _plannerService.updatePlanner(
      plannerId: widget.planner.id,
      titlu: titlu,
      dataInceput: _dataInceput!,
      dataFinal: _dataFinal!,
      locatii: locatii,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Planificarea a fost actualizată.')),
    );

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editează planificarea')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titlu planificare',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickStartDate,
                        icon: const Icon(Icons.date_range),
                        label: Text('Start: ${_formatDate(_dataInceput)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickEndDate,
                        icon: const Icon(Icons.event),
                        label: Text('Final: ${_formatDate(_dataFinal)}'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Locații în itinerar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ..._allLocations.map((locatie) {
                  final selected = _selectedLocations.any(
                    (item) => item.id == locatie.id,
                  );

                  return Card(
                    child: CheckboxListTile(
                      value: selected,
                      onChanged: (_) => _toggleLocation(locatie),
                      title: Text(locatie.nume),
                      subtitle: Text('${locatie.oras}, ${locatie.judet}'),
                      secondary: locatie.imagini.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                locatie.imagini.first,
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.place),
                              ),
                            )
                          : const Icon(Icons.place),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveChanges,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _saving ? 'Se salvează...' : 'Salvează modificările',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
