import 'dart:async';

class ClonableStream<T> extends Stream<T> {
  ClonableStream(Stream<T> stream)
      : _stream = stream is ClonableStream<T> ? stream._stream : stream;

  Stream<T> _stream;

  @override
  bool get isBroadcast => _stream.isBroadcast;

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Stream<T> clone() {
    if (_stream.isBroadcast) {
      return this;
    }

    final stream = this._stream;

    final c1 = StreamController<T>();
    final c2 = StreamController<T>();

    // Reset upstream.
    _stream = c1.stream;

    final subscription = stream.listen((event) {
      if (!c1.isClosed) {
        c1.add(event);
      }

      if (!c2.isClosed) {
        c2.add(event);
      }
    });

    c1.onCancel = c2.onCancel = () {
      if (c1.isClosed && c2.isClosed) {
        subscription.cancel();
      }
    };

    subscription.onDone(() {
      c1.close();
      c2.close();
    });

    subscription.onError((e, s) {
      c1.addError(e, s);
      c2.addError(e, s);
    });

    return c2.stream;
  }
}
