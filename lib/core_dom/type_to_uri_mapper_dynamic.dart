library angular.core_dom.type_to_uri_mapper_dynamic;

import 'dart:html' as dom;
import 'dart:mirrors';

import 'type_to_uri_mapper.dart';

/// Resolves type-relative URIs
class DynamicTypeToUriMapper extends TypeToUriMapper {
  Uri uriForType(Type type) {
    var typeMirror = reflectType(type);
    LibraryMirror lib = typeMirror.owner;
    print("ckck: $runtimeType: $type → ${lib.uri}");
    return lib.uri;
  }
}
