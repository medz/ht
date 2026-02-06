# ht

`ht` 是 **HTTP Types** 的缩写，提供一套以 Fetch 风格为中心的 Dart HTTP 抽象类型。

这个包只做“类型与语义层”，不做具体网络请求发送或服务器运行时实现。

## 特性

- Fetch 风格基础类型：`Request`、`Response`、`Headers`、`URLSearchParams`、`Blob`、`File`、`FormData`
- 协议辅助类型：`HttpMethod`、`HttpStatus`、`HttpVersion`、`MimeType`
- 统一 body 读取语义（一次消费）、克隆语义、header 归一化语义
- 可作为上层 client / server 框架的共享类型层

## 安装

```bash
dart pub add ht
```

或在 `pubspec.yaml` 中手动添加：

```yaml
dependencies:
  ht: ^0.0.0
```

## 设计边界

- 本包不提供 HTTP client
- 本包不提供 HTTP server
- 本包不内置路由/中间件框架

目标是让下游实现复用一致的 HTTP 类型与行为约束。

## 核心 API

| 分类 | 类型 |
| --- | --- |
| 协议 | `HttpMethod`, `HttpStatus`, `HttpVersion`, `MimeType` |
| 消息 | `Request`, `Response`, `BodyMixin`, `BodyInit` |
| Header/URL | `Headers`, `URLSearchParams` |
| 二进制与表单 | `Blob`, `File`, `FormData` |

## 快速示例

```dart
import 'package:ht/ht.dart';

Future<void> main() async {
  final request = Request.json(
    Uri.parse('https://api.example.com/tasks'),
    method: HttpMethod.post.value,
    body: {'title': 'rewrite ht'},
  );

  final response = Response.json(
    {'ok': true},
    status: HttpStatus.created,
  );

  print(request.method); // POST
  print(request.headers.get('content-type')); // application/json; charset=utf-8
  print(await response.text());
}
```

## Body 语义

`Request` / `Response` 的 body 采用一次消费模型：

- 首次调用 `text()` / `bytes()` / `json()` / `blob()` 或读取 `body` 流后，`bodyUsed == true`
- 再次读取同一实例会抛出 `StateError`
- 如需重复读取，先 `clone()`

## FormData 示例

```dart
import 'package:ht/ht.dart';

void main() {
  final form = FormData()
    ..append('name', 'alice')
    ..append('avatar', Blob.text('binary'), filename: 'avatar.txt');

  final multipart = form.encodeMultipart();

  print(multipart.contentType);   // multipart/form-data; boundary=...
  print(multipart.contentLength); // body bytes length
}
```

## 开发

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart run example/main.dart
```

## License

[MIT](./LICENSE)
