# gestor_cafeteria

Aplicación Flutter para gestionar los pedidos de una cafetería. Por ahora incluye la capa de red: `ApiClient` consume el servidor de pedidos y convierte cada respuesta de error en un `Failure` concreto (`NotFoundFailure`, `ConflictFailure`, `ValidationFailure`, `ServerFailure`, `NetworkFailure` o `UnexpectedFailure`) para que la app sepa qué le pasó a la petición. Las pruebas usan un cliente falso y no necesitan servidor.

## Requisitos

- Flutter estable (probado con 3.47.2).
- Node.js 22.13 o superior (`node --version`), solo para el servidor.
- Chrome, un emulador de Android o un celular para correr la app.

## Servidor de pedidos (mini_backend)

El servidor es **otro repositorio** y no está copiado aquí: <https://github.com/DMI-2026/mini_backend> (rama `master`). Lo probé con el commit `94d2533`.

```bash
git clone https://github.com/DMI-2026/mini_backend.git
cd mini_backend
node server.js
```

No hace falta `npm install`. Debe imprimir `Listening on http://0.0.0.0:8000` y <http://localhost:8000/health> responde `{"status":"ok"}`.

## Correr la app

```bash
flutter pub get
flutter run -d chrome
```

En Chrome usa `http://localhost:8000` y en el emulador de Android `http://10.0.2.2:8000`. Si el servidor está en otra dirección (por ejemplo, un celular conectado a la misma red), se indica con `API_URL`:

```bash
flutter run --dart-define=API_URL=http://<IP de la computadora>:8000
```

## Pruebas

```bash
flutter analyze
flutter test
```

`flutter test` no necesita el servidor porque usa `MockClient`.

## Estructura

```
lib/core/failure.dart       clase sellada Failure y sus subtipos
lib/core/http_client.dart   ApiClient (GET, POST, PATCH, DELETE) y mapeo de errores
lib/main.dart               pantalla de prueba con la lista de pedidos
test/core/                  pruebas de Failure y de ApiClient
```
