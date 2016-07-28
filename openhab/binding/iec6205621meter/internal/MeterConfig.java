/**
 * Copyright (c) 2010-2015, openHAB.org and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */
package org.openhab.binding.iec6205621meter.internal;

/**
 * Class defining the communication configuration parameter for metering device
 * 
 * @author Peter Kreutzer
 * @author Günter Speckhofer
 * @author Daniel Haensse
 * @since 1.5.0
 */
public class MeterConfig {

	// configuration defaults for optional properties
	static final int DEFAULT_BAUD_RATE_CHANGE_DELAY = 0;
	static final boolean DEFAULT_ECHO_HANDLING = true;
	static final String DEFAULT_SERIAL_PORT = "";
	static final String DEFAULT_TCP_HOST = "";
	static final int DEFAULT_TCP_PORT = 0;

	private final String serialPort;
	private final int baudRateChangeDelay;
	private final boolean echoHandling;
	private final String tcpHost;
	private final int tcpPort;

	public MeterConfig(String serialPort, String tcpHost, int tcpPort, int baudRateChangeDelay,
			boolean echoHandling) {
		this.serialPort = serialPort;
		this.tcpHost = tcpHost;
		this.tcpPort = tcpPort;
		this.baudRateChangeDelay = baudRateChangeDelay;
		this.echoHandling = echoHandling;
	}

	public String getSerialPort() {
		return this.serialPort;
	}

	public int getBaudRateChangeDelay() {
		return this.baudRateChangeDelay;
	}

	public boolean getEchoHandling() {
		return this.echoHandling;
	}

	public String getTCPHost() {
		return this.tcpHost;
	}
	
	public int getTCPPort() {
		return this.tcpPort;
	}

	
	@Override
	public String toString() {
		return "IEC 62056-21Meter DeviceConfig [serialPort=" + serialPort
				+ ", tcpHost=" + tcpHost
				+ ", tcpPort=" + tcpPort
				+ ", baudRateChangeDelay=" + baudRateChangeDelay
				+ ", echoHandling=" + echoHandling + "]";
	}

}
