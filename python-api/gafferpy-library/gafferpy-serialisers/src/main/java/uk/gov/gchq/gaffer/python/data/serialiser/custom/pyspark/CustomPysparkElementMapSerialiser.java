/*
 * Copyright 2016-2018 Crown Copyright
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package uk.gov.gchq.gaffer.python.data.serialiser.custom.pyspark;

import uk.gov.gchq.gaffer.data.element.Element;
import uk.gov.gchq.gaffer.python.data.serialiser.custom.CustomPythonElementMapSerialiser;
import uk.gov.gchq.gaffer.python.pyspark.serialiser.PySparkSerialiser;

import java.util.Map;

public class CustomPysparkElementMapSerialiser extends CustomPythonElementMapSerialiser implements PySparkSerialiser<Element, Map<String, Object>> {

    @Override
    public Map<String, Object> convert(Element element) {
        return this.serialise(element);
    }
}


