library angular.tools.transformer.template_cache_generator;

import 'dart:io';
import 'dart:async';

import 'package:analyzer/src/generated/ast.dart';
import 'package:angular/tools/transformer/options.dart';
import 'package:code_transformers/resolver.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

const String PACKAGE_PREFIX = 'package:';
const String DART_PACKAGE_PREFIX = 'dart:';

String fileHeader(String library) => '''// GENERATED, DO NOT EDIT!
library ${library};

import 'package:angular/angular.dart';

primeTemplateCache(TemplateCache tc) {
''';

const String FILE_FOOTER = '}';

class TemplateCacheGenerator extends Transformer with ResolverTransformer {
  final TransformOptions options;

  String entryPoint;
  String sdkPath;
  List<String> templateRoots;
  String output;
  String outputLibrary;
  Map<RegExp, String> urlRewriters;
  Set<String> skippedClasses;
  String cssRewriter;

  TemplateCacheGenerator(this.options, Resolvers resolvers){
    resolvers = resolvers;
    sdkPath = options.sdkDirectory;
    options.entryPoint == null ?
        entryPoint = options.entryPoint :
        entryPoint = 'web/main.dart';
    options.templateRoots == null ?
        templateRoots = options.templateRoots :
        templateRoots = ['.'];
    if (options.templateUriRewrites != null) {
      urlRewriters = new Map<RegExp, String>();
      options.templateUriRewrites.forEach((patternUrl, rewriteTo) {
        urlRewriters.putIfAbsent(new RegExp(patternUrl),
            () => rewriteTo);
      });
    }
    else {
      urlRewriters = {};
    }
    skippedClasses = options.skippedTemplateCacheClasses;
    cssRewriter = options.cssRewriter;


    //TODO: do these need to be options to be set from pubspec?
    this.output = 'web/generated.dart';
    this.outputLibrary = 'generated';

  }

  void applyResolver(Transform transform, Resolver resolver) {
    var asset = transform.primaryInput;
    var id = asset.id;
    var outputPath = path.url.join(path.url.dirname(this.outputLibrary),
        this.output);
    var outputId = new AssetId(id.package, outputPath);

    String template_cache = generateTemplateCache(resolver);

    transform.addOutput(new Asset.fromString(outputId, template_cache));
  }

  String generateTemplateCache(Resolver resolver) {
    Map<String, String> templates = {};
    resolver.libraries
            .expand((lib) => lib.units)
            .map((cue) => cue.node)
            .expand((cu) => cu.declarations)
            .where((declaration) => declaration is ClassDeclaration)
            .forEach((clazz) => _getTemplateCache(clazz, templates));
    return printTemplateCache(templates);
  }

  void _getTemplateCache(ClassDeclaration clazz, Map<String, String> templates) {
    List<String> cacheUris = [];
    bool cache = true;
    clazz.metadata.forEach((Annotation ann) {
      if (ann.arguments == null) return; // Ignore non-class annotations.
      if (skippedClasses.contains(clazz.name.name)) return;

      switch (ann.name.name) {
        case 'Component':
            extractComponentMetadata(ann, cacheUris); break;
        case 'NgTemplateCache':
            cache = extractNgTemplateCache(ann, cacheUris); break;
      }
    });
    if (cache && cacheUris.isNotEmpty) {
      cacheUris..sort()..forEach(
          (uri) => storeUriAsset(uri, templateRoots, templates));
    }
  }

  String printTemplateCache(Map<String, String> templateKeyMap) {
    String cache = fileHeader(outputLibrary);

    Future future = new Future.value(0);
    List uris = templateKeyMap.keys.toList()..sort()..forEach((uri) {
      var templateFile = templateKeyMap[uri];
      future = future.then((_) {
        return new File(templateFile).readAsString().then((fileStr) {
          fileStr = fileStr.replaceAll('"""', r'\"\"\"');
          String resultUri = uri;
          urlRewriters.forEach((regexp, replacement) {
            resultUri = resultUri.replaceFirst(regexp, replacement);
          });
          cache += 'tc.put("$resultUri", new HttpResponse(200, r"""$fileStr"""));\n';
        });
      });
    });

    // Wait until all templates files are processed.
    future.then((_) {
      cache += FILE_FOOTER;
    });

    return cache;
  }

  void extractComponentMetadata(Annotation ann, List<String> cacheUris) {
    ann.arguments.arguments.forEach((Expression arg) {
      if (arg is NamedExpression) {
        NamedExpression namedArg = arg;
        var paramName = namedArg.name.label.name;
        if (paramName == 'templateUrl') {
          cacheUris.add(assertString(namedArg.expression).stringValue);
        } else if (paramName == 'cssUrl') {
          if (namedArg.expression is StringLiteral) {
            cacheUris.add(assertString(namedArg.expression).stringValue);
          } else {
            cacheUris.addAll(assertList(namedArg.expression).elements.map((e) =>
                assertString(e).stringValue));
          }
        }
      }
    });
  }

  bool extractNgTemplateCache(Annotation ann, List<String> cacheUris) {
    bool cache = true;
    ann.arguments.arguments.forEach((Expression arg) {
      if (arg is NamedExpression) {
        NamedExpression namedArg = arg;
        var paramName = namedArg.name.label.name;
        if (paramName == 'preCacheUrls') {
          assertList(namedArg.expression).elements
            ..forEach((expression) =>
                cacheUris.add(assertString(expression).stringValue));
        }
        if (paramName == 'cache') {
          cache = assertBoolean(namedArg.expression).value;
        }
      }
    });
    return cache;
  }

  void storeUriAsset(String uri, templateRoots, Map<String, String> templates) {
    String assetFileLocation = findAssetLocation(uri, templateRoots);
    if (assetFileLocation == null) {
      print("Could not find asset for uri: $uri");
    } else {
      templates[uri] = assetFileLocation;
    }
  }

  String findAssetLocation(String uri, List<String>
      templateRoots) {
    if (uri.startsWith('/')) {
      var paths = templateRoots.map((r) => '$r/$uri');
      return paths.firstWhere((p) => new File(p).existsSync(),
          orElse: () => paths.first);
    }
    // Otherwise let the sourceFactory resolve for packages, and relative paths.
    return Uri.base.resolve(uri).toString();
//    Source source = sourceCrawler.context.sourceFactory
//        .resolveUri(srcPath, uri);
//    return (source != null) ? source.fullName : null;
  }


  BooleanLiteral assertBoolean(Expression key) {
    if (key is! BooleanLiteral) {
        throw 'must be a boolean literal: ${key.runtimeType}';
    }
    return key;
  }

  ListLiteral assertList(Expression key) {
    if (key is! ListLiteral) {
        throw 'must be a list literal: ${key.runtimeType}';
    }
    return key;
  }

  StringLiteral assertString(Expression key) {
    if (key is! StringLiteral) {
        throw 'must be a string literal: ${key.runtimeType}';
    }
    return key;
  }
}
