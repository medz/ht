Never throwHttpBodyUsedError() {
  throw StateError('The body has already been read');
}
