/**
 * Copyright (c) 2010-2015, openHAB.org and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */
package org.openhab.binding.egosmartheater;

import org.openhab.core.binding.BindingProvider;
import org.openhab.core.items.Item;

/**
 * @author Daniel Haensse
 * @since 1.6.0
 */


public interface EgoSmartHeaterBindingProvider extends BindingProvider {

	/**
	 * Returns the heater for the given <code>itemName</code>. If the itemName is unknown,
	 * <code>null<code> is returned
	 * 
	 * @param itemName
	 *            the item to find 
	 * @return the configured value or <code>null<code> if nothing is configured
	 *         or the itemName is unknown
	 */
	public String getHeaterName(String itemName);

	/**
	 * Returns the heater parameter <code>itemName</code>. If
	 * the itemName is unknown, <code>null<code> is returned
	 * 
	 * @param itemName
	 *            the item to find 
	 * @return the configured value or <code>null<code> if nothing is
	 *         configured or the itemName is unknown
	 */
	public String getHeaterParameter(String itemName);

	/**
	 * Returns the Type of the Item identified by {@code itemName}
	 * 
	 * @param itemName
	 *            the name of the item to find the type for
	 * @return the type of the Item identified by {@code itemName}
	 */
	Class<? extends Item> getItemType(String itemName);
	
}
