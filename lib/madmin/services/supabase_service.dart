import 'package:supabase_flutter/supabase_flutter.dart'
    hide User; // Hide Supabase's User to avoid conflict
import 'package:amar_uddokta/madmin/models/category_model.dart';
import 'package:amar_uddokta/madmin/models/order_model.dart';
import 'package:amar_uddokta/uddoktaa/models/user.dart'
    as AppUser; // Alias our User model

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient client;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() {
    // Initialize Supabase client. Replace with your actual Supabase URL and Anon Key.
    // These should ideally be loaded from environment variables or a config file.
    client = Supabase.instance.client;
  }

  Stream<List<ProductCategory>> getCategories() {
    return client.from('categories').stream(primaryKey: ['id']).map((data) =>
        data
            .map((category) => ProductCategory.fromSupabase(category))
            .toList());
  }

  Future<void> deleteCategory(String id) async {
    await client.from('categories').delete().eq('id', id);
  }

  Future<void> addCategory(ProductCategory category) async {
    await client.from('categories').insert(category.toSupabaseJson());
  }

  Future<void> updateCategory(ProductCategory category) async {
    await client
        .from('categories')
        .update(category.toSupabaseJson())
        .eq('id', category.id);
  }

  // OrderModel operations
  Stream<List<OrderModel>> getOrders() {
    return client.from('orders').stream(primaryKey: ['order_id']).map(
        (data) => data.map((order) => OrderModel.fromSupabase(order)).toList());
  }

  Future<void> deleteOrder(String orderId) async {
    await client.from('orders').delete().eq('order_id', orderId);
  }

  Future<void> addOrder(OrderModel order) async {
    await client.from('orders').insert(order.toSupabaseJson());
  }

  Future<void> updateOrder(OrderModel order) async {
    await client
        .from('orders')
        .update(order.toSupabaseJson())
        .eq('order_id', order.orderId);
  }

  // User operations
  Stream<List<AppUser.User>> getUsers() {
    return client.from('users').stream(primaryKey: ['id']).map(
        (data) => data.map((user) => AppUser.User.fromSupabase(user)).toList());
  }

  Future<void> deleteUser(String id) async {
    await client.from('users').delete().eq('id', id);
  }

  Future<void> addUser(AppUser.User user) async {
    await client.from('users').insert(user.toSupabaseJson());
  }

  Future<void> updateUser(AppUser.User user) async {
    await client.from('users').update(user.toSupabaseJson()).eq('id', user.id);
  }
}
