import 'dart:async';

class StatefulStream<T> extends Stream<T> {
  StatefulStream(this._stream);

  final Stream<T> _stream;
  bool isListened = false;

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    isListened = true;

    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
