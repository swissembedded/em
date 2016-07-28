/**
 * Copyright (c) 2010-2015, openHAB.org and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */
package org.openhab.binding.egosmartheater.internal;

import java.util.Dictionary;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang.StringUtils;
import org.openhab.binding.egosmartheater.EgoSmartHeaterBindingProvider;
import org.openhab.core.binding.AbstractActiveBinding;
import org.openhab.core.items.Item;
import org.openhab.core.library.items.NumberItem;
import org.openhab.core.library.items.StringItem;
import org.openhab.core.library.types.DecimalType;
import org.openhab.core.library.types.StringType;
import org.openhab.core.types.Command;
import org.openhab.core.types.State;
import org.osgi.service.cm.ConfigurationException;
import org.osgi.service.cm.ManagedService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Ego smart heater binding implementation
 * 
 * @author Daniel Haensse
 * @since 1.6.0
 */
public class EgoSmartHeaterBinding extends
		AbstractActiveBinding<EgoSmartHeaterBindingProvider> implements
		ManagedService {

	private static final Logger logger = LoggerFactory
			.getLogger(EgoSmartHeaterBinding.class);

	// regEx to validate a meter config
	// <code>'^(.*?)\\.(serialPort|baudRateChangeDelay|echoHandling)$'</code>
	private final Pattern HEATER_CONFIG_PATTERN = Pattern
			.compile("^(.*?)\\.(tcpHost|tcpPort)$");

	private static final long DEFAULT_REFRESH_INTERVAL = 60000;
	private static final long REG_TIME = 300000; //5min, decreasing this constant will result in faster wearout of the relay inside the ego heater

	/**
	 * the refresh interval which is used to poll values from the ego smart heater
	 * (optional, defaults to 10 minutes)
	 */
	private long refreshInterval = DEFAULT_REFRESH_INTERVAL;

	// configured heater devices - keyed by heater device name
	private final Map<String, Heater> heaterDeviceConfigurtions = new HashMap<String, Heater>();

	int regulatePower =0;
	boolean regulateState=false;
	long timeStamp=0;
	
	public EgoSmartHeaterBinding() {
	}

	public void activate() {

	}

	public void deactivate() {
		heaterDeviceConfigurtions.clear();
	}

	/**
	 * @{inheritDoc
	 */
	@Override
	protected long getRefreshInterval() {
		return refreshInterval;
	}

	/**
	 * @{inheritDoc
	 */
	@Override
	protected String getName() {
		return "egosmartheater Refresh Service";
	}

	private final Heater createEgoSmartHeaterConfig(String name,
			HeaterConfig config) {

		Heater reader = null;
		reader = new Heater(name, config);
		return reader;
	}

	/**
	 * @{inheritDoc
	 */
	@Override
	protected void execute() {
		// the frequently executed code (polling) goes here ...
		Map<String, Map<String, DataSet>> cache = new HashMap<String, Map<String,DataSet>>();
		for (EgoSmartHeaterBindingProvider provider : providers) {

			for (String itemName : provider.getItemNames()) {
				
				for (Entry<String, Heater> entry : heaterDeviceConfigurtions.entrySet()) {
					
					Heater reader = entry.getValue();
					String heaterName = provider.getHeaterName(itemName);
					if(heaterName != null && heaterName.equals(entry.getKey())) {
						Map<String, DataSet> dataSets;
						// Check cache, if no entry we have to run a modbus cycle to get all the vars we need
						if((dataSets = cache.get(heaterName)) == null) {
							if(logger.isDebugEnabled())
								logger.debug("Read ego smart heater: " + heaterName);
							long now=System.currentTimeMillis();
							if((now-timeStamp) > REG_TIME)
							{
								// Only regulate the power every 5 minutes
								timeStamp=now;
								regulateState = true;
							}
							else
							{
								regulateState = false;
							}
							
							dataSets = reader.read(regulatePower, regulateState);
							cache.put(heaterName, dataSets);
						}
						// data is available now, process the items and post updates to openhab
						String param = provider.getHeaterParameter(itemName);
						if (param != null && dataSets.containsKey(param)) {
							DataSet dataSet = dataSets.get(param);
							if(logger.isDebugEnabled())
								logger.debug("Updateing item " + itemName + " with paramter " + param + " and value " + dataSet.getValue());
							Class<? extends Item> itemType = provider.getItemType(itemName);
							if (itemType.isAssignableFrom(NumberItem.class)) {
								eventPublisher.postUpdate(itemName,
										new DecimalType(dataSet.getValue()));
							}
							if (itemType.isAssignableFrom(StringItem.class)) {
								String value = dataSet.getValue();
								eventPublisher.postUpdate(itemName, new StringType(
										value));
							}
						}
					}
				}
			}

		}
	}

	/**
	 * @{inheritDoc
	 */
	protected void internalReceiveCommand(String itemName, Command command) {
		// the code being executed when a command was sent on the openHAB
		// event bus goes here. This method is only called if one of the
		// BindingProviders provide a binding for the given 'itemName'.
		if(logger.isDebugEnabled())
			logger.debug("internalReceiveCommand() is called! itemName "+itemName+" command "+ command.toString());
		
		for (EgoSmartHeaterBindingProvider provider : providers) {
			for (String iteritemName : provider.getItemNames()) {					
				if(itemName.equals(iteritemName))
				{					
					String param = provider.getHeaterParameter(iteritemName);					
					if(param!=null && param.equals("regulatePower"))
					{	
						
						regulatePower=Math.round(Float.parseFloat(command.toString()));
						logger.debug("set power "+regulatePower);
						
					}
				}
			}

		}
	}

	/**
	 * @{inheritDoc
	 */
	protected void internalReceiveUpdate(String itemName, State newState) {
		// the code being executed when a state was sent on the openHAB
		// event bus goes here. This method is only called if one of the
		// BindingProviders provide a binding for the given 'itemName'.
		logger.debug("internalReceiveUpdate() is called! itemName "+itemName+" newstate "+newState.toString());		
	}

	/**
	 * @{inheritDoc
	 */
	@Override
	public void updated(Dictionary<String, ?> config)
			throws ConfigurationException {

		if (config == null || config.isEmpty()) {
			logger.warn("Empty or null configuration. Ignoring.");
			return;
		}

		Set<String> names = getNames(config);

		for (String name : names) {
			
			String value = (String) config.get(name + ".tcpHost");
			String tcpHost = value != null ? value
					: HeaterConfig.DEFAULT_TCP_HOST;

			value = (String) config.get(name + ".tcpPort");
			int tcpPort = value != null ? Integer.valueOf(value)
					: HeaterConfig.DEFAULT_TCP_PORT;
			


			Heater meterConfig = createEgoSmartHeaterConfig(name,
					new HeaterConfig(tcpHost, tcpPort));

			if (heaterDeviceConfigurtions.put(meterConfig.getName(), meterConfig) != null) {
				logger.info("Recreated reader {} with  {}!", meterConfig.getName(),
						meterConfig.getConfig());
			} else {
				logger.info("Created reader {} with  {}!", meterConfig.getName(),
						meterConfig.getConfig());
			}
		}

		if (config != null) {
			// to override the default refresh interval one has to add a
			// parameter to openhab.cfg like
			// <bindingName>:refresh=<intervalInMs>
			if (StringUtils.isNotBlank((String) config.get("refresh"))) {
				refreshInterval = Long
						.parseLong((String) config.get("refresh"));
			}
			setProperlyConfigured(true);
		}
	}

	/**
	 * Analyze configuration to get meter names
	 * 
	 * @return set of String of meter names
	 */
	private Set<String> getNames(Dictionary<String, ?> config) {
		Set<String> set = new HashSet<String>();

		Enumeration<String> keys = config.keys();
		while (keys.hasMoreElements()) {

			String key = (String) keys.nextElement();

			// the config-key enumeration contains additional keys that we
			// don't want to process here ...
			if ("service.pid".equals(key) || "refresh".equals(key)) {
				continue;
			}

			Matcher heaterMatcher = HEATER_CONFIG_PATTERN.matcher(key);

			if (!heaterMatcher.matches()) {
				logger.debug("given config key '"
						+ key
						+ "' does not follow the expected pattern '<meterName>.<serialPort|baudRateChangeDelay|echoHandling>'");
				continue;
			}

			heaterMatcher.reset();
			heaterMatcher.find();

			set.add(heaterMatcher.group(1));
		}
		return set;
	}

}
