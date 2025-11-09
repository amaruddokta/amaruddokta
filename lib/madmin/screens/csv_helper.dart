import 'package:csv/csv.dart';

class CsvHelper {
  static String convertToCsv(List<List<dynamic>> rows) {
    return const ListToCsvConverter().convert(rows);
  }

  static List<List<dynamic>> convertFromCsv(String csvString) {
    return const CsvToListConverter().convert(csvString);
  }
}
