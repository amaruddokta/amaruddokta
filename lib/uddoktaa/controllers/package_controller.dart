import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/package_model.dart';

class PackageController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Observable list of packages
  var packages = <Package>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPackages();
  }

  void fetchPackages() {
    _supabase
        .from('userPackages')
        .stream(primaryKey: ['id'])
        .execute()
        .listen((data) {
          final loadedPackages = data.map((map) {
            return Package.fromJson(map);
          }).toList();

          packages.assignAll(loadedPackages);
        });
  }
}
