// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// To decouple the reporting of errors, and allow for extensibility of
// matchers, we make use of some interfaces.

/**
 * The ErrorFormatter type is used for functions that
 * can be used to build up error reports upon [expect] failures.
 * There is one built-in implementation ([defaultErrorFormatter])
 * which is used by the default failure handler. If the failure handler
 * is replaced it may be desirable to replace the [stringDescription]
 * error formatter with another.
 */
typedef String ErrorFormatter(actual, Matcher matcher, String reason,
    MatchState matchState, bool verbose);

/**
 * Matchers build up their error messages by appending to
 * Description objects. This interface is implemented by
 * StringDescription. This interface is unlikely to need
 * other implementations, but could be useful to replace in
 * some cases - e.g. language conversion.
 */
interface Description {
  /** Change the value of the description. */
  Description replace(String text);

  /** This is used to add arbitrary text to the description. */
  Description add(String text);

  /** This is used to add a meaningful description of a value. */
  Description addDescriptionOf(value);

  /**
   * This is used to add a description of an [Iterable] [list],
   * with appropriate [start] and [end] markers and inter-element [separator].
   */
  Description addAll(String start, String separator, String end,
                       Iterable list);
}

/**
 * [expect] Matchers must implement the Matcher interface.
 * The base Matcher class that implements this interface has
 * a generic implementation of [describeMismatch] so this does
 * not need to be provided unless a more clear description is
 * required. The other two methods ([matches] and [describe])
 * must always be provided as they are highly matcher-specific.
 */
interface Matcher {
  /**
   * This does the matching of the actual vs expected values.
   * [item] is the actual value. [matchState] can be supplied
   * and may be used to add details about the mismatch that are too
   * costly to determine in [describeMismatch].
   */
  bool matches(item, MatchState matchState);

  /** This builds a textual description of the matcher. */
  Description describe(Description description);

  /**
   * This builds a textual description of a specific mismatch. [item]
   * is the value that was tested by [matches]; [matchState] is
   * the [MatchState] that was passed to and supplemented by [matches]
   * with additional information about the mismact, and [mismatchDescription]
   * is the [Description] that is being built to decribe the mismatch.
   * A few matchers make use of the [verbose] flag to provide detailed
   * information that is not typically included but can be of help in
   * diagnosing failures, such as stack traces.
   */
  Description describeMismatch(item, Description mismatchDescription,
      MatchState matchState, bool verbose);
}

/**
 * Failed matches are reported using a default IFailureHandler.
 * The default implementation simply throws ExpectExceptions;
 * this can be replaced by some other implementation of
 * IFailureHandler by calling configureExpectHandler.
 */
interface FailureHandler {
  /** This handles failures given a textual decription */
  void fail(String reason);

  /**
   * This handles failures given the actual [value], the [matcher]
   * the [reason] (argument from [expect]), some additonal [matchState]
   * generated by the [matcher], and a verbose flag which controls in
   * some cases how much [matchState] information is used. It will use
   * these to create a detailed error message (typically by calling
   * an [ErrorFormatter]) and then call [fail] with this message.
   */
  void failMatch(actual, Matcher matcher, String reason,
                 MatchState matchState, bool verbose);
}

