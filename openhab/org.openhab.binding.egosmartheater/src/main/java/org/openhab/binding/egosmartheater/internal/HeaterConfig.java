/**
 * Copyright (c) 2010-2015, openHAB.org and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */
package org.openhab.binding.egosmartheater.internal;

/**
 * Class defining the communication configuration parameter for Ego Smart Heater
 * 
 * @author Daniel Haensse
 * @since 1.6.0
 */
public class HeaterConfig {

	// configuration defaults for optional properties
	static final String DEFAULT_TCP_HOST = "";
	static final int DEFAULT_TCP_PORT = 0;

	private final String tcpHost;
	private final int tcpPort;

	public HeaterConfig(String tcpHost, int tcpPort) {
		this.tcpHost = tcpHost;
		this.tcpPort = tcpPort;
	}


	public String getTCPHost() {
		return this.tcpHost;
	}
	
	public int getTCPPort() {
		return this.tcpPort;
	}

	
	@Override
	public String toString() {
		return "EgoSmartHeater DeviceConfig [tcpHost=" + tcpHost
				+ ", tcpPort=" + tcpPort+"]";
	}

}
