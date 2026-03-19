import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../models/workout.dart';

import 'package:flutter/material.dart';

class ExportService {
  static Future<void> exportSessionToPdf(BuildContext context, WorkoutSession session, Map<String, Workout> workoutMap) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(session.name, dateFormat.format(DateTime.now())),
          pw.SizedBox(height: 20),
          ...session.exercises.map((exercise) {
            final workout = workoutMap[exercise.workoutId];
            return _buildExerciseSection(exercise, workout);
          }),
        ],
      ),
    );

    final box = context.findRenderObject() as RenderBox?;
    final bounds = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${session.name.replaceAll(' ', '_')}_session_details.pdf',
      bounds: bounds,
    );
  }

  static Future<void> exportAllSessionsToPdf(BuildContext context, List<WorkoutSession> sessions, Map<String, Workout> workoutMap) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    for (var session in sessions) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            _buildHeader(session.name, dateFormat.format(DateTime.now())),
            pw.SizedBox(height: 20),
            if (session.exercises.isEmpty)
              pw.Center(child: pw.Text('No exercises in this session.', style: const pw.TextStyle(color: PdfColors.grey600)))
            else
              ...session.exercises.map((exercise) {
                final workout = workoutMap[exercise.workoutId];
                return _buildExerciseSection(exercise, workout);
              }),
          ],
        ),
      );
    }

    if (sessions.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(child: pw.Text('No workout sessions found.')),
        ),
      );
    }

    final box = context.findRenderObject() as RenderBox?;
    final bounds = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'all_workout_sessions_${DateTime.now().millisecondsSinceEpoch}.pdf',
      bounds: bounds,
    );
  }

  static pw.Widget _buildHeader(String sessionName, String date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Workout Session Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan900),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Session: $sessionName',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Exported: $date',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.cyan700),
      ],
    );
  }

  static pw.Widget _buildExerciseSection(SessionExercise exercise, Workout? workout) {
    final workoutName = workout?.name ?? 'Unknown Exercise';
    final note = workout?.note ?? '';
    
    final sortedSets = List<SessionSet>.from(exercise.sets)
      ..sort((a, b) {
        int cmp = b.weight.compareTo(a.weight);
        if (cmp == 0) return b.reps.compareTo(a.reps);
        return cmp;
      });
    
    final topSets = sortedSets.take(5).toList();
    final latestWeight = exercise.sets.isNotEmpty ? exercise.sets.last.weight : 0.0;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                workoutName,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan800),
              ),
              pw.Text(
                'Latest: ${latestWeight}kg',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Notes: $note',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
            ),
          ],
          pw.SizedBox(height: 8),
          if (topSets.isNotEmpty)
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Set', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Weight (kg)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Reps', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...topSets.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final set = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('$index')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${set.weight}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${set.reps}')),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4), 
                        child: pw.Text(
                          set.date != null ? DateFormat('d MMM yy').format(set.date!) : '--'
                        )
                      ),
                    ],
                  );
                }),
              ],
            )
          else
            pw.Text('No sets recorded.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Divider(color: PdfColors.grey300),
        ],
      ),
    );
  }
}
