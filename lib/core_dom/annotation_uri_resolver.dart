library angular.core_dom.annotation_uri_resolver;

import 'package:path/path.dart' as native_path;

final _path = native_path.url;

/// Utility to convert type-relative URIs to be page-relative.
abstract class AnnotationUriResolver {
  String resolve(String uri, Type type);
  
  static final RegExp _libraryRegExp = new RegExp(r'/packages/');

  /// Combines a type-based URI with a relative URI.
  ///
  /// [typeUri] is assumed to use package: syntax for package-relative
  /// URIs, while [uri] is assumed to use 'packages/' syntax for
  /// package-relative URIs. Resulting URIs will use 'packages/' to indicate
  /// package-relative URIs.
  static String combine(Uri typeUri, String uri) {   
    var resolved;
    
    if (uri == null) {
      uri = typeUri.path;
    } else {
      // if it's absolute but not package-relative, then just use that
      if (uri.startsWith("/") || uri.startsWith('packages/')) {
        return uri;
      }
    }
    // If it's not absolute, then resolve it first
    resolved = typeUri.resolve(uri);
    
    // If it's package-relative, tack on 'packages/' - Note that eventually
    // we may want to change this to be '/packages/' to make it truly absolute
    if (resolved.scheme == 'package') {
      return 'packages/${resolved.path}';
    } else {
      // TODO(chirayu): This is an absolute path.  Either we should make this a
      // path relative to the baseUrl here, or we should enhance template cache
      // to support both absolute and relative URLs.
      return resolved.toString();
    }
  }
}
