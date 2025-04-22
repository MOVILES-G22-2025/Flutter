import 'package:hive/hive.dart';

import 'models/operation.dart';

class OperationQueue {
  final _box = Hive.box<Operation>('operation_queue');

  Future<void> enqueue(Operation op) async => _box.put(op.id, op);

  List<Operation> pending() => _box.values.toList();

  Future<void> remove(String id) async => _box.delete(id);
}