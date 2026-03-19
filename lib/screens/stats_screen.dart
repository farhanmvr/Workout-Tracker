import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/stats_provider.dart';
import '../providers/workout_provider.dart';
import '../models/session.dart';
import '../models/body_weight.dart';
import '../widgets/premium_card.dart';
import '../utils/dialogs.dart';
import 'profiles_screen.dart';
import '../providers/profile_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedTabIndex = 0; // 0 for Attendance, 1 for Weight Progress

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Set<DateTime> _getAttendanceDates(List<WorkoutSession> sessions) {
    final dates = <DateTime>{};
    for (var session in sessions) {
      for (var exercise in session.exercises) {
        for (var set in exercise.sets) {
          if (set.date != null) {
            dates.add(DateTime(set.date!.year, set.date!.month, set.date!.day));
          }
        }
      }
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stats'),
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilesScreen()),
                  );
                },
                icon: const CircleAvatar(
                  radius: 14,
                  child: Icon(Icons.person, size: 16),
                ),
                label: Text(
                  profileProvider.activeProfile?.name ?? 'Profile',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer2<StatsProvider, WorkoutProvider>(
        builder: (context, statsProvider, workoutProvider, child) {
          final history = statsProvider.weightHistory;
          final currentWeight = history.isNotEmpty ? history.last.weight : null;
          final bmi = statsProvider.currentBmi;
          final height = statsProvider.height;
          final attendanceDates = _getAttendanceDates(workoutProvider.sessions);

          return ListView(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
            children: [
              _buildSummaryRow(context, currentWeight, bmi, height, statsProvider),
              const SizedBox(height: 24),
              _buildTabSwitcher(),
              const SizedBox(height: 24),
              if (_selectedTabIndex == 0) ...[
                const Text(
                  'Gym Attendance',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildCalendar(context, attendanceDates),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weight Progress',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _showLogWeightDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Log Weight'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (history.isEmpty)
                  const SizedBox(
                    height: 200,
                    child: Center(child: Text('No weight recorded yet.')),
                  )
                else ...[
                  SizedBox(
                    height: 250,
                    child: PremiumCard(
                      padding: const EdgeInsets.all(16),
                      margin: EdgeInsets.zero,
                      child: _buildChart(context, history),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Weight History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...history.reversed.map((record) => _buildWeightRecordTile(context, record, statsProvider)),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabSwitcher() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.grey.withValues(alpha: 0.1);
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _selectedTabIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Attendance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Weight Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, double? weight, double? bmi, double? height, StatsProvider provider) {
    return Row(
      children: [
        _buildStatCard(
          context,
          'Weight',
          weight != null ? weight.toStringAsFixed(1) : '--',
          'kg',
          Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          context,
          'BMI',
          bmi != null ? bmi.toStringAsFixed(1) : '--',
          _getBmiCategory(bmi),
          Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          context,
          'Height',
          height != null ? height.toStringAsFixed(0) : '--',
          'cm',
          Colors.orange,
          onTap: () => _showUpdateHeightDialog(context, provider),
          showEditIcon: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, String subtitle, Color baseColor, {VoidCallback? onTap, bool showEditIcon = false}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                baseColor,
                baseColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  if (showEditIcon) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, color: Colors.white70, size: 10),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightRecordTile(BuildContext context, BodyWeightRecord record, StatsProvider provider) {
    return PremiumCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.zero,
      child: Slidable(
        key: ValueKey(record.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.5,
          children: [
            SlidableAction(
              onPressed: (context) => _showEditWeightDialog(context, record),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (context) async {
                final confirm = await showDeleteConfirmation(context, 'Weight Entry');
                if (confirm == true) {
                  provider.deleteWeight(record.id);
                }
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: ListTile(
          title: Text('${record.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat('d MMM yyyy').format(record.date)),
          trailing: const Icon(Icons.chevron_left, color: Colors.grey, size: 16),
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, Set<DateTime> attendanceDates) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard(
      padding: const EdgeInsets.all(8),
      margin: EdgeInsets.zero,
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        availableGestures: AvailableGestures.all,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(color: isDark ? Colors.redAccent.withValues(alpha: 0.7) : Colors.redAccent),
        ),
        eventLoader: (day) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          if (attendanceDates.contains(normalizedDay)) {
            return ['present'];
          }
          return [];
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  String _getBmiCategory(double? bmi) {
    if (bmi == null) return '--';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Widget _buildChart(BuildContext context, List history) {
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index < 0 || index >= history.length) {
                  return const SizedBox.shrink();
                }
                final date = history[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    DateFormat('d MMM').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Theme.of(context).colorScheme.surface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y} kg',
                  TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            barWidth: 6,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateHeightDialog(BuildContext context, StatsProvider provider) {
    final heightController =
        TextEditingController(text: provider.height?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Height'),
        content: TextField(
          controller: heightController,
          decoration: const InputDecoration(labelText: 'Height (cm)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final h = double.tryParse(heightController.text);
              if (h != null) {
                provider.setHeight(h);
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showLogWeightDialog(BuildContext context) {
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Weight'),
        content: TextField(
          controller: weightController,
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(weightController.text);
              if (w != null) {
                Provider.of<StatsProvider>(context, listen: false)
                    .addWeight(w, DateTime.now());
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditWeightDialog(BuildContext context, BodyWeightRecord record) {
    final weightController = TextEditingController(text: record.weight.toString());
    DateTime selectedDate = record.date;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Weight Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(DateFormat('d MMM yyyy').format(selectedDate)),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                final w = double.tryParse(weightController.text);
                if (w != null) {
                  Provider.of<StatsProvider>(context, listen: false)
                      .updateWeight(record.id, w, selectedDate);
                  Navigator.pop(context);
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}
