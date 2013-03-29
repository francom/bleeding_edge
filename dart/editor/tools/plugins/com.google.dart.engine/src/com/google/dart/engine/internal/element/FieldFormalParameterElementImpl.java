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
package com.google.dart.engine.internal.element;

import com.google.dart.engine.ast.Identifier;
import com.google.dart.engine.element.FieldElement;

/**
 * Instances of the class {@code FieldFormalParameterElementImpl} extend
 * {@link ParameterElementImpl} to provide the additional information of the {@link FieldElement}
 * associated with the parameter.
 * 
 * @coverage dart.engine.element
 */
public class FieldFormalParameterElementImpl extends ParameterElementImpl {

  /**
   * The field associated with this field formal parameter.
   */
  private FieldElement field;

  /**
   * Initialize a newly created parameter element to have the given name.
   * 
   * @param name the name of this element
   */
  public FieldFormalParameterElementImpl(Identifier name) {
    super(name);
  }

  /**
   * Get the field element associated with this field formal parameter, or {@code null} if the
   * parameter references a field that doesn't exist.
   * 
   * @return the field element associated with this field formal parameter
   */
  public FieldElement getField() {
    return field;
  }

  /**
   * Set the field element associated with this field formal parameter.
   * 
   * @param field the new field element
   */
  public void setField(FieldElement field) {
    this.field = field;
  }
}