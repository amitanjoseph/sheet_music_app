extension ListGet<T> on List<T> {
  T? get(int index) => index < 0 || index >= length ? null : this[index];
}
