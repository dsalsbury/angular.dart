library foo2_repeat_demo;

import 'package:angular/angular.dart';

@Component(
    selector: 'repeat-demo2',
    useShadowDom: false,
    templateUrl: 'repeat_demo2.html',
    publishAs: 'ctrl',
    applyAuthorStyles: true)
class RepeatDemo2 {
  var thing = 0;
  final items = [];

  void addItem() {
    items.add("Thing ${thing++}");
  }

  void removeItem() {
    if (items.isNotEmpty) items.removeLast();
  }
}
