library angular.tools.transformer.options;

import 'package:di/transformer.dart' as di show TransformOptions;

/** Options used by Angular transformers */
class TransformOptions {

  /**
   * List of html file paths which may contain Angular expressions.
   * The paths are relative to the package home and are represented using posix
   * style, which matches the representation used in asset ids in barback.
   */
  final List<String> htmlFiles;

  /**
   * Path to the Dart SDK directory, for resolving Dart libraries.
   */
  final String sdkDirectory;

  /**
   * Template cache path modifiers
   */
  final Map<String, String> templateUriRewrites;

  /**
   * Dependency injection options.
   */
  final di.TransformOptions diOptions;
  
  //TODO: Do I need to add tests for these additions somewhere?
  /**
   * Entry point for AST Resolver
   */
  final String entryPoint;
  
  /**
   * List of paths from which templates with absolute paths can
   * be fetched for use in the Template Cache Generator. This is 
   * optional, and if undefined will default to '.'.
   */
  final List<String> templateRoots;
  
  /**
   * For use in the Template Cache Generator: List of classes to 
   * skip putting in the template cache.  This is optional, and if 
   * undefined will default to empty
   */
  final Set<String> skippedTemplateCacheClasses;
  
  /**
   * For use in the Template Cache Generator: Application used to 
   * rewrite css.  Each css file will be passed to stdin and rewritten
   * one is expected on stdout.  This is optional, and if undefined
   * will default to empty
   */
  final String cssRewriter;
  

  TransformOptions({String sdkDirectory, List<String> htmlFiles,
      Map<String, String> templateUriRewrites, String entryPoint,
      List<String> templateRoots,
      Set<String> skippedTemplateCacheClasses,
      String cssRewriter,
      di.TransformOptions diOptions}) :
      sdkDirectory = sdkDirectory,
      htmlFiles = htmlFiles != null ? htmlFiles : [],
      templateUriRewrites = templateUriRewrites != null ?
          templateUriRewrites : {},
      entryPoint = entryPoint,
      templateRoots = templateRoots,
      skippedTemplateCacheClasses = skippedTemplateCacheClasses,
      cssRewriter = cssRewriter,
      diOptions = diOptions {
    if (sdkDirectory == null)
      throw new ArgumentError('sdkDirectory must be provided.');
  }
}
