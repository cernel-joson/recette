// In lib/core/data/services/base_service.dart

import 'package:recette/core/data/repositories/data_repository.dart';

abstract class BaseService<T extends DataModel> {
  final DataRepository<T> repository;

  BaseService(this.repository);

  Future<List<T>> getAll() => repository.getAll();
  Future<T?> getById(int id) => repository.getById(id);
  Future<T> create(T item) => repository.create(item);
  Future<int> update(T item) => repository.update(item);
  Future<int> delete(int id) => repository.delete(id);
  Future<void> clear() => repository.clear();
  Future<void> batchInsert(List<T> items) => repository.batchInsert(items);
}