import 'package:flutter/material.dart';

import 'staff_app_state.dart';

class StaffStateScope extends InheritedNotifier<StaffAppState> {
  const StaffStateScope({
    super.key,
    required StaffAppState state,
    required super.child,
  }) : super(notifier: state);

  static StaffAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StaffStateScope>();
    assert(scope != null, 'No StaffStateScope found in context');
    return scope!.notifier!;
  }

  static StaffAppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<StaffStateScope>();
    assert(scope != null, 'No StaffStateScope found in context');
    return scope!.notifier!;
  }
}
