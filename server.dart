import 'dart:io';
import 'dart:async';

void main(List<String> args) async {
  // Configuration
  final port = int.tryParse(args.isNotEmpty ? args[0] : '8080') ?? 8080;
  final buildDir = args.length > 1 ? args[1] : 'build/web';
  final host = args.length > 2 ? args[2] : 'localhost';

  final directory = Directory(buildDir);

  if (!await directory.exists()) {
    print('Error: Build directory "$buildDir" does not exist.');
    print('Please build your Flutter web project first:');
    print('  flutter build web --dart-define=flavor=dev --release --wasm --source-maps');
    exit(1);
  }

  // Start the HTTP server
  final server = await HttpServer.bind(host, port);
  print('Static file server running on http://$host:$port');
  print('Serving files from: ${directory.absolute.path}');
  print('Press Ctrl+C to stop the server');

  await for (HttpRequest request in server) {
    await handleRequest(request, buildDir);
  }
}

Future<void> handleRequest(HttpRequest request, String buildDir) async {
  try {
    final uri = request.uri;
    var path = uri.path;

    // Remove leading slash
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // If path is empty or ends with /, serve index.html
    if (path.isEmpty || path.endsWith('/')) {
      path = '${path}index.html';
    }

    final file = File('$buildDir/$path');

    // Check if file exists
    if (await file.exists()) {
      // Get file stats
      final stat = await file.stat();

      if (stat.type == FileSystemEntityType.file) {
        // Set content type based on file extension
        final contentType = getContentType(path);
        request.response.headers.contentType = contentType;

        // Add caching headers for static assets
        if (isCacheableAsset(path)) {
          request.response.headers.add('Cache-Control', 'public, max-age=31536000');
        } else {
          request.response.headers.add('Cache-Control', 'no-cache');
        }

        // Enable CORS for development
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type');

        // Stream file to response
        await file.openRead().pipe(request.response);

        print('${request.method} ${uri.path} - 200 OK');
        return;
      }
    }

    // If file not found, try serving index.html (for SPA routing)
    final indexFile = File('$buildDir/index.html');
    if (await indexFile.exists()) {
      request.response.headers.contentType = ContentType.html;
      request.response.headers.add('Cache-Control', 'no-cache');
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      await indexFile.openRead().pipe(request.response);
      print('${request.method} ${uri.path} - 200 OK (index.html)');
      return;
    }

    // 404 Not Found
    request.response.statusCode = HttpStatus.notFound;
    request.response.write('404 Not Found');
    await request.response.close();
    print('${request.method} ${uri.path} - 404 Not Found');
  } catch (e) {
    print('Error handling request: $e');
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.write('500 Internal Server Error');
    await request.response.close();
  }
}

ContentType getContentType(String path) {
  final ext = path.split('.').last.toLowerCase();

  switch (ext) {
    // HTML
    case 'html':
    case 'htm':
      return ContentType.html;

    // JavaScript
    case 'js':
    case 'mjs':
      return ContentType('application', 'javascript', charset: 'utf-8');

    // CSS
    case 'css':
      return ContentType('text', 'css', charset: 'utf-8');

    // JSON
    case 'json':
      return ContentType.json;

    // Images
    case 'png':
      return ContentType('image', 'png');
    case 'jpg':
    case 'jpeg':
      return ContentType('image', 'jpeg');
    case 'gif':
      return ContentType('image', 'gif');
    case 'svg':
      return ContentType('image', 'svg+xml');
    case 'ico':
      return ContentType('image', 'x-icon');
    case 'webp':
      return ContentType('image', 'webp');

    // Fonts
    case 'woff':
      return ContentType('font', 'woff');
    case 'woff2':
      return ContentType('font', 'woff2');
    case 'ttf':
      return ContentType('font', 'ttf');
    case 'otf':
      return ContentType('font', 'otf');

    // WebAssembly
    case 'wasm':
      return ContentType('application', 'wasm');

    // Source maps
    case 'map':
      return ContentType('application', 'json', charset: 'utf-8');

    // Text
    case 'txt':
      return ContentType.text;

    // XML
    case 'xml':
      return ContentType('application', 'xml', charset: 'utf-8');

    // Default
    default:
      return ContentType.binary;
  }
}

bool isCacheableAsset(String path) {
  final ext = path.split('.').last.toLowerCase();
  // Cache versioned assets and static resources
  return [
    'js',
    'css',
    'woff',
    'woff2',
    'ttf',
    'otf',
    'png',
    'jpg',
    'jpeg',
    'gif',
    'svg',
    'ico',
    'webp',
    'wasm',
  ].contains(ext);
}
