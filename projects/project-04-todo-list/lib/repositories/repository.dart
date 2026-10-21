abstract class Repository<T> {
  Future<List<T>> getAll();
  Future<T> getById(int id);
  Future<T> add(T t);
  Future<T> update(T t);
  Future<void> delete(int id);
}
