import 'dart:async';
import 'dart:ui';

class Debouncer {

  Debouncer({required this.milliseconds});
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  void run(VoidCallback action) {
    // Si un Timer existe déjà, on l'annule
    _timer?.cancel();

    // On crée un nouveau Timer qui exécute l'action après 300 ms
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}


List<DateTime> generateDates(int year) {
  return List.generate(12, (index) => DateTime(year, index + 1));
}