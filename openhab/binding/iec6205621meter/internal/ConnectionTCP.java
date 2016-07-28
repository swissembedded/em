/**
 * Copyright (c) 2010-2015, openHAB.org and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */
package org.openhab.binding.iec6205621meter.internal;

import java.io.*;
import java.net.*;
import java.util.ArrayList;
import java.util.List;
import org.openmuc.j62056.DataSet;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This class represents binding to swissEmbedded GmbH EMDO101
 * @author Daniel Haensse
 * @since 1.6.0
 */
public class ConnectionTCP {
	private static Logger logger = LoggerFactory
			.getLogger(ConnectionTCP.class);

	private String tcpHost=null;
	private int tcpPort=0;
	private Socket  tcpSocket = null;	
	private DataInputStream is=null;
	private static final long READ_TIMEOUT = 25000; //25seconds

	public ConnectionTCP(String tcpHost, int tcpPort)  {
		/* Check if params are supplied correctly */
		if (tcpHost == null || tcpPort==0) {
			throw new IllegalArgumentException("tcpHost or tcpPort is undefined");
		}

		this.tcpHost = tcpHost;
		this.tcpPort = tcpPort;
	}
/**
 * 
 */
	public void close() {		
	}
	
	public void open() {
	}



	public List<DataSet> read() throws IOException {
		// open connection
		List<DataSet> dataSets = new ArrayList<DataSet>();
		try {
			tcpSocket=new Socket(tcpHost, tcpPort);
			 is = new DataInputStream(tcpSocket.getInputStream());
		}
		catch (UnknownHostException e) {
			throw new IllegalStateException("Connection is not open");
	    } 
		catch (IOException e) {
			throw new IllegalStateException("Connection is not open");
	    }

		//read device
		if(tcpSocket!=null && is!=null)
		{
			BufferedReader br = new BufferedReader(new InputStreamReader(is));		
			String meterReading;					
			int linecount=0;
			int bracketo, star, bracketc;
			long now=System.currentTimeMillis();
			long timeout=now+READ_TIMEOUT;
			dataSets.add(new DataSet("timestamp",
					""+now, "ms"));
			logger.debug("iec6205621meter connectTCP start reading "+now);
			
			while (System.currentTimeMillis() < timeout) {
				
				/*
				 * EMDO101, pls see manual for configuration of D0Autoread
				 * connection is closed with !CRLF line example: /identifier
				 * 1.8.1(00123.456*kWh) id / value / unit
				 * C.1.0(13647149)
				 * If the D0 interface does not responde, the EMDO101 generates a faked ! end message with a following error keyword
				 */
				if (br.ready()) {					
					if ((meterReading = br.readLine()) != null) {
						logger.debug("iec6205621meter connectTCP line reading "+System.currentTimeMillis()+" "+meterReading);
						if (linecount == 0) {
							// Identifier, special case
							dataSets.add(new DataSet(meterReading.substring(1),
									"", ""));
						} else {
							// Last entry?
							if (meterReading.startsWith("!")) {								
								if(meterReading.contains("error"))
								{
									dataSets.add(new DataSet("status",
											"error", ""));
								}
								else
								{
									dataSets.add(new DataSet("status",
											"ok", ""));
								}
								break;
							}
							// normal line, search for delimiters, if not found, skip dataset
							bracketo = meterReading.indexOf('(');
							star = meterReading.indexOf('*');
							bracketc = meterReading.indexOf(')');
							if ((bracketo >= 0) && (bracketc >= 0)) {
								if(star<0)
								{
									// with units
									dataSets.add(new DataSet(meterReading
												.substring(0, bracketo), meterReading
												.substring(bracketo + 1, bracketc),
												""));
								}
								else
								{
								 // no units
								 dataSets.add(new DataSet(meterReading
										.substring(0, bracketo), meterReading
										.substring(bracketo + 1, star),
										meterReading.substring(star + 1,
												bracketc)));
								}
							}
							
						}
						linecount++;
					} // readline!=null
				} // br.ready 

			} // while
			logger.debug("iec6205621meter connectTCP stop reading "+System.currentTimeMillis());
		} // socket !=null
		
		// if socket is open, close it
		try {
			 tcpSocket.close();
			 tcpSocket = null;
			 is.close();
			 is=null;
		} 
		catch (IOException e) {
			throw new IllegalStateException("Connection close failed");
        }		
		return dataSets;
	}
	
}
	

	
