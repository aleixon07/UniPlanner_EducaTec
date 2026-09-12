import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import 'sidebar.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  List<DateTime?> _dates = [DateTime.now()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarUniPlanner(),
      drawer: const Sidebar(),
      backgroundColor: Colors.grey.shade100,

      body: Column(
        children: [
          // ============================================================
          // CALENDÁRIO
          // ============================================================

          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: Center(
                child: CalendarDatePicker2(
                  config: CalendarDatePicker2Config(
                    calendarType: CalendarDatePicker2Type.single,
                    firstDayOfWeek: 1,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),

                    weekdayLabels: const [
                      'Dom',
                      'Seg',
                      'Ter',
                      'Qua',
                      'Qui',
                      'Sex',
                      'Sáb',
                    ],

                    weekdayLabelTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                    ),

                    controlsTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3750B5),
                    ),

                    selectedDayHighlightColor: const Color(0xFF3750B5),

                    selectedDayTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),

                    dayTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      color: Colors.black87,
                    ),

                    todayTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3750B5),
                    ),

                    disabledDayTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      color: Colors.grey,
                    ),

                    dayBorderRadius: BorderRadius.circular(8),

                    centerAlignModePicker: true,

                    lastMonthIcon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF3750B5),
                    ),

                    nextMonthIcon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF3750B5),
                    ),
                  ),

                  value: _dates,

                  onValueChanged: (dates) {
                    setState(() {
                      _dates = dates;
                    });
                  },
                ),
              ),
            ),
          ),

          // ============================================================
          // AVISOS
          // ============================================================
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Avisos',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF203F7D),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ÚNICO AVISO DE EXEMPLO
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE85D75),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Reunião',
                                      style: TextStyle(
                                        fontFamily: 'NunitoSans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF203F7D),
                                      ),
                                    ),

                                    SizedBox(width: 8),

                                    Text(
                                      '• 17:30',
                                      style: TextStyle(
                                        fontFamily: 'NunitoSans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 4),

                                Text(
                                  'Reunião de conselho de classe',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============================================================
          // AULAS DO DIA
          // ============================================================
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF203F7D),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  const Text(
                    'Aulas do Dia',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ÚNICA AULA DE EXEMPLO
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // SALA
                          Container(
                            width: 75,
                            height: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE3E3E3),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sala',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),

                                SizedBox(height: 2),

                                Text(
                                  '305',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF203F7D),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 14),

                          // INFORMAÇÕES DA AULA
                          const Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Programação',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF203F7D),
                                  ),
                                ),

                                SizedBox(width: 10),

                                Text(
                                  'T30 Informática',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),

                                SizedBox(width: 10),

                                Text(
                                  '8h - 9h30',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
