package com.google.dart.engine.services.completion;

import com.google.common.base.Joiner;
import com.google.dart.engine.ast.CompilationUnit;
import com.google.dart.engine.context.AnalysisException;
import com.google.dart.engine.resolver.ResolverTestCase;
import com.google.dart.engine.services.assist.AssistContext;
import com.google.dart.engine.services.util.LocationSpec;
import com.google.dart.engine.services.util.MockCompletionRequestor;
import com.google.dart.engine.source.Source;

import java.net.URISyntaxException;
import java.util.Collection;

public class CompletionTestCase extends ResolverTestCase {

  protected static final String NAME_OF_SOURCE_TO_ANALYZE = "/some/long/name/that/is/unique/in/tests";

  protected static String src(String... parts) {
    return Joiner.on('\n').join(parts);
  }

  /**
   * Run a set of completion tests on the given <code>originalSource</code>. The source string has
   * completion points embedded in it, which are identified by '!X' where X is a single character.
   * Each X is matched to positive or negative results in the array of
   * <code>validationStrings</code>. Validation strings contain the name of a prediction with a two
   * character prefix. The first character of the prefix corresponds to an X in the
   * <code>originalSource</code>. The second character is either a '+' or a '-' indicating whether
   * the string is a positive or negative result.
   * 
   * @param originalSource The source for a completion test that contains completion points
   * @param validationStrings The positive and negative predictions
   */
  protected void test(String originalSource, String... results) throws URISyntaxException,
      AnalysisException {
    Collection<LocationSpec> completionTests = LocationSpec.from(originalSource, results);
    assertTrue(
        "Expected exclamation point ('!') within the source"
            + " denoting the position at which code completion should occur",
        !completionTests.isEmpty());
    CompilationUnit compilationUnit = analyze(completionTests.iterator().next().source);
    CompletionFactory factory = new CompletionFactory();
    for (LocationSpec test : completionTests) {
      MockCompletionRequestor requestor = new MockCompletionRequestor();
      CompletionEngine engine = new CompletionEngine(requestor, factory);
      engine.complete(new AssistContext(compilationUnit, test.testLocation, 0));
      if (test.positiveResults.size() > 0) {
        assertTrue("Expected code completion suggestions", requestor.validate());
      }
      for (String result : test.positiveResults) {
        requestor.assertSuggested(result);
      }
      for (String result : test.negativeResults) {
        requestor.assertNotSuggested(result);
      }
    }
  }

  private CompilationUnit analyze(String content) throws AnalysisException {
    Source source = addSource(NAME_OF_SOURCE_TO_ANALYZE, content);
    resolve(source);
    CompilationUnit unit = getAnalysisContext().parse(source);
    return unit;
  }

}