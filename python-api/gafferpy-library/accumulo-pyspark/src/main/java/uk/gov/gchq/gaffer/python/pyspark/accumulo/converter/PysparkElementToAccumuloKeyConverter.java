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

package uk.gov.gchq.gaffer.python.pyspark.accumulo.converter;

import org.apache.accumulo.core.data.Key;
import org.apache.spark.api.python.Converter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.gov.gchq.gaffer.accumulostore.key.AccumuloKeyPackage;
import uk.gov.gchq.gaffer.data.element.Element;
import uk.gov.gchq.gaffer.exception.SerialisationException;
import uk.gov.gchq.gaffer.jsonserialisation.JSONSerialiser;
import uk.gov.gchq.gaffer.store.schema.Schema;

public class PysparkElementToAccumuloKeyConverter implements Converter<String, Key> {

    private static final Logger LOGGER = LoggerFactory.getLogger(PysparkElementToAccumuloKeyConverter.class);

    @Override
    public Key convert(final String input) {

        String[] t = input.split(";");

        String elementString = t[0];
        String schemaAsJson = t[1];
        String keyPackageClassName = t[2];

        Element element = null;
        try {
            element = JSONSerialiser.deserialise(elementString, Element.class);
        } catch (final SerialisationException e) {
            LOGGER.error(e.getMessage());
        }

        Schema schema = Schema.fromJson(schemaAsJson.getBytes());

        AccumuloKeyPackage keyPackage = null;
        try {
            keyPackage = (AccumuloKeyPackage) Class.forName(keyPackageClassName).newInstance();
        } catch (final InstantiationException | IllegalAccessException | ClassNotFoundException e) {
            LOGGER.error(e.getMessage());
        }

        keyPackage.setSchema(schema);

        return keyPackage.getKeyConverter().getKeysFromElement(element).getFirst();
    }
}
