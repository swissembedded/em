/**
 * Copyright (c) 2010-2015, openHAB.org and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */
package org.openhab.binding.egosmartheater.internal;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This class represents a heater with its communication configuration.
 * @author Daniel Haensse
 * @since 1.6.0
 */
public class Heater {

	private static final Logger logger = LoggerFactory
			.getLogger(Heater.class);

	private final HeaterConfig config;

	private final String name;

	public Heater(String name, HeaterConfig config) {
		this.name = name;
		this.config = config;
	}

	/**
	 * Return the name of the heater
	 * 
	 * @return the name of the heater
	 */
	public String getName() {
		return name;
	}

	/**
	 * Return the configuration of this heater
	 * 
	 * @return the heater configuration
	 */
	public HeaterConfig getConfig() {
		return config;
	}

	/**
	 * Reads data from heater
	 * 
	 * @return a map of DataSet objects with the parameters
	 */
	public Map<String, DataSet> read(int regulatePower, boolean regulateState) {
		// the frequently executed code (polling) goes here ...
		Map<String, DataSet> dataSetMap = new HashMap<String, DataSet>();
//		if(config.getSerialPort().length()==0)
//		{
			ConnectionTCP connection = new ConnectionTCP(config.getTCPHost(),
					config.getTCPPort());
			try {
					connection.open();
				
				List<DataSet> dataSets = null;
				try {
					dataSets = connection.read(regulatePower, regulateState);
					for (DataSet dataSet : dataSets) {
						logger.debug("DataSet: {}/{}", dataSet.getName(),
								dataSet.getValue());
						dataSetMap.put(dataSet.getName(), dataSet);
					}
				} catch (IOException e) {
					logger.error("IOException while trying to read: {}", e.getMessage());
				} 
			} finally {
				connection.close();
			}
//		}
//		else
//		{
//			Connection connection = new Connection(config.getSerialPort(),
//					config.getEchoHandling(), config.getBaudRateChangeDelay());
//			try {
//				try {
//					connection.open();
//				} catch (IOException e) {
//					logger.error("Failed to open serial port {}: {}",
//							config.getSerialPort(), e.getMessage());
//					return dataSetMap;
//				}
//				
//				List<DataSet> dataSets = null;
//				try {
//					dataSets = connection.read();
//					for (DataSet dataSet : dataSets) {
//						logger.debug("DataSet: {};{};{}", dataSet.getId(),
//								dataSet.getValue(), dataSet.getUnit());
//						dataSetMap.put(dataSet.getId(), dataSet);
//					}
//				} catch (IOException e) {
//					logger.error("IOException while trying to read: {}", e.getMessage());
//				} catch (TimeoutException e) {
//					logger.error("Read attempt timed out");
//				}
//			} finally {
//				connection.close();
//			}			
//		}

		return dataSetMap;
	}

}
