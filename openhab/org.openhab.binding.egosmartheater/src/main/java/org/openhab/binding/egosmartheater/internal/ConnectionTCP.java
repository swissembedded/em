/**
 * Copyright (c) 2010-2015, openHAB.org and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */
package org.openhab.binding.egosmartheater.internal;

import java.io.*;
import java.net.*;
import java.util.ArrayList;
import java.util.List;

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
	private DataOutputStream os=null;
	private static final long READ_TIMEOUT = 5000; //5seconds
	private static final int MIN_POWER = -30000;
	private static final int MAX_POWER = 30000;
	private int heatingPower = 0;
	private int heatingStage=0;
	private int waterTemperature=0;
	private int userTemperature=0;
	private long timeStamp=0;	
	
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


/*
 * EMDO101 configuration 19200, 8bits, parity even, 1 stopbit
 * Init procedure:
 * Check device id is correct:
 * addr 0x2000 equals value 0x14ef, func code 3
 * addr 0x2001 equals value 0xebaf, func code 3
 * addr 0x2002 equals value 0x0001, func code 3
 * 
 * configure registers
 * addr 0x1300 to value 0xffff, func code 6 
 * set power
 * addr 0x1301 to value negative power value, func code 6
 * 
 * read heating power
 * addr 0x1408 range 0x0000 to 0x0007 (3 heating power stages), func code 3
 * read temperature
 * addr 0x1404 water temperature, func code 3
 */
	public List<DataSet> read(int regulatePower, boolean regulateState) throws IOException {
		
		// open connection
		List<DataSet> dataSets = new ArrayList<DataSet>();
		try {
			tcpSocket=new Socket(tcpHost, tcpPort);
			 is = new DataInputStream(tcpSocket.getInputStream());
			 os = new DataOutputStream(tcpSocket.getOutputStream());
		}
		catch (UnknownHostException e) {
			closeConnection();
			throw new IllegalStateException("Connection is not open");			 
	    } 
		catch (IOException e) {
			closeConnection();
			throw new IllegalStateException("Connection is not open");
	    }

		//read device
		if(tcpSocket!=null && is!=null && os!=null)
		{			
			logger.debug("egosmartheater connectTCP start reading");			
			// check Manufacturer ID, Product ID and Product Version, that keeps the ego smart heater communication running
			int manufacturerId=readRegister16(0x2000);
			int productId=readRegister16(0x2001);
			int variantId=readRegister16(0x2002);
			int firmwareVersion=readRegister16(0x2003);
			if(manufacturerId==0x14ef && (productId==0xff37 || productId==0xebaf) && (variantId==0x0000))
			{
				/* calculate time from last iteration to the current */
				if(regulateState)
				{
					/* 5 minutes are over */
					timeStamp=System.currentTimeMillis();
					logger.debug("egosmartheater regulation control " + timeStamp);
					// Configure the regulator
					writeRegister16(0x1300,0xffff);
					int rP=regulatePower;
					if(rP <0)
					{
						if(rP < MIN_POWER) rP=MIN_POWER;
						// value <0.0 means house is sourcing to power grid
						writeRegister32(0x1301,0x100000000L+rP); 
					}
					else
					{
						if(rP > MAX_POWER) rP=MAX_POWER;
						// value >0.0 means house is sinking from power grid
						writeRegister32(0x1301,rP); 
					}
				}
				else
				{
					// hold regulator in the current state
					writeRegister16(0x1300,0xffff);
					writeRegister32(0x1301,0); 
				}
				heatingStage=readRegister16(0x1408);
				waterTemperature=readRegister16(0x1404);				
				userTemperature=readRegister16(0x1407);
			}
			logger.debug("egosmartheater connectTCP stop reading");
			dataSets.add(new DataSet("regulatePower",""+regulatePower));
			dataSets.add(new DataSet("heatingStage",""+heatingStage));			
			dataSets.add(new DataSet("waterTemperature",""+waterTemperature));
			dataSets.add(new DataSet("userTemperature",""+userTemperature));
			dataSets.add(new DataSet("heatingPowerk",""+((float)heatingStage*500.0/1000.0)));
			dataSets.add(new DataSet("heatingPower",""+(heatingStage*500)));
			dataSets.add(new DataSet("timeStamp",""+timeStamp));						
		} // socket !=null
		
		// if socket is open, close it
		try {
			closeConnection();
		} 
		catch (IOException e) {			
			throw new IllegalStateException("Connection close failed");
        }		
		return dataSets;
	}

	private void closeConnection() throws IOException
	{		
		if(is!=null) is.close();
		if(os!=null) os.close();
		if(tcpSocket!=null) tcpSocket.close();
		tcpSocket = null;
		is=null;
		os=null;
	}
	
	private void writeRegister16(int addr,int data)  throws IOException
	{
		// RTU master frame start slave address (1byte 0xf7), function code (1byte 0y06), addr (2byte), data (2 bytes), crc (2 bytes)
		// RTU slave  frame start slave address (1byte 0xf7), function code (1byte 0x86), addr (2byte), reg (2bytes), crc (2 bytes)
		byte [] message ={
				          (byte) 0xf7 /*slave address */, 0x06 /*function code */, 
				          0x00 /*addr hi*/, 0x00/*addr lo*/, 
				          0x00 /*data hi*/, 0x00/*data lo*/, 
				          0x00 /*crc hi*/,  0x00/*crc lo*/};		
		// skip any available data from input buffer
		BufferedReader br = new BufferedReader(new InputStreamReader(is));	
		while(br.ready()) br.read();
		// write single register
		message[2]=(byte) ((addr >> 8) & 0xFF);
		message[3]=(byte) (addr & 0xFF);   
		message[4]=(byte) ((data >> 8) & 0xFF);
		message[5]=(byte) (data & 0xFF);   
		int crc=calcCRC(message,0,5);
		message[6]=(byte) ((crc >> 8) & 0xFF);
		message[7]=(byte) (crc & 0xFF);
		os.write(message, 0, 8);
		os.flush();
		logger.debug("write register request size 8:"+convertToHexString(message,8));
		
		// read response
		long now=System.currentTimeMillis();
		long timeout=now+READ_TIMEOUT;
		int index=0;
		while (System.currentTimeMillis() < timeout) 
		{
			if(br.ready()) 
			{
				message[index]=(byte) (br.read() &0xff);
				index++;
			}
			if(index==8) break;
		}
		logger.debug("write register response size "+index+":"+convertToHexString(message,index));
		crc=(((int)message[6]&0xff)<<8)|((int)message[7]&0xff);
		int adr=(((int)message[2]&0xff)<<8)|((int)message[3]&0xff);
		int dta=(((int)message[4]&0xff)<<8)|((int)message[5]&0xff);
		if( (message[0]!=(byte)0xf7) || (message[1]!=0x06) || (adr!=addr) || (dta!=data))
		{
			throw new IllegalStateException("Modbus response is illegal writing address "+addr+" data"+data);
		}		
		int ccrc=calcCRC(message,0,5);
		if(ccrc!=crc)
		{
			logger.debug("write register crc error received "+crc+" calculated "+ccrc);
		}
		
	}

	private void writeRegister32(int addr,long data)  throws IOException
	{
		// RTU master frame start slave address (1byte 0xf7), function code (1byte 0y06), addr (2byte), no regs (2byte), byte count (1byte), data (4 bytes), crc (2 bytes)
		// RTU slave  frame start slave address (1byte 0xf7), function code (1byte 0x86), addr (2byte), no regs (2bytes), crc (2 bytes)
		byte [] message ={
				          (byte) 0xf7 /*slave address */, 0x10 /*function code */, 
				          0x00 /*addr hi*/, 0x00/*addr lo*/,
				          0x00 /*no regs hi */, 0x02 /* no regs lo */,
				          0x04 /* byte count */,
				          0x00 /*data hi*/, 0x00/*data */, 
				          0x00 /*data */, 0x00/*data lo*/,
				          0x00 /*crc hi*/,  0x00/*crc lo*/};		
		// skip any available data from input buffer
		BufferedReader br = new BufferedReader(new InputStreamReader(is));	
		while(br.ready()) br.read();
		// write single register
		message[2]=(byte) ((addr >> 8) & 0xFF);
		message[3]=(byte) (addr & 0xFF);   
		message[7]=(byte) ((data >> 24) & 0xFF);
		message[8]=(byte) ((data >> 16) & 0xFF);
		message[9]=(byte) ((data >> 8) & 0xFF);
		message[10]=(byte) (data & 0xFF);   

		int crc=calcCRC(message,0,10);
		message[11]=(byte) ((crc >> 8) & 0xFF);
		message[12]=(byte) (crc & 0xFF);
		os.write(message, 0, 13);
		os.flush();
		logger.debug("write register request size 13:"+convertToHexString(message,13));
		
		// read response
		long now=System.currentTimeMillis();
		long timeout=now+READ_TIMEOUT;
		int index=0;
		while (System.currentTimeMillis() < timeout) 
		{
			if(br.ready()) 
			{
				message[index]=(byte) (br.read() &0xff);
				index++;
			}
			if(index==8) break;
		}
		logger.debug("write register response size "+index+":"+convertToHexString(message,index));
		crc=(((int)message[6]&0xff)<<8)|((int)message[7]&0xff);
		int adr=(((int)message[2]&0xff)<<8)|((int)message[3]&0xff);		
		if( (message[0]!=(byte)0xf7) || (message[1]!=0x10) || message[4]!=0x00 || message[5]!=0x02 || (adr!=addr))
		{
			throw new IllegalStateException("Modbus response is illegal writing address "+addr+" data"+data);
		}		
		int ccrc=calcCRC(message,0,5);
		if(ccrc!=crc)
		{
			logger.debug("write register crc error received "+crc+" calculated "+ccrc);
		}
		
	}

	private int readRegister16(int addr) throws IOException
	{
		// RTU master frame start slave address (1byte 0xf7), function code (1byte), addr (2byte), data (2 bytes), crc (2 bytes)
		// RTU slave  frame start slave address (1byte 0xf7), function code (1byte 0x83), bytecount (1 byte must be 0x02), data (2 bytes), crc (2 bytes)
		byte [] message ={
				 (byte) 0xf7 /*slave address */, 
				  0x03 /*function code */, 
		          0x00 /*addr hi*/, 0x00 /*addr lo*/, 
		          0x00 /*number hi*/, 0x01 /*number lo*/, 
		          0x00 /*crc hi*/,  0x00 /*crc lo*/};
		// skip any available data from input buffer
		BufferedReader br = new BufferedReader(new InputStreamReader(is));	
		while(br.ready()) br.read();
		// read multiple
		message[2]=(byte) ((addr >> 8) & 0xFF);
		message[3]=(byte) (addr & 0xFF);   
		int crc=calcCRC(message,0,5);
		message[6]=(byte) ((crc >> 8) & 0xFF);
		message[7]=(byte) (crc & 0xFF);   
		os.write(message, 0, 8);
		os.flush();
		logger.debug("read register request size 8:"+convertToHexString(message,8));
		// read response we receive start token, payload, end token
		long now=System.currentTimeMillis();
		long timeout=now+READ_TIMEOUT;
		int index=0;
		while (System.currentTimeMillis() < timeout) 
		{
			if(br.ready()) 
			{
				message[index]=(byte) (br.read() &0xff);
				index++;
			}
			if(index==7) break;
		}
		logger.debug("read register response size "+index+":" + convertToHexString(message,index));
		crc=(((int)message[5]&0xff)<<8)|((int)message[6]&0xff);
		if( (message[0]!=(byte)0xf7) || (message[1]!=0x03) || (message[2]!=0x02))
		{
			throw new IllegalStateException("Modbus response is illegal reading address "+addr);
		}	
		int ccrc=calcCRC(message,0,4);
		if(ccrc!=crc)
		{
			logger.debug("read register crc error received "+crc+" calculated "+ccrc);
		}
		int ret= (( (int)message[3]&0xff)<<8 ) |( (int)message[4]&0xff );
		logger.debug("read register response data:" + ret);
		return(ret);
	}
	
	
	private static final int calcCRC(byte[] data, int start, int end) {
		// See modbus overall serial line specification implementation guide
		// v1.0 page 39 for reference
		int[] uchcrc = { 0xFF, 0xFF };
		int calcByte = 0;
		int uIndex;
		for (int idx = start; (idx <= end) && (idx < data.length); idx++) {
			calcByte = 0xFF & ((int) data[idx]);
			uIndex = uchcrc[0] ^ calcByte;
			uchcrc[0] = uchcrc[1] ^ auchCRCHi[uIndex];
			uchcrc[1] = auchCRCLo[uIndex];
		}
		return((((int) uchcrc[0]&0xff)<<8)|((int)uchcrc[1]&0xff));
	}

	/* Table of CRC values for high-order byte */
	private final static short[] auchCRCHi = { 
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81,
		0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
		0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01,
		0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81,
		0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
		0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01,
		0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81,
		0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
		0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01,
		0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
		0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81,
		0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
		0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01,
		0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81,
		0x40 };

	/* Table of CRC values for low-order byte */
	private final static short[] auchCRCLo = { 
		0x00, 0xC0, 0xC1, 0x01, 0xC3, 0x03, 0x02, 0xC2, 0xC6, 0x06, 0x07, 0xC7, 0x05, 0xC5, 0xC4,
		0x04, 0xCC, 0x0C, 0x0D, 0xCD, 0x0F, 0xCF, 0xCE, 0x0E, 0x0A, 0xCA, 0xCB, 0x0B, 0xC9, 0x09,
		0x08, 0xC8, 0xD8, 0x18, 0x19, 0xD9, 0x1B, 0xDB, 0xDA, 0x1A, 0x1E, 0xDE, 0xDF, 0x1F, 0xDD,
		0x1D, 0x1C, 0xDC, 0x14, 0xD4, 0xD5, 0x15, 0xD7, 0x17, 0x16, 0xD6, 0xD2, 0x12, 0x13, 0xD3,
		0x11, 0xD1, 0xD0, 0x10, 0xF0, 0x30, 0x31, 0xF1, 0x33, 0xF3, 0xF2, 0x32, 0x36, 0xF6, 0xF7,
		0x37, 0xF5, 0x35, 0x34, 0xF4, 0x3C, 0xFC, 0xFD, 0x3D, 0xFF, 0x3F, 0x3E, 0xFE, 0xFA, 0x3A,
		0x3B, 0xFB, 0x39, 0xF9, 0xF8, 0x38, 0x28, 0xE8, 0xE9, 0x29, 0xEB, 0x2B, 0x2A, 0xEA, 0xEE,
		0x2E, 0x2F, 0xEF, 0x2D, 0xED, 0xEC, 0x2C, 0xE4, 0x24, 0x25, 0xE5, 0x27, 0xE7, 0xE6, 0x26,
		0x22, 0xE2, 0xE3, 0x23, 0xE1, 0x21, 0x20, 0xE0, 0xA0, 0x60, 0x61, 0xA1, 0x63, 0xA3, 0xA2,
		0x62, 0x66, 0xA6, 0xA7, 0x67, 0xA5, 0x65, 0x64, 0xA4, 0x6C, 0xAC, 0xAD, 0x6D, 0xAF, 0x6F,
		0x6E, 0xAE, 0xAA, 0x6A, 0x6B, 0xAB, 0x69, 0xA9, 0xA8, 0x68, 0x78, 0xB8, 0xB9, 0x79, 0xBB,
		0x7B, 0x7A, 0xBA, 0xBE, 0x7E, 0x7F, 0xBF, 0x7D, 0xBD, 0xBC, 0x7C, 0xB4, 0x74, 0x75, 0xB5,
		0x77, 0xB7, 0xB6, 0x76, 0x72, 0xB2, 0xB3, 0x73, 0xB1, 0x71, 0x70, 0xB0, 0x50, 0x90, 0x91,
		0x51, 0x93, 0x53, 0x52, 0x92, 0x96, 0x56, 0x57, 0x97, 0x55, 0x95, 0x94, 0x54, 0x9C, 0x5C,
		0x5D, 0x9D, 0x5F, 0x9F, 0x9E, 0x5E, 0x5A, 0x9A, 0x9B, 0x5B, 0x99, 0x59, 0x58, 0x98, 0x88,
		0x48, 0x49, 0x89, 0x4B, 0x8B, 0x8A, 0x4A, 0x4E, 0x8E, 0x8F, 0x4F, 0x8D, 0x4D, 0x4C, 0x8C,
		0x44, 0x84, 0x85, 0x45, 0x87, 0x47, 0x46, 0x86, 0x82, 0x42, 0x43, 0x83, 0x41, 0x81, 0x80,
		0x40 };
	
	private static String convertToHexString(byte[] data, int num) {
		StringBuffer buf = new StringBuffer();
		for (int i = 0; i < data.length; i++) {
			if(i==num) break;
			int halfbyte = (data[i] >>> 4) & 0x0F;
			int two_halfs = 0;
			do {
				if ((0 <= halfbyte) && (halfbyte <= 9))
					buf.append((char) ('0' + halfbyte));
				else
					buf.append((char) ('a' + (halfbyte - 10)));
				halfbyte = data[i] & 0x0F;				
			} while (two_halfs++ < 1);			
		}
		return buf.toString();
	}

}
	

	
