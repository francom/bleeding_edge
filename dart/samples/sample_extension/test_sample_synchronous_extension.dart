// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_sample_extension;

import 'sample_synchronous_extension.dart';

void check(bool condition, String message) {
  if (!condition) {
    throw new StateError(message);
  }
}

// TODO(3008): Run this test automatically on buildbot (dart:3008).
void main() {
  systemSrand(17);
  var x1 = systemRand();
  var x2 = systemRand();
  var x3 = systemRand();
  check(x1 != x2, "x1 != x2");
  check(x1 != x3, "x1 != x3");
  check(x2 != x3, "x2 != x3");
  systemSrand(17);
  check(x1 == systemRand(), "x1 == systemRand()");
  check(x2 == systemRand(), "x2 == systemRand()");
  check(x3 == systemRand(), "x3 == systemRand()");
  systemSrand(18);
  check(x1 != systemRand(), "x1 != systemRand()");
  check(x2 != systemRand(), "x2 != systemRand()");
  check(x3 != systemRand(), "x3 != systemRand()");
}
