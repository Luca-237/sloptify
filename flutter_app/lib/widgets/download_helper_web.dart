// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Dispara una descarga directa en el navegador sin abrir una nueva pestaña.
/// Crea un <a> invisible con el atributo download y lo clickea programáticamente.
void triggerBrowserDownload(String url, String filename) {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
}
