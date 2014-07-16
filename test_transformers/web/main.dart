library animation;

import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:angular/animate/module.dart';


import 'relative_uris/foo2/relative_foo.dart';


@Controller(
    selector: '[animation-demo]',
    publishAs: 'demo')
class AnimationDemo {
  final pages = ["About", "ng-repeat", "Visibility", "Css", "Stress Test"];
  var currentPage = "About";
}

class AnimationDemoModule extends Module {
  AnimationDemoModule() {
    install(new AnimationModule());
    bind(RelativeFooComponent);
    bind(ResourceResolverConfig, toValue: new ResourceResolverConfig(useRelativeUrls: true));
  }
}
main() {
  applicationFactory()
      .addModule(new AnimationDemoModule())
      .run();
}
