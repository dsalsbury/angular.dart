library templateurl_spec;

import 'dart:html' as dom;
import '../_specs.dart';

@Component(
    selector: 'simple-url',
    templateUrl: 'simple.html')
class SimpleUrlComponent {
}

@Component(
  selector: 'dot-slash-url',
  templateUrl: './simple.html')
class DotSlashUrlComponent{
}

@Component(
  selector: 'absolute-url',
  templateUrl: '/simple.html')
class AbsoluteUrlComponent{
}

@Component(
  selector: 'http-url',
  templateUrl: 'http://www/simple.html')
class HttpUrlComponent{
}

@Component(
    selector: 'html-and-css',
    templateUrl: 'simple.html',
    cssUrl: 'simple.css')
class HtmlAndCssComponent {
}

@Component(
    selector: 'html-and-multi-css',
    templateUrl: 'simple.html',
    cssUrl: const ['simple.css', 'another.css'])
class HtmlAndMultipleCssComponent {
}

@Component(
    selector: 'inline-with-css',
    template: '<div>inline!</div>',
    cssUrl: 'simple.css')
class InlineWithCssComponent {
}

@Component(
    selector: 'only-css',
    cssUrl: 'simple.css')
class OnlyCssComponent {
}

class PrefixedUrlRewriter extends UrlRewriter {
  call(url) => "PREFIX:$url";
}

