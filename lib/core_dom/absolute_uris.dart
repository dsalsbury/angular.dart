/**
 * Dart port of
 * https://github.com/Polymer/platform-dev/blob/896e245a0046a397bfc0190d958d2bd162e8f53c/src/url.js
 *
 * This converts URIs within a document from relative URIs to being absolute
 * URIs.
 */

library angular.core_dom.absolute_uris;

import 'dart:html';
import 'dart:js' as js;

import 'package:angular/core_dom/annotation_uri_resolver.dart';


String resolveHtml(String html, [Uri baseUrl]) {
  if (baseUrl == null) {
    return html;
  }
  HtmlDocument document = new DomParser().parseFromString(
      "<!doctype html><html><body>$html</body></html>", "text/html");
  _resolveDom(document.body, baseUrl);
  return document.body.innerHtml;
}

/**
 * Resolves all relative URIs within the DOM from being relative to
 * [originalBase] to being absolute.
 */
void _resolveDom(Node root, [Uri originalBase]) {
  if (originalBase == null) {
    originalBase = Uri.base;
  }

  _resolveAttributes(root, originalBase);
  _resolveStyles(root, originalBase);

  // handle template.content
  for (var template in _querySelectorAll(root, 'template')) {
    if (template.content != null) {
      _resolveDom(template.content, originalBase);
    }
  }
} 

Iterable<Element> _querySelectorAll(Node node, String selectors) {
  if (node is DocumentFragment) {
    return node.querySelectorAll(selectors);
  }
  if (node is Element) {
    return node.querySelectorAll(selectors);
  }
  return const [];
}

void _resolveStyles(Node node, Uri originalBase) {
  var styles = _querySelectorAll(node, 'style');
  for (var style in styles) {
    _resolveStyle(style, originalBase);
  }
}

void _resolveStyle(StyleElement style, Uri originalBase) {
  style.text = resolveCssText(style.text, originalBase);
}

String resolveCssText(String cssText, Uri originalBase) {
  cssText = _replaceUrlsInCssText(cssText, originalBase, _cssUrlRegexp);
  return _replaceUrlsInCssText(cssText, originalBase, _cssImportRegexp);
}

void _resolveAttributes(Node root, Uri originalBase) {
  if (root is Element) {
    _resolveElementAttributes(root, originalBase);
  }

  for (var node in _querySelectorAll(root, _urlAttrsSelector)) {
    _resolveElementAttributes(node, originalBase);
  }
}

void _resolveElementAttributes(Element element, Uri originalBase) {
  var attrs = element.attributes;
  for (var attr in _urlAttrs) {
    if (attrs.containsKey(attr)) {
      var value = attrs[attr];
      if (!value.contains(_urlTemplateSearch)) {
        attrs[attr] = AnnotationUriResolver.combine(originalBase, value).toString();
      }
    }
  }
}

final RegExp _cssUrlRegexp = new RegExp(r'(\burl\()([^)]*)(\))');
final RegExp _cssImportRegexp = new RegExp(r'(@import[\s]+(?!url\())([^;]*)(;)');
const List<String> _urlAttrs = const ['href', 'src', 'action'];
final String _urlAttrsSelector = '[${_urlAttrs.join('],[')}]';
final RegExp _urlTemplateSearch = new RegExp('{{.*}}');
final RegExp _quotes = new RegExp('["\']');

String _replaceUrlsInCssText(String cssText, Uri originalBase, RegExp regexp) {
  return cssText.replaceAllMapped(regexp, (match) {
    var url = match[2];
    url = url.replaceAll(_quotes, '');
    var urlPath = AnnotationUriResolver.combine(originalBase, url).toString();
    return '${match[1]}\'$urlPath\'${match[3]}';
  });
}
