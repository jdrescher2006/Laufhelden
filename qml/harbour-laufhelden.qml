/*
 * Copyright (C) 2017 Jens Drescher, Germany
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtSensors 5.0 as Sensors
import "pages"
import "tools"
import QtFeedback 5.0
import QtMultimedia 5.0 as Media
import harbour.laufhelden 1.0

ApplicationWindow
{
    id: appWindow

    onApplicationActiveChanged:
    {
        console.log("onApplicationActiveChanged: " + applicationActive);
    }

    //Define global variables

    //*** HRM Start ***
    property bool bHRMConnected: false          //the connection state to the HRM device
    property bool bHRMConnecting: false
    property bool bReconnectHRMDevice: false    //HRM device has lost connection, reconnect
    property bool bRecordDialogRequestHRM: false
    property string sHeartRate: ""
    property string sBatteryLevel: ""    
    property string sHRMAddress: ""
    property string sHRMDeviceName: ""
    property string sHeartRateHexString: ""
    //*** HRM End ***   

    property var vMainPageObject            //this is used for back jumps (pop) to the MainPage
    property bool bLoadHistoryData: true    //this is set on record page after a workout, to have mainpage load GPX files
    property int iVibrationCounter: 0       //this is used for the vibration function
    property bool bPlayerWasPlaying: false     //this is used if playing music needs to be resumed after audio output

    //*** Pebble Start ***
    property bool bPebbleConnected: false
    property bool bPebbleSportAppRequired: false
    property string sPebblePath: ""
    property string sPebbleNameAddress: ""
    //*** Pebble End ***   

    property real rLastAccuracy: -1

    property bool bPlayingSound: false
    property int iPlayLoop: 0
    property variant arrayPlaySounds: 0


    //property bool bApplicationIsActive: fal

    //Init C++ classes, libraries
    HistoryModel{ id: id_HistoryModel }
    BluetoothConnection{ id: id_BluetoothConnection }
    BluetoothData{ id: id_BluetoothData }
    LogWriter{ id: id_LogWriter }
    Settings{ id: settings }
    PlotWidget{ id: id_PlotWidget }
    Light{ id: id_Light }
    PebbleManagerComm{ id: id_PebbleManagerComm }
    PebbleWatchComm{ id: id_PebbleWatchComm }
    TrackRecorder
    {
        id: recorder        
        updateInterval: settings.updateInterval

        onPauseChanged:
        {
            if (!settings.voicePauseContinueWorkout)
                return;

            var sVoiceLanguage = "_en_male.wav";
            //check voice language and generate last part of audio filename
            if (settings.voiceLanguage === 0)        //english male
                sVoiceLanguage = "_en_male.wav";
            else if (settings.voiceLanguage === 1)   //german male
                sVoiceLanguage = "_de_male.wav";


            if (pause)
                fncPlaySound("audio/break_workout" + sVoiceLanguage);
            else
                fncPlaySound("audio/continue_workout" + sVoiceLanguage);
        }

        onRunningChanged:
        {
            if (!settings.voiceStartEndWorkout)
                return;

            var sVoiceLanguage = "_en_male.wav";
            //check voice language and generate last part of audio filename
            if (settings.voiceLanguage === 0)        //english male
                sVoiceLanguage = "_en_male.wav";
            else if (settings.voiceLanguage === 1)   //german male
                sVoiceLanguage = "_de_male.wav";


            if (running)
                fncPlaySound("audio/start_workout" + sVoiceLanguage);
            else
                fncPlaySound("audio/end_workout" + sVoiceLanguage);
        }

        onAccuracyChanged:
        {
            if (!settings.voiceGPSConnectLost)
                return;

            var sVoiceLanguage = "_en_male.wav";
            //check voice language and generate last part of audio filename
            if (settings.voiceLanguage === 0)        //english male
                sVoiceLanguage = "_en_male.wav";
            else if (settings.voiceLanguage === 1)   //german male
                sVoiceLanguage = "_de_male.wav";

            if (accuracy < 30 && accuracy !== -1 && (rLastAccuracy >= 30 || rLastAccuracy === -1))
            {
                fncPlaySound("audio/gps_connected" + sVoiceLanguage);
            }
            if ((accuracy >= 30 || accuracy === -1) && rLastAccuracy < 30 && rLastAccuracy !== -1)
            {
                fncPlaySound("audio/gps_disconnected" + sVoiceLanguage);
            }

            rLastAccuracy = accuracy;
        }
    }

    //These are connections to c++ events
    Connections
    {
        target: id_BluetoothData        
        onSigReadDataReady:     //This is called from C++ if there is data via bluetooth
        {
            fncCheckHeartrate(sData);
        }
        onSigConnected:
        {
            fncShowMessage(2,"HRM Connected", 4000);
            bHRMConnected = true;
        }
        onSigDisconnected:
        {
            fncShowMessage(1,"HRM Disconnected", 4000);
            sHeartRate = "";
            sBatteryLevel = "";
            bHRMConnected = false;
            recorder.vSetCurrentHeartRate(-1);

            //if record dialog is opened, try to reconnect to HRM device
            if (bRecordDialogRequestHRM)
                bReconnectHRMDevice = true;

        }
        onSigError:
        {
            fncShowMessage(3,"HRM Error: " + sError, 10000);
        }
    }

    function fncCheckHeartrate(sData)
    {
        var sHeartRateTemp = 0;
        var sBatteryLevelTemp = 0;
        var iPacketLength = 0;

        //Save received data to packet string. This must be done because a packet is not always consistent.
        sHeartRateHexString = sHeartRateHexString + sData.toLowerCase();

        //console.log("sHeartRateHexString: " + sHeartRateHexString);

        //Check for minimal length
        if (sHeartRateHexString.length < 8)
        {
            //console.log("Packet is too small!");
            return;
        }

        //Search for vaid telegrams
        //Check for Zephyr control characters start and enddelimiter
        //console.log("Header: " + sHeartRateHexString.substr(0,4));
        //console.log("Enddelimiter: " + sHeartRateHexString.substr(sHeartRateHexString.length - 2));

        if (sHeartRateHexString.substr(0,4).indexOf("0226") !== -1 && sHeartRateHexString.substr(sHeartRateHexString.length-2).indexOf("03") !== -1)
        {
            //This should be a Zyphyr packet

            //console.log("Valid Zepyhr HxM data packet found!");

            //Extract length
            iPacketLength = parseInt(sHeartRateHexString.substr(4,2),16);
            //console.log("Length: " + iPacketLength.toString());

            //Extract CRC
            var sCRC = sHeartRateHexString.substr(-4);
            sCRC = sCRC.substr(0,2);
            //console.log("CRC: " + sCRC);

            //Extract heart rate data
            sHeartRateHexString = sHeartRateHexString.substring(6,sHeartRateHexString.length - 4);

            //console.log("HR data: " + sHeartRateHexString);
            //console.log("HR data length: " + sHeartRateHexString.length);

            //Check if length match is given
            if (sHeartRateHexString.length !== (iPacketLength*2))
            {
                //console.log("Length does not match, scrap packet!");
                sHeartRateHexString = "";
                return;
            }

            //Check if data is valid by CRC
            //Man the example is in C )-: do it later...

            //Extract battery level
            sBatteryLevelTemp = (parseInt(sHeartRateHexString.substr(16,2),16)).toString();
            //console.log("Battery level: " + sBatteryLevelTemp);

            //Extract heart rate at byte 12
            sHeartRateTemp = (parseInt(sHeartRateHexString.substr(18,2),16)).toString();
            //console.log("Heartrate: " + sHeartRateTemp);

            //If we found a valid packet, delete the packet memory string
            sHeartRateHexString = "";
        }
        else if (sHeartRateHexString.substr(0,2).indexOf("fe") !== -1)
        {
            //This should be a POLAR packet

            //Check if packet is at correct length
            iPacketLength = parseInt(sHeartRateHexString.substr(2,2), 16);
            //console.log("iPacketLength: " + iPacketLength);
            if (sHeartRateHexString.length < (iPacketLength * 2))
            {
                sHeartRateHexString = "";
                return; //Packet is not big enough
            }
            //Check check byte, 255 - packet length
            var iCheckByte = parseInt(sHeartRateHexString.substr(4,2), 16);
            //console.log("iCheckByte: " + iCheckByte);
            if (iCheckByte !== (255 - iPacketLength))
            {
                sHeartRateHexString = "";
                //console.log("Check byte is not valid!");
                return; //Check byte is not valid
            }
            //Check sequence valid
            var iSequenceValid = parseInt(sHeartRateHexString.substr(6,2), 16);
            //console.log("iSequenceValid: " + iSequenceValid);
            if (iSequenceValid >= 16)
            {
                sHeartRateHexString = "";
                return; //Sequence valid byte is not valid
            }

            //Check status byte
            var iStatus = parseInt(sHeartRateHexString.substr(8,2), 16);
            //console.log("iStatus: " + iStatus);
            //Check battery state
            sBatteryLevelTemp = parseInt(sHeartRateHexString.substr(8,1), 16);
            //console.log("iBattery: " + sBatteryLevelTemp);
            //Extract heart rate
            sHeartRateTemp = (parseInt(sHeartRateHexString.substr(10,2), 16)).toString();
            //console.log("HeartRateTemp: " + sHeartRateTemp);

            var sTemp = ((100/15) * sBatteryLevelTemp).toString();
            if (sTemp.indexOf(".") != -1)
                sTemp = sTemp.substring(0, sTemp.indexOf("."));
            sBatteryLevelTemp = sTemp;

            //Extraction was successful here. Reset message text var.
            //Only kill the bytes for this packet. There might be more bytes after this packet.
            if (sHeartRateHexString.length > (iPacketLength * 2))
            {
                sHeartRateHexString = sHeartRateHexString.substring((iPacketLength * 2));
                //console.log("Found additional data: " + sHeartRateHexString);
                fncCheckHeartrate("");
            }
            else
                sHeartRateHexString = "";
        }
        else
        {
            //We have a strange start delimiter. Kill data...
            //console.log("Strange data found. Kill data.");
            sHeartRateHexString = "";
        }


        //Send heart rate to trackrecorderiHeartRate so that it can be included into the gpx file.
        recorder.vSetCurrentHeartRate(parseInt(sHeartRateTemp));

        sHeartRate = sHeartRateTemp;
        sBatteryLevel = sBatteryLevelTemp;
    }


    function fncShowMessage(iType ,sMessage, iTime)
    {
        messagebox.showMessage(iType, sMessage, iTime);
    }

    Sensors.OrientationSensor
    {
        id: rotationSensor
        active: true
        property int angle: reading.orientation ? _getOrientation(reading.orientation) : 0
        function _getOrientation(value)
        {
            switch (value)
            {
                case 2:
                    return 180
                case 3:
                    return -90
                case 4:
                    return 90
                default:
                    return 0
            }
        }
    }

    Messagebox
    {
        id: messagebox
        rotation: rotationSensor.angle
        width: Math.abs(rotationSensor.angle) == 90 ? parent.height : parent.width
        Behavior on rotation { SmoothedAnimation { duration: 500 } }
        Behavior on width { SmoothedAnimation { duration: 500 } }
    }

    Timer
    {
        //This is called if the connection to the HRM device is broken
        id: timReconnectHRMdevice
        interval: 2000
        running: bReconnectHRMDevice
        repeat: false
        onTriggered:
        {
            //console.log("Timer for HRM reconnection is running.");

            id_BluetoothData.connect(sHRMAddress, 1);

            bReconnectHRMDevice = false;
        }
    }

    Timer
    {
        //This is called if the connection to the HRM device is broken
        id: timVibrationTimer
        interval: 1000
        running: iVibrationCounter > 0
        repeat: iVibrationCounter > 0
        onTriggered:
        {
            vibrateEffect.start();
            iVibrationCounter--;
        }
    }

    //iVibrationCount: amount of vibrations in series
    //iVibrationSpeed: duration of vibrations and pause between the vibrations
    function fncVibrate(iVibrationCount, iVibrationDuration)
    {
        //if there is a vibration process running, return
        if (iVibrationCounter !== 0 || iVibrationCount === 0 || iVibrationDuration === 0)
            return;

        vibrateEffect.duration = iVibrationDuration;
        timVibrationTimer.interval = (iVibrationDuration * 2);

        //Start first vibration
        vibrateEffect.start();

        iVibrationCount--;

        if (iVibrationCount === 0)
            return;

        //Start timer because we need some more vibrations
        iVibrationCounter = iVibrationCount;
    }

    HapticsEffect
    {
        id: vibrateEffect
        intensity: 1
        duration: 200
    }

    function fncEnableScreenBlank(bEnableScreenBlank)
    {
        screenblank.enabled = bEnableScreenBlank;
    }

    ScreenBlank
    {
        id: screenblank
    }

    MediaPlayerControl
    {
       id: mediaPlayerControl
    }

    PebbleComm
    {
        id: pebbleComm
    }

    Media.Audio
    {
        id: playSoundEffect
        source: "audio/hr_toohigh_de_male.wav"

        onPlaybackStateChanged:
        {
            //console.log("onPlaybackStateChanged: " + playbackState.toString());

            //Check if playing a sound is done.
            if (playbackState == 0)
            {
                //Set index to next sound in array
                iPlayLoop++;

                //console.log("iPlayLoop: " + iPlayLoop.toString());

                //Check if we are ready with playing sounds, all sounds in the array were played.
                if (arrayPlaySounds.length === 0 || iPlayLoop >= arrayPlaySounds.length)
                {
                    //Check if the system audio player was playing before
                    if (bPlayerWasPlaying)
                    {
                        //Resume system audio player
                        mediaPlayerControl.resume();
                    }

                    //We are done now with playing sounds. Mark that.
                    bPlayingSound = false;

                    //console.log("onPlayingChanged, the END!");
                }
                else
                {
                    //There is still something to play in the array. Restart play timer.
                    timerPlaySoundArray.start();

                    //console.log("onPlayingChanged, starting timer!");
                }
            }
        }
    }

    //This is not used because the onPlayingChanged often times is not fired after an audio file is played
    Media.SoundEffect
    {
        id: playSoundEffect2
        source: "audio/hr_toohigh_de_male.wav"
        volume: 1.0; //Full 1.0
        onPlayingChanged:
        {
            //console.log("onPlayingChanged: " + playing.toString());

			//Check if playing a sound is done.
			if (playing == false)
            {
				//Set index to next sound in array
                iPlayLoop++;
	
                //console.log("iPlayLoop: " + iPlayLoop.toString());

				//Check if we are ready with playing sounds, all sounds in the array were played.			
				if (arrayPlaySounds.length === 0 || iPlayLoop >= arrayPlaySounds.length)
				{
					//Check if the system audio player was playing before
					if (bPlayerWasPlaying)
					{
						//Resume system audio player
					    mediaPlayerControl.resume();
					}

					//We are done now with playing sounds. Mark that.
					bPlayingSound = false;

                    //console.log("onPlayingChanged, the END!");
				}
				else
				{
					//There is still something to play in the array. Restart play timer.
                    timerPlaySoundArray.start();

                    //console.log("onPlayingChanged, starting timer!");
				}				
			}
        }
    }    

    function fncPlaySoundArray(arraySoundArray)
    {
        //Check if a sound is already playing. If so, return!
        if (bPlayingSound)
            return;
        else
            bPlayingSound = true;

		//detect if SFOS music player is currently playing
        if (mediaPlayerControl.getPlayerStatus() === "Playing")
        {
            bPlayerWasPlaying = true;
            mediaPlayerControl.pause();
        }
        else
            bPlayerWasPlaying = false;

        arrayPlaySounds = arraySoundArray;

        iPlayLoop = 0;
        playSoundEffect.source = arrayPlaySounds[iPlayLoop];
        playSoundEffect.play();
    }

    Timer
    {
        id: timerPlaySoundArray
        running: false
        repeat: false
        interval: 75
        onTriggered:
        {
            //console.log("timerPlaySoundArray: " + iPlayLoop.toString());

            playSoundEffect.source = arrayPlaySounds[iPlayLoop];
            playSoundEffect.play();
        }
    }

	function fncPlaySound(sFile)
    {
        //Check if a sound is already playing. If so, return!
        if (bPlayingSound)
            return;
        else
            bPlayingSound = true;

		var arTemp = [];
		arrayPlaySounds = arTemp;
        iPlayLoop = 0;

        //detect if SFOS music player is currently playing
        if (mediaPlayerControl.getPlayerStatus() === "Playing")
        {
            bPlayerWasPlaying = true;
            mediaPlayerControl.pause();
        }
        else
            bPlayerWasPlaying = false;

        playSoundEffect.source = sFile;
        playSoundEffect.play();
    }
         
    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All
}
