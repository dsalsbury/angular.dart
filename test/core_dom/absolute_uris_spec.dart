library angular.test.core_dom.uri_resolver_spec;

import 'package:angular/core_dom/absolute_uris.dart';
import 'package:angular/core_dom/annotation_uri_resolver.dart';
import '../_specs.dart';

import 'dart:mirrors';

void main() {
  describe('url_resolver', () {
    var container;

    beforeEach(() {
      container = document.createElement('div');
      document.body.append(container);
    });

    afterEach(() {
      container.remove();
    });

    var originalBase = Uri.parse('package:angular/test/core_dom/absolute_uris_spec.dart');
    ResourceUrlResolver resourceResolver = new ResourceUrlResolver();

    testResolution(url, expected) {
      var baseUri = originalBase;
      it('resolves attribute URIs $url to $expected', () {
        var html = resourceResolver.resolveHtml("<img src='$url'>", baseUri);
        expect(html).toEqual('<img src="$expected">');
      });
    }

    testResolution('packages/angular/test/core_dom/foo.html', 'packages/angular/test/core_dom/foo.html');
    testResolution('foo.html', 'packages/angular/test/core_dom/foo.html');
    testResolution('./foo.html', 'packages/angular/test/core_dom/foo.html');
    testResolution('/foo.html', '/foo.html');
    testResolution('http://google.com/foo.html', 'http://google.com/foo.html');

    // Set originalBase to an http URL type instead of a 'package:' URL (because of
    // the way karma runs the tests) and ensure that after resolution, the result doesn't
    // have a protocol or domain but contains the full path
    var typeMirror = reflectType(NullSanitizer);
    LibraryMirror lib = typeMirror.owner;
    var originalBase2 = lib.uri;

    testResolution('packages/angular/test/core_dom/foo.html', 'packages/angular/test/core_dom/foo.html');
    testResolution('foo.html', 'packages/angular/test/core_dom/foo.html');
    testResolution('./foo.html', 'packages/angular/test/core_dom/foo.html');
    testResolution('/foo.html', '/foo.html');
    testResolution('http://google.com/foo.html', 'http://google.com/foo.html');


    testTemplateResolution(url, expected) {
      expect(resourceResolver.resolveHtml('''
        <template>
          <img src="$url">
        </template>''', originalBase)).toEqual('''
        <template>
          <img src="$expected">
        </template>''');
    }

    it('resolves template contents', () {
        testTemplateResolution('foo.png', 'packages/angular/test/core_dom/foo.png');
    });

    it('does not change absolute urls when they are resolved', () {
      testTemplateResolution('/foo/foo.png', '/foo/foo.png');
    });

    it('resolves CSS URIs', () {
      var html_style = ('''
        <style>
          body {
            background-image: url(foo.png);
          }
        </style>''');

      html_style = resourceResolver.resolveHtml(html_style, originalBase).toString();

      var resolved_style = ('''
        <style>
          body {
            background-image: url('packages/angular/test/core_dom/foo.png');
          }
        </style>''');
      expect(html_style).toEqual(resolved_style);
    });

    it('resolves @import URIs', () {
      var html_style = ('''
        <style>
          @import url("foo.css");
          @import 'bar.css';
        </style>''');

      html_style = resourceResolver.resolveHtml(html_style, originalBase).toString();

      var resolved_style = ('''
        <style>
          @import url('packages/angular/test/core_dom/foo.css');
          @import 'packages/angular/test/core_dom/bar.css';
        </style>''');
      expect(html_style).toEqual(resolved_style);
    });
  });
}

class NullSanitizer implements NodeValidator {
  bool allowsElement(Element element) => true;
  bool allowsAttribute(Element element, String attributeName, String value) =>
      true;
}