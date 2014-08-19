library foo;

import 'package:angular/angular.dart';

@Component(
    selector: 'ck-foo',
    useShadowDom: false,
    templateUrl: 'foo.html',
    publishAs: 'ctrl',
    applyAuthorStyles: false)
class FooComponent {
}
