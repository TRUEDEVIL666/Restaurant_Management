import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  DateTimeRange? _selectedRange;
  String _mode = 'daily'; // hoặc 'monthly'

  Map<String, double> _revenueData = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _fetchRevenue();
  }

  Future<void> _fetchRevenue() async {
    if (_selectedRange == null) return;

    setState(() {
      _loading = true;
    });

    final revenueMap = <String, double>{};
    final snapshot =
        await FirebaseFirestore.instance
            .collection('bills')
            .where('createdAt', isGreaterThanOrEqualTo: _selectedRange!.start)
            .where('createdAt', isLessThanOrEqualTo: _selectedRange!.end)
            .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final time = (data['createdAt'] as Timestamp).toDate();
      final key =
          _mode == 'daily'
              ? DateFormat('dd/MM').format(time)
              : DateFormat('MM/yyyy').format(time);

      final amount = (data['total'] as num).toDouble();
      revenueMap[key] = (revenueMap[key] ?? 0) + amount;
    }

    setState(() {
      _revenueData = revenueMap;
      _loading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
      _fetchRevenue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _revenueData.keys.toList();
    final values = _revenueData.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('📊 Thống kê tổng thu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _selectedRange != null
                        ? '${DateFormat('dd/MM/yyyy').format(_selectedRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedRange!.end)}'
                        : 'Chọn ngày',
                  ),
                ),
                DropdownButton<String>(
                  value: _mode,
                  onChanged: (val) {
                    setState(() {
                      _mode = val!;
                    });
                    _fetchRevenue();
                  },
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Theo ngày')),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text('Theo tháng'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceBetween,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, TitleMeta meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= labels.length)
                                    return const SizedBox();
                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(
                                      labels[index],
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          barGroups: List.generate(labels.length, (index) {
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: values[index],
                                  color: Colors.deepPurple,
                                  width: 18,
                                  borderRadius: BorderRadius.circular(6),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY:
                                        values.reduce((a, b) => a > b ? a : b) +
                                        100000,
                                    color: Colors.grey[200],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
