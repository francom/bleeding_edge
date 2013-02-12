/*
 * Copyright (c) 2013, the Dart project authors.
 * 
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 * 
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package com.google.dart.engine.services.status;

import com.google.common.base.Objects;
import com.google.dart.engine.ast.CompilationUnit;
import com.google.dart.engine.context.AnalysisContext;
import com.google.dart.engine.element.CompilationUnitElement;
import com.google.dart.engine.source.Source;
import com.google.dart.engine.utilities.source.SourceRange;

/**
 * {@link RefactoringStatusContext} can be used to annotate a {@link RefactoringStatusEntry} with
 * additional information typically presented in the user interface.
 */
public class RefactoringStatusContext {
  /**
   * @return the {@link RefactoringStatusContext} which corresponds to given location in the
   *         {@link Source} of the given {@link CompilationUnit}.
   */
  public static RefactoringStatusContext create(CompilationUnit unit, SourceRange range) {
    CompilationUnitElement unitElement = unit.getElement();
    assert unitElement != null;
    return new RefactoringStatusContext(unitElement.getContext(), unitElement.getSource(), range);
  }

  private final AnalysisContext context;
  private final Source source;
  private final SourceRange range;

  public RefactoringStatusContext(AnalysisContext context, Source source, SourceRange range) {
    this.context = context;
    this.source = source;
    this.range = range;
  }

  /**
   * @return the {@link AnalysisContext} in which this status occurs.
   */
  public AnalysisContext getContext() {
    return context;
  }

  /**
   * @return the {@link SourceRange} with specific location where this status occurs.
   */
  public SourceRange getRange() {
    return range;
  }

  /**
   * @return the {@link Source} in which this status occurs.
   */
  public Source getSource() {
    return source;
  }

  @Override
  public String toString() {
    return Objects.toStringHelper(this).add("source", source).add("range", range).toString();
  }
}