void main() {
  describe('template url', () {
    afterEach((MockHttpBackend backend) {
      backend.verifyNoOutstandingExpectation();
      backend.verifyNoOutstandingRequest();
    });

    describe('loading with http rewriting', () {
      beforeEachModule((Module module) {
        module
            ..bind(HtmlAndCssComponent)
            ..bind(UrlRewriter, toImplementation: PrefixedUrlRewriter)
            ..bind(ResourceResolverConfig, toValue: new ResourceResolverConfig(useRelativeUrls: true));
      });

      it('should use the UrlRewriter for both HTML and CSS URLs', async(
          (Http http, Compiler compile, Scope rootScope, Logger log,
           Injector injector, VmTurnZone zone, MockHttpBackend backend,
           DirectiveMap directives) {

        backend
            ..whenGET('PREFIX:base/test/core/simple.html').respond('<div log="SIMPLE">Simple!</div>')
            ..whenGET('PREFIX:base/test/core/simple.css').respond('.hello{}');

        var element = e('<div><html-and-css log>ignore</html-and-css><div>');
        zone.run(() {
          compile([element], directives)(rootScope, injector.get(DirectiveInjector), [element]);
        });

        backend.flush();
        microLeap();

        expect(element).toHaveText('.hello{}Simple!');
        expect(element.children[0].shadowRoot).toHaveHtml(
            '<style>.hello{}</style><div log="SIMPLE">Simple!</div>'
        );
      }));
    });


    describe('async template loading', () {
      beforeEachModule((Module module) {
        module
            ..bind(LogAttrDirective)
            ..bind(SimpleUrlComponent)
            ..bind(DotSlashUrlComponent)
            ..bind(AbsoluteUrlComponent)
            ..bind(HttpUrlComponent)
            ..bind(HtmlAndCssComponent)
            ..bind(OnlyCssComponent)
            ..bind(InlineWithCssComponent)
            ..bind(ResourceResolverConfig, toValue: new ResourceResolverConfig(useRelativeUrls: true));
      });

      testResolution(description, expected, component) {
        it('should replace element with template from url $description', async(inject(
            (Http http, Compiler compile, Scope rootScope,  Logger log,
             Injector injector, MockHttpBackend backend, DirectiveMap directives) {
          backend.expectGET(expected).respond(200, '<div log="SIMPLE">Simple!</div>');

          var element = es('<div><$component log>ignore</$component><div>');
          compile(element, directives)(rootScope, injector.get(DirectiveInjector), element);

          microLeap();
          backend.flush();
          microLeap();

          expect(element[0]).toHaveText('Simple!');
          rootScope.apply();
          // Note: There is no ordering.  It is who ever comes off the wire first!
          expect(log.result()).toEqual('LOG; SIMPLE');
        })));
      }

      testResolution('simple relative url', 'base/test/core/simple.html', 'simple-url');
      testResolution('./relative url', 'base/test/core/simple.html', 'dot-slash-url');
      testResolution('absolute url', '/simple.html', 'absolute-url');
      testResolution('http url', 'http://www/simple.html', 'http-url');

      it('should load template from URL once', async(inject(
          (Http http, Compiler compile, Scope rootScope,  Logger log,
           Injector injector, MockHttpBackend backend, DirectiveMap directives) {
        backend.whenGET('base/test/core/simple.html').respond(200, '<div log="SIMPLE">Simple!</div>');

        var element = es(
            '<div>'
            '<simple-url log>ignore</simple-url>'
            '<simple-url log>ignore</simple-url>'
            '<div>');
        compile(element, directives)(rootScope, injector.get(DirectiveInjector), element);

        microLeap();
        backend.flush();
        microLeap();

        expect(element[0]).toHaveText('Simple!Simple!');
        rootScope.apply();

        // Note: There is no ordering.  It is who ever comes off the wire first!
        expect(log.result()).toEqual('LOG; LOG; SIMPLE; SIMPLE');
      })));

      it('should use template-relative URIs', async(inject(
          (Http http, Compiler compile, Scope rootScope,  Logger log,
           Injector injector, MockHttpBackend backend, DirectiveMap directives) {
        backend.expectGET("base/test/core/simple.html").respond(200, '<div><img src="foo.png"/></div>');

        var element = es('<div><simple-url log>ignore</simple-url><div>');
        compile(element, directives)(rootScope, injector.get(DirectiveInjector), element);

        microLeap();
        backend.flush();
        microLeap();

        var img = element[0].children[0].shadowRoot.querySelector('img');
        print("img=" + img.src);
        expect(img.src).toEqual(Uri.base.resolve('base/test/core/foo.png').toString());
      })));

      it('should load a CSS file into a style', async(
          (Http http, Compiler compile, Scope rootScope, Logger log,
           Injector injector, MockHttpBackend backend, DirectiveMap directives) {
        backend
            ..expectGET('base/test/core/simple.css').respond(200, '.hello{}')
            ..expectGET('base/test/core/simple.html').respond(200, '<div log="SIMPLE">Simple!</div>');

        var element = e('<div><html-and-css log>ignore</html-and-css><div>');
        compile([element], directives)(rootScope, injector.get(DirectiveInjector), [element]);

        microLeap();
        backend.flush();
        microLeap();

        expect(element).toHaveText('.hello{}Simple!');
        expect(element.children[0].shadowRoot).toHaveHtml(
            '<style>.hello{}</style><div log="SIMPLE">Simple!</div>'
        );
        rootScope.apply();
        // Note: There is no ordering.  It is who ever comes off the wire first!
        expect(log.result()).toEqual('LOG; SIMPLE');
      }));

      it('should use template-relative CSS URIs', async(
          (Http http, Compiler compile, Scope rootScope, Logger log,
           Injector injector, MockHttpBackend backend, DirectiveMap directives) {
        backend
            ..expectGET('base/test/core/simple.css').respond(200, 'body { background-image: url(foo.png);}')
            ..expectGET('base/test/core/simple.html').respond(200, '<div log="SIMPLE">Simple!</div>');

        var element = e('<div><html-and-css log>ignore</html-and-css><div>');
        compile([element], directives)(rootScope, injector.get(DirectiveInjector), [element]);

        microLeap();
        backend.flush();
        microLeap();

        expect(element).toHaveText(
            'body { background-image: url(\'base/test/core/foo.png\');}Simple!');
      }));

      it('should load a CSS file with a \$template', async(inject(
          (Http http, Compiler compile, Scope rootScope, Injector injector,
           MockHttpBackend backend, DirectiveMap directives) {
        var element = es('<div><inline-with-css log>ignore</inline-with-css><div>');
        backend.expectGET('base/test/core/simple.css').respond(200, '.hello{}');
        compile(element, directives)(rootScope, injector.get(DirectiveInjector), element);

        microLeap();
        backend.flush();
        microLeap();
        expect(element[0]).toHaveText('.hello{}inline!');
      })));

      it('should ignore CSS load errors ', async(
          (Http http, Compiler compile, Scope rootScope, Injector injector,
           MockHttpBackend backend, DirectiveMap directives) {
        var element = es('<div><inline-with-css log>ignore</inline-with-css><div>');

        backend.expectGET('base/test/core/simple.css').respond(500, 'some error');
        compile(element, directives)(rootScope, injector.get(DirectiveInjector), element);

        microLeap();
        backend.flush();
        microLeap();
        expect(element.first).toHaveText(
            '/*\n'
            'HTTP 500: some error\n'
            '*/\n'
            'inline!');
      }));

      it('should load a CSS with no template', async(
          (Http http, Compiler compile, Scope rootScope, Injector injector,
           MockHttpBackend backend, DirectiveMap directives) {
        var element = es('<div><only-css log>ignore</only-css><div>');

        backend.expectGET('base/test/core/simple.css').respond(200, '.hello{}');
        compile(element, directives)(rootScope, injector.get(DirectiveInjector), element);

        microLeap();
        backend.flush();
        microLeap();
        expect(element[0]).toHaveText('.hello{}');
      }));

      it('should load the CSS before the template is loaded', async(
          (Http http, Compiler compile, Scope rootScope, Injector injector,
           MockHttpBackend backend, DirectiveMap directives) {
        backend
            ..expectGET('base/test/core/simple.css').respond(200, '.hello{}')
            ..expectGET('base/test/core/simple.html').respond(200, '<div>Simple!</div>');

        var element = es('<html-and-css>ignore</html-and-css>');
        compile(element, directives)(rootScope, injector.get(DirectiveInjector), element);

        microLeap();
        backend.flush();
        microLeap();
        expect(element.first).toHaveText('.hello{}Simple!');
      }));
    });

    describe('multiple css loading', () {
      beforeEachModule((Module module) {
        module
            ..bind(LogAttrDirective)
            ..bind(HtmlAndMultipleCssComponent)
            ..bind(ResourceResolverConfig, toValue: new ResourceResolverConfig(useRelativeUrls: true));
      });

      it('should load multiple CSS files into a style', async(
          (Http http, Compiler compile, Scope rootScope, Logger log,
           Injector injector, MockHttpBackend backend, DirectiveMap directives) {
        backend
            ..expectGET('base/test/core/simple.css').respond(200, '.hello{}')
            ..expectGET('base/test/core/another.css').respond(200, '.world{}')
            ..expectGET('base/test/core/simple.html').respond(200, '<div log="SIMPLE">Simple!</div>');

        var element = e('<div><html-and-multi-css log>ignore</html-and-multi-css><div>');
        compile([element], directives)(rootScope, injector.get(DirectiveInjector), [element]);

        microLeap();
        backend.flush();
        microLeap();

        expect(element).toHaveText('.hello{}.world{}Simple!');
        expect(element.children[0].shadowRoot).toHaveHtml(
            '<style>.hello{}</style><style>.world{}</style><div log="SIMPLE">Simple!</div>'
        );
        rootScope.apply();
        // Note: There is no ordering.  It is who ever comes off the wire first!
        expect(log.result()).toEqual('LOG; SIMPLE');
      }));
    });

    describe('style cache', () {
      beforeEachModule((Module module) {
        module
            ..bind(HtmlAndCssComponent)
            ..bind(TemplateCache, toValue: new TemplateCache(capacity: 0))
            ..bind(ResourceResolverConfig, toValue: new ResourceResolverConfig(useRelativeUrls: true));
      });

      it('should load css from the style cache for the second component', async(
          (Http http, Compiler compile, MockHttpBackend backend, RootScope rootScope,
           DirectiveMap directives, Injector injector) {
        backend
          ..expectGET('base/test/core/simple.css').respond(200, '.hello{}')
          ..expectGET('base/test/core/simple.html').respond(200, '<div log="SIMPLE">Simple!</div>');

        var element = e('<div><html-and-css>ignore</html-and-css><div>');
        compile([element], directives)(rootScope, injector.get(DirectiveInjector), [element]);

        microLeap();
        backend.flush();
        microLeap();

        expect(element.children[0].shadowRoot).toHaveHtml(
            '<style>.hello{}</style><div log="SIMPLE">Simple!</div>'
        );

        var element2 = e('<div><html-and-css>ignore</html-and-css><div>');
        compile([element2], directives)(rootScope, injector.get(DirectiveInjector), [element2]);

        microLeap();

        expect(element2.children[0].shadowRoot).toHaveHtml(
            '<style>.hello{}</style><div log="SIMPLE">Simple!</div>'
        );
      }));
    });
  });
}
