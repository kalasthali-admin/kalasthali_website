import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'app.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);
  runApp(
    Document(
      title: 'Kalasthali By Nisha',
      lang: 'en',
      head: [
        link(rel: 'stylesheet', href: '/public.css'),
        link(rel: 'icon', href: '/favicon.ico'),
        link(rel: 'apple-touch-icon', href: '/apple-touch-icon.png'),
        script(src: '/public-config.js', defer: true),
        script(src: '/public.js', defer: true),
      ],
      body: const App(),
    ),
  );
}
