import 'package:math_expressions/math_expressions.dart';

class AppUtils {
  static String? tryCalculate(String input) {
    if (!input.contains(RegExp(r'[\+\-\*\/\^]'))) return null;

    try {
      Parser p = Parser();
      Expression exp = p.parse(input);
      double result = exp.evaluate(EvaluationType.REAL, ContextModel());

      return result % 1 == 0
          ? result.toInt().toString()
          : result.toStringAsFixed(2);
    } catch (e) {
      return null;
    }
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 23 || hour < 4) return "Staying up late?";
    if (hour < 12) return "Good Morning!";
    if (hour < 17) return "Good Afternoon!";
    return "Good Evening!";
  }
}
