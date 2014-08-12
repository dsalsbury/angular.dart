library angular.test.tools.transformer.template_cache_generator_spec;

import 'package:angular/tools/transformer/options.dart';
import 'package:angular/tools/transformer/template_cache_generator.dart';
import 'package:code_transformers/resolver.dart';
import 'package:code_transformers/tests.dart' as tests;

import 'package:unittest/unittest.dart' hide expect;
import 'package:guinness/guinness.dart';

main() {
  describe('TemplateCacheGenerator', () {
    var options = new TransformOptions(
        sdkDirectory: dartSdkDirectory);

    var resolvers = new Resolvers(dartSdkDirectory);

    var phases = [
      [new TemplateCacheGenerator(options, resolvers)]
    ];

    it('should correctly generate the templates cache file (template)', () {
      return tests.applyTransformers(phases,
          inputs: {
            'angular|'
          })
    })
  });
}


String header = '''
// GENERATED, DO NOT EDIT!
library generated;

import 'package:angular/angular.dart';

primeTemplateCache(TemplateCache tc) {
''';

String footer = '''
}
''';