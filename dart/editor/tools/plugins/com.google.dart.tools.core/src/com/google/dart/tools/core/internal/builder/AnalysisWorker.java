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
package com.google.dart.tools.core.internal.builder;

import com.google.dart.engine.ast.CompilationUnit;
import com.google.dart.engine.context.AnalysisContext;
import com.google.dart.engine.context.ChangeNotice;
import com.google.dart.engine.error.AnalysisError;
import com.google.dart.engine.index.Index;
import com.google.dart.engine.source.Source;
import com.google.dart.engine.utilities.source.LineInfo;
import com.google.dart.tools.core.DartCore;
import com.google.dart.tools.core.analysis.model.Project;
import com.google.dart.tools.core.analysis.model.ProjectManager;

import org.eclipse.core.resources.IResource;

/**
 * Instances of {@code AnalysisWorker} perform analysis by repeatedly calling
 * {@link AnalysisContext#performAnalysisTask()} and update both the index and the error markers
 * based upon the analysis results.
 */
public class AnalysisWorker {

  /**
   * The project containing the source for this context.
   */
  protected final Project project;

  /**
   * The analysis context on which analysis is performed.
   */
  protected final AnalysisContext context;

  /**
   * The marker manager used to translate errors into Eclipse markers (not {@code null}).
   */
  private final AnalysisMarkerManager markerManager;

  /**
   * The index to be updated (not {@code null}).
   */
  private final Index index;

  /**
   * Construct a new instance for performing analysis which updates the
   * {@link ProjectManager#getIndex() default index} and uses the
   * {@link AnalysisMarkerManager#getInstance() default marker manager} to translate errors into
   * Eclipse markers.
   * 
   * @param project the project containing sources for the specified context (not {@code null})
   * @param context the context used to perform the analysis (not {@code null})
   */
  public AnalysisWorker(Project project, AnalysisContext context) {
    this(
        project,
        context,
        DartCore.getProjectManager().getIndex(),
        AnalysisMarkerManager.getInstance());
  }

  /**
   * Construct a new instance for performing analysis.
   * 
   * @param project the project containing sources for the specified context (not {@code null})
   * @param context the context used to perform the analysis (not {@code null})
   * @param index the index to be updated (not {@code null})
   * @param the marker manager used to translate errors into Eclipse markers (not {@code null})
   */
  public AnalysisWorker(Project project, AnalysisContext context, Index index,
      AnalysisMarkerManager markerManager) {
    this.project = project;
    this.context = context;
    this.index = index;
    this.markerManager = markerManager;
  }

  /**
   * Perform analysis by repeatedly calling {@link AnalysisContext#performAnalysisTask()} and update
   * both the index and the error markers based upon the analysis results.
   */
  public void performAnalysis() {
    ChangeNotice[] changes = context.performAnalysisTask();
    while (processResults(changes) && checkContext()) {
      changes = context.performAnalysisTask();
    }
    markerManager.done();
  }

  /**
   * Subclasses may override this method to call various "get" methods on the context looking to see
   * if information it needs is cached.
   * 
   * @return {@code true} if analysis should continue, or {@code false} to exit the
   *         {@link #performAnalysis()} loop.
   */
  protected boolean checkContext() {
    return true;
  }

  /**
   * Update the index and error markers based upon the specified change.
   * 
   * @param change the analysis change (not {@code null})
   */
  private void processChange(ChangeNotice change) {

    // If errors are available, then queue the errors to be translated to markers
    AnalysisError[] errors = change.getErrors();
    if (errors != null) {
      Source source = change.getSource();
      IResource res = project.getResource(source);
      if (res == null) {
        // TODO (danrubel): log unmatched sources once context only returns errors for added sources
//        DartCore.logError("Failed to determine resource for: " + source);
      } else {
        LineInfo lineInfo = change.getLineInfo();
        if (lineInfo == null) {
          DartCore.logError("Missing line information for: " + source);
        } else {
          markerManager.queueErrors(res, lineInfo, errors);
        }
      }
    }

    // If there is a unit to be indexed, then do so
    CompilationUnit unit = change.getCompilationUnit();
    if (unit != null) {
      index.indexUnit(context, unit);
    }
  }

  /**
   * Update both the index and the error markers based upon the analysis results.
   * 
   * @param changes the changes or {@code null} if there is no more work to be done
   * @return {@code true} if there may be more analysis, or {@code false} if not
   */
  private boolean processResults(ChangeNotice[] changes) {

    // if no more tasks, then return false indicating analysis is complete
    if (changes == null) {
      return false;
    }

    // process results and return true indicating there might be more analysis
    for (ChangeNotice change : changes) {
      processChange(change);
    }
    return true;
  }
}