/**
 * Copyright (c) 2010-2015, openHAB.org and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */
package org.openhab.binding.egosmartheater.internal;

import java.util.StringTokenizer;

import org.openhab.binding.egosmartheater.EgoSmartHeaterBindingProvider;
import org.openhab.core.binding.BindingConfig;
import org.openhab.core.items.Item;
import org.openhab.core.library.items.NumberItem;
import org.openhab.core.library.items.StringItem;
import org.openhab.model.item.binding.AbstractGenericBindingProvider;
import org.openhab.model.item.binding.BindingConfigParseException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * <p>This class is responsible for parsing the binding configuration.
 * 
 * <p>Here are some examples for valid binding configuration strings:
 * 
 * <ul>
 * 	<li><code>{ egosmartheater="ego1:temperature" }</code> - shows water temperature'</li>
 * </ul>
 * @author Daniel Haensse
 * @since 1.6.0
 */
public class EgoSmartHeaterGenericBindingProvider extends
		AbstractGenericBindingProvider implements EgoSmartHeaterBindingProvider {

	private static final Logger logger = LoggerFactory
			.getLogger(EgoSmartHeaterGenericBindingProvider.class);

	/**
	 * {@inheritDoc}
	 */
	public String getBindingType() {
		return "egosmartheater";
	}

	/**
	 * @{inheritDoc
	 */
	@Override
	public void validateItemType(Item item, String bindingConfig)
			throws BindingConfigParseException {
		if (!(item instanceof NumberItem || item instanceof StringItem)) {
			throw new BindingConfigParseException(
					"item '"
							+ item.getName()
							+ "' is of type '"
							+ item.getClass().getSimpleName()
							+ "', only Number- and StringItems are allowed - please check your *.items configuration");
		}
		logger.debug(bindingConfig);

	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	public void processBindingConfiguration(String context, Item item,
			String bindingConfig) throws BindingConfigParseException {
		super.processBindingConfiguration(context, item, bindingConfig);
		EgoSmartHeaterBindingConfig config = new EgoSmartHeaterBindingConfig();
		StringTokenizer tokenizer = new StringTokenizer(bindingConfig.trim(),
				":");
		String[] tokens = new String[tokenizer.countTokens()];
		for (int i = 0; i < tokens.length; i++) {
			tokens[i] = tokenizer.nextToken();
		}
		config.heaterName = tokens[0].trim();
		config.heaterVariable = tokens[1].trim();
		config.itemType = item.getClass();
		addBindingConfig(item, config);
	}

	@Override
	public String getHeaterParameter(String itemName) {
		EgoSmartHeaterBindingConfig config = (EgoSmartHeaterBindingConfig) bindingConfigs
				.get(itemName);
		return config != null ? config.heaterVariable : null;
	}

	@Override
	public String getHeaterName(String itemName) {
		EgoSmartHeaterBindingConfig config = (EgoSmartHeaterBindingConfig) bindingConfigs
				.get(itemName);
		return config != null ? config.heaterName : null;
	}

	/**
	 * @{inheritDoc
	 */
	@Override
	public Class<? extends Item> getItemType(String itemName) {
		EgoSmartHeaterBindingConfig config = (EgoSmartHeaterBindingConfig) bindingConfigs
				.get(itemName);
		return config != null ? config.itemType : null;
	}

	class EgoSmartHeaterBindingConfig implements BindingConfig {
		public String heaterName;
		public String heaterVariable;
		public Class<? extends Item> itemType;
	}

}
