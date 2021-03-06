﻿/*
 * 
 * This file is part of the OpenKinect Project. http://www.openkinect.org
 * 
 * Copyright (c) 2010 individual OpenKinect contributors. See the CONTRIB file 
 * for details.
 * 
 * This code is licensed to you under the terms of the Apache License, version 
 * 2.0, or, at your option, the terms of the GNU General Public License, 
 * version 2.0. See the APACHE20 and GPL20 files for the text of the licenses, 
 * or the following URLs:
 * http://www.apache.org/licenses/LICENSE-2.0
 * http://www.gnu.org/licenses/gpl-2.0.txt
 * 
 * If you redistribute this file in source form, modified or unmodified, 
 * you may:
 * 1) Leave this header intact and distribute it under the same terms, 
 * accompanying it with the APACHE20 and GPL20 files, or
 * 2) Delete the Apache 2.0 clause and accompany it with the GPL20 file, or
 * 3) Delete the GPL v2.0 clause and accompany it with the APACHE20 file
 * In all cases you must keep the copyright notice intact and include a copy 
 * of the CONTRIB file.
 * Binary distributions must follow the binary distribution requirements of 
 * either License.
 * 
 */
 
 package org.libfreenect {
	 
	import org.libfreenect.libfreenect;
	import org.libfreenect.events.libfreenectSocketEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * LibFreenectSocket class recieves Kinect data from the libfreenect driver.
	 */
	public class libfreenectSocket extends EventDispatcher
	{
		private static const _images_size:int = 640 * 480 * 4; //614400; //NEEDS DEFINITION (65536 * 9 = 589824) 640 * 480 * 2 = 614400
		private static const _data_size:int = 3 * 2 + 3 * 8;
		private static const _send_size:int = 6;
		//private static var _singleton_lock:Boolean = false;
		private static var _instance:libfreenectSocket;
		private var _packages_received:Number = 0;
		private var packet_size:Number;
		private var socket:Socket;
		private var buffer:ByteArray;
		private var rawPackage:ByteArray;
		private var _port:Number;
		private var byteArray:ByteArray;

		public function libfreenectSocket()
		{
			//if ( !_singleton_lock ) throw new Error( 'Use libfreenectSocket.instance' );
				
			socket = new Socket();
			buffer = new ByteArray();
			rawPackage = new ByteArray();
			
			//Another initialization may be needed here
			
			socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketError);
			socket.addEventListener(Event.CONNECT, onSocketConnect);
		}
		
		//DEFAULT PORT NEEDS DEFINITION
		public function connect(host:String = 'localhost', port:uint = 8000):void
		{
			_port = port;
			packet_size = (_port == 6003) ? _data_size : _images_size;
			if (!this.connected) 
				socket.connect(host, port);
			else
				dispatchEvent(new libfreenectSocketEvent(libfreenectSocketEvent.LIBFREENECT_SOCKET_ONCONNECT, null));
		}
		
		public function get connected():Boolean
		{
			return socket.connected;
		}
		
		public function close():void
		{
			socket.close();
		}
		
		public function sendData(data:ByteArray):int{
			if(data.length == _send_size){
				trace("sendData");
				socket.writeBytes(data, 0, _send_size);
				socket.flush();
				return libfreenect.LIBFREENECT_SUCCESS;
			} else {
				throw new Error( 'Incorrect data size (' + data.length + '). Expected: ' + _send_size);
				return libfreenect.LIBFREENECT_SIZE_ERROR;
			}
		}
		private function onSocketData(event:ProgressEvent):void
		{
			if(socket.bytesAvailable == 237){
				byteArray = new ByteArray();
				socket.readBytes(byteArray, 0, socket.bytesAvailable);
				trace("policy_file : " + byteArray);
			}
			if(socket.bytesAvailable > 0) {
				if(socket.bytesAvailable >= packet_size){
					socket.readBytes(rawPackage, 0, packet_size);
					rawPackage.endian = Endian.LITTLE_ENDIAN;
					rawPackage.position = 0;
					dispatchEvent(new libfreenectSocketEvent(libfreenectSocketEvent.LIBFREENECT_SOCKET_ONDATA, rawPackage));
				}
			}
		}
		
		private function onSocketError(event:IOErrorEvent):void{
			dispatchEvent(new libfreenectSocketEvent(libfreenectSocketEvent.LIBFREENECT_SOCKET_ONERROR, null));
		}
		
		private function onSocketConnect(event:Event):void{
			dispatchEvent(new libfreenectSocketEvent(libfreenectSocketEvent.LIBFREENECT_SOCKET_ONCONNECT, null));
		}

		public function set instance(instance:libfreenectSocket):void 
		{
			throw new Error('libfreenectSocket.instance is read-only');
		}
		
		public static function get instance():libfreenectSocket 
		{
			if ( _instance == null )
			{
				//_singleton_lock = true;
				_instance = new libfreenectSocket();
				//_singleton_lock = false;
			}
			return _instance;
		}
	}
}