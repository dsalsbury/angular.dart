library angular.core_dom.type_to_uri_mapper;

import 'package:path/path.dart' as native_path;

final _path = native_path.url;

/// Utility to convert type-relative URIs to be page-relative.
abstract class TypeToUriMapper {
  final ResourceResolverConfig _resourceResolverConfig;
  final String baseUri = Uri.base.toString();
  
  TypeToUriMapper(this._resourceResolverConfig);
  
  static final RegExp _libraryRegExp = new RegExp(r'/packages/');
  
  // to be rewritten for dynamic and static cases
  Uri uriForType(Type type);
  
  String combineWithType(Type type, String uri) {
    return combine(uriForType(type), uri);
  }

  /// Combines a type-based URI with a relative URI.
  ///
  /// [typeUri] is assumed to use package: syntax for package-relative
  /// URIs, while [uri] is assumed to use 'packages/' syntax for
  /// package-relative URIs. Resulting URIs will use 'packages/' to indicate
  /// package-relative URIs.
  String combine(Uri typeUri, String uri) {
    if (!_resourceResolverConfig.useRelativeUrls) {
      return uri;
    }
    
    if (uri == null) {
      uri = typeUri.path;
    } else {
      // if it's absolute but not package-relative, then just use that
      if (uri.startsWith("/") || uri.startsWith('packages/')) {
        return uri;
      }
    }
    // If it's not absolute, then resolve it first
    Uri resolved = typeUri.resolve(uri);

    // If it's package-relative, tack on 'packages/' - Note that eventually
    // we may want to change this to be '/packages/' to make it truly absolute
    if (resolved.scheme == 'package') {
      return 'packages/${resolved.path}';
    } else if (typeUri.isAbsolute && typeUri.toString().startsWith(baseUri)) {
      return typeUri.path;
    } else {
      return resolved.toString();
    }
  }
}

class ResourceResolverConfig {
  bool useRelativeUrls;
  
  ResourceResolverConfig({this.useRelativeUrls});
}