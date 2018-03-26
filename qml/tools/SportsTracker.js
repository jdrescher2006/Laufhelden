/*
 * Copyright (C) 2017 Jussi Nieminen, Finland
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

var SESSIONKEY = ""; //Sessionkey is filled automatically after login.
var loginurl = "https://www.sports-tracker.com/apiserver/v1/login";
var importurl = "https://www.sports-tracker.com/apiserver/v1/workout/importGpx";
var saveurl = "https://www.sports-tracker.com/apiserver/v1/workouts/header";
var workoutsurl = "https://www.sports-tracker.com/apiserver/v1/workouts";
var exportgpxurl = "https://www.sports-tracker.com/apiserver/v1/workout/exportGpx/";
var recycledlogin = false;
var loginstate = 0;
var writecallback;        //Write file to disk callback which is called after download
var downloadDoneCallback; //This is called when all downloads are done
var maxdownloadcount = 100;

var existingkeys = []; //Array of already downloaded workout keys.
var keys = []; //array of Sports-Tracker workout keys and timestamps
var numofitems = 0;
var currentitem = 0;
var stComment = "";
var stSharing = 0;

/*
    Decode SportsTracker sharing options to List index values
    These are used in Settings and Sharing pages.
    There are some missing values which may be related to Twitter and Facebook.
*/
function sharingOptionToIndex(option){
    switch (option) {
        case 0: return 0
        case 17: return 1
        case 19: return 2
        default: return 0
    }
}

/*
    Login to Sports-Tracker.com using given username and password. Successfull login sets SESSSIONKEY -global variable.
    After login This function calls Callback -function without any parameters.
*/
function loginSportsTracker(callback, notificationcallback, username, password){
    console.log("loginSportsTracker called");
    var xmlhttp = new XMLHttpRequest();
    xmlhttp.open("POST", loginurl);
    xmlhttp.setRequestHeader('Accept-Encoding', 'text');
    xmlhttp.setRequestHeader('Connection', 'keep-alive');
    xmlhttp.setRequestHeader('Pragma', 'no-cache');
    xmlhttp.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xmlhttp.setRequestHeader('Accept', 'application/json, text/plain, */*');
    xmlhttp.setRequestHeader('Cache-Control', 'no-cache');

    xmlhttp.onreadystatechange=function(){
        if (xmlhttp.readyState==4 && xmlhttp.status==200){
            var loginresponse = JSON.parse(xmlhttp.responseText);
            if (loginresponse["error"] === undefined){
                SESSIONKEY = loginresponse["sessionkey"];
                callback(); //Call function when request is ready
            }
            else{
                console.log(xmlhttp.responseText);
            }
        }
        else if (xmlhttp.readyState==4 && xmlhttp.status!=200){
            notificationcallback(qsTr("Oops, username or password error"),"error", 3000);
            console.log(xmlhttp.responseText);
        }
    };
    console.log("Sending login request");
    xmlhttp.send("l="+username+"&p="+password);
}

/*
    Imports given GPXcontent to Sports-tracker server. After import this function is calling SaveExercise
*/
function importGPX(gpxcontent, notificationcallback, sharing, comment){
    if (SESSIONKEY == ""){
        console.log("Sports-Tracker.com SESSIONKEY empty. please login before POST");
        return;
    }

    var xmlhttp = new XMLHttpRequest();
    var boundary = "--------------" + (new Date).getTime();

    xmlhttp.open("POST", importurl);
    xmlhttp.setRequestHeader('Accept-Encoding', 'text');
    xmlhttp.setRequestHeader('Connection', 'keep-alive');
    xmlhttp.setRequestHeader('Pragma', 'no-cache');
    xmlhttp.setRequestHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
    xmlhttp.setRequestHeader('Accept', 'application/json, text/plain, */*');
    xmlhttp.setRequestHeader('Cache-Control', 'no-cache');
    xmlhttp.setRequestHeader('STTAuthorization', SESSIONKEY);

    xmlhttp.onreadystatechange=function(){
        if (xmlhttp.readyState==4 && xmlhttp.status==200){
            //console.log(xmlhttp.responseText); //,codeapp);
            var postresponse = JSON.parse(xmlhttp.responseText);
            if (postresponse["error"] === null){
                var data = [{ "totalDistance":postresponse["payload"]["totalDistance"],
                              "workoutKey": postresponse["payload"]["workoutKey"],
                              "activityId": postresponse["payload"]["activityId"],
                              "startTime": postresponse["payload"]["startTime"],
                              "totalTime": postresponse["payload"]["totalTime"],
                              "description": comment.length === 0 ? "laufhelden upload" : comment,
                              "energyConsumption":postresponse["payload"]["energyConsumption"],
                              "sharingFlags": sharing //Sharing flags: 0=private, 19=public, 17=Followers
                            }];
                saveExercise(data, notificationcallback);
            }
            else{
                console.log(xmlhttp.responseText);
                console.log("GPX Import error, cannot save exercise");
            }
        }
        else if (xmlhttp.readyState==4 && xmlhttp.status!=200){
            console.log(xmlhttp.responseText);
            console.log("Some kind of error happened");
            notificationcallback(qsTr("Some kind of error happened on GPX import"),"error", 3000);
        }
    };

    var  part ="";
    part += 'Content-Disposition: form-data; ';
    part += 'name="' + 'file' + '"; ';
    part += 'filename="'+ "exercise.gpx" +  '";\r\n';

    part += "Content-Type: application/gpx+xml";
    part += "\r\n\r\n"; // marks end of the headers part
    part += gpxcontent;
    var request = "--" + boundary + "\r\n";
    request += part+"\r\n"
    request += "--" + boundary + "--" + "\r\n";
    xmlhttp.send(request);
}

/*
    Saves exercise data to Sports-Tracker server. This can be used to modify existing workouts.
    data input is telling what workout is modified and how.
    Example of data array/map can be found from importGPX function.
*/
function saveExercise(data, notificationcallback){
    if (SESSIONKEY == ""){
        console.log("Sports-Tracker.com SESSIONKEY empty. please login before POST");
        return;
    }
    var xmlhttp = new XMLHttpRequest();
    xmlhttp.open("POST", saveurl);
    xmlhttp.setRequestHeader('Accept-Encoding', 'text');
    xmlhttp.setRequestHeader('Connection', 'keep-alive');
    xmlhttp.setRequestHeader('Pragma', 'no-cache');
    xmlhttp.setRequestHeader('Content-Type', 'application/json');
    xmlhttp.setRequestHeader('Accept', 'application/json, text/plain, */*');
    xmlhttp.setRequestHeader('Cache-Control', 'no-cache');
    xmlhttp.setRequestHeader('STTAuthorization', SESSIONKEY);

    xmlhttp.onreadystatechange=function(){
        if (xmlhttp.readyState==4 && xmlhttp.status==200){
            var postresponse = JSON.parse(xmlhttp.responseText);
            if (postresponse["error"] === null){
                console.log("Send was success");
                notificationcallback(qsTr("Workout uploaded!"),"success", 3000);
            }
            else{
                console.log(xmlhttp.responseText);
                console.log("Error happened");
            }
            console.log(xmlhttp.responseText); //,codeapp);
        }
        else if (xmlhttp.readyState==4 && xmlhttp.status!=200){
            console.log(xmlhttp.responseText);
            console.log("Some kind of error happened");
            notificationcallback(qsTr("Some kind of error happened on Saving data"),"error", 3000);
        }
    };
    xmlhttp.send(JSON.stringify(data));
}


/*
    Reads all exercices from Sports-Tracker.com and exports them to Local disk in GPX -format
*/
function loadWorkouts(){
    if (SESSIONKEY == ""){
        console.log("Sports-Tracker.com SESSIONKEY empty. please login before POST");
        return;
    }
    var xmlhttp = new XMLHttpRequest();
    xmlhttp.open("GET", workoutsurl+ "?sortonst=true&limit="+maxdownloadcount+"&offset=0");
    xmlhttp.setRequestHeader('Accept-Encoding', 'text');
    xmlhttp.setRequestHeader('Connection', 'keep-alive');
    xmlhttp.setRequestHeader('Pragma', 'no-cache');
    xmlhttp.setRequestHeader('Content-Type', 'application/json');
    xmlhttp.setRequestHeader('Accept', 'application/json, text/plain, */*');
    xmlhttp.setRequestHeader('Cache-Control', 'no-cache');
    xmlhttp.setRequestHeader('STTAuthorization', SESSIONKEY);

    xmlhttp.onreadystatechange=function(){
        if (xmlhttp.readyState==4 && xmlhttp.status==200){
            var postresponse = JSON.parse(xmlhttp.responseText);
            if (postresponse["error"] === null){
                console.log("Read was success");
                processWorkouts(postresponse["payload"]);
            }
            else{
                console.log(xmlhttp.responseText);
                console.log("Error happened");
            }
            //console.log(xmlhttp.responseText); //,codeapp);
        }
        else if (xmlhttp.readyState==4 && xmlhttp.status!=200){
            console.log(xmlhttp.responseText);
            console.log("Error happened");
        }
    };
    xmlhttp.send();
}

/*
    Will process readed workout JSON -feed and takes all needed information of them.
*/
function processWorkouts(workouts){
    workouts.forEach( function (feedItem){
        //Add only workouts which are not downloaded yet
        if (existingkeys.indexOf(feedItem.key) === -1){
            //console.log(JSON.stringify(feedItem));
            keys[keys.length] = {"key":feedItem.key,
                                 "activity":feedItem.activityId,
                                 "created":feedItem['created'],
                                 "desc":feedItem['description'],
                                 "name":feedItem['workoutName'],
                                 "distance":feedItem['totalDistance']};
        }
    });

    numofitems = keys.length;
    currentitem = 0;
    exportNextGPX();
}

/*
   Decodes Sports-Tracker.com activityID to string. Some activities are modified to Laufhelden style
*/
function decodeType(type){
    switch(type){
        case 0:return "walking";
        case 1:return "running";
        case 2:return "biking";         //cycling in sport-stracker
        case 3:return "nordic skiing";
        case 4:return "other 1";
        case 5:return "other 2";
        case 6:return "other 3";
        case 7:return "other 4";
        case 8:return "other 5";
        case 9:return "other 6";
        case 10:return "mountainBiking";
        case 11:return "hiking";
        case 12:return "inlineSkating"; //roller skating in sports-tracker
        case 13:return "skiing";        //downhill skiing in sports-tracker
        case 14:return "paddling";
        case 15:return "rowing";
        case 16:return "golf";
        case 17:return "indoor";
        case 18:return "parkour";
        case 19:return "ball games";
        case 20:return "outdoor gym";
        case 21:return "swimming";
        case 22:return "trail running";
        case 23:return "gym";
        case 24:return "nordic walking";
        case 25:return "horseback riding";
        case 26:return "motorsports";
        case 27:return "skateboarding";
        case 28:return "water sports";
        case 29:return "climbing";
        case 30:return "snowboarding";
        case 31:return "ski touring";
        case 32:return "fitness class";
        case 33:return "soccer";
        case 34:return "tennis";
        case 35:return "basketball";
        case 36:return "badminton";
        case 37:return "baseball";
        case 38:return "volleyball";
        case 39:return "american football";
        case 40:return "table tennis";
        case 41:return "racquet ball";
        case 42:return "squash";
        case 43:return "floorball";
        case 44:return "handball";
        case 45:return "softball";
        case 46:return "bowling";
        case 47:return "cricket";
        case 48:return "rugby";
        default: return "running";
    }
}
var stActivityLookup = ["walking","running","biking","nordic skiing","other 1","other 2","other 3","other 4","other 5","other 6","mountainBiking","hiking","inlineSkating",
"skiing","paddling","rowing","golf","indoor","parkour","ball games","outdoor gym","swimming","trail running","gym","nordic walking","horseback riding",
"motorsports","skateboarding","water sports","climbing","snowboarding","ski touring","fitness class","soccer","tennis","basketball","badminton","baseball","volleyball",
"american football","table tennis","racquet ball","squash","floorball","handball","softball","bowling","cricket","rugby"]

/*
    Takes next workout key from keys -array and tries to download it from the API.
    This function is called until all selected workouts are downloaded.
*/
function exportNextGPX(){
    if (currentitem > numofitems){
        downloadDoneCallback();
        return 0;
    }

    var item = keys[currentitem];
    console.log("Exporting:"+item.key+" ac:"+item.activity);

    var xmlhttp = new XMLHttpRequest();
    xmlhttp.open("GET", exportgpxurl+item.key);
    xmlhttp.setRequestHeader('Accept-Encoding', 'text');
    xmlhttp.setRequestHeader('Connection', 'keep-alive');
    xmlhttp.setRequestHeader('Pragma', 'no-cache');
    xmlhttp.setRequestHeader('Content-Type', 'application/json');
    xmlhttp.setRequestHeader('Accept', 'application/json, text/plain, */*');
    xmlhttp.setRequestHeader('Cache-Control', 'no-cache');
    xmlhttp.setRequestHeader('STTAuthorization', SESSIONKEY);

    xmlhttp.onreadystatechange=function(){
        if (xmlhttp.readyState==4 && xmlhttp.status==200){
            //console.log(xmlhttp.responseText);
            var desc = "";
            if (keys[currentitem-1]["desc"] !== undefined){
                desc = keys[currentitem-1]["desc"];
            }
            else if (keys[currentitem-1]["name"] !== undefined){
                desc = keys[currentitem-1]["name"];
            }
            else{
                desc = item.activity+"_"+Math.round(keys[currentitem-1]['distance']/2,1);
            }

            writecallback(xmlhttp.responseText, item.created, desc, keys[currentitem-1]["key"], decodeType(item.activity), keys[currentitem-1]['distance']);
        }
        else if (xmlhttp.readyState==4 && xmlhttp.status!=200){
            console.log(xmlhttp.responseText);
            console.log("Error happened");
        }
    };
    xmlhttp.send();
    currentitem += 1;
    return 1;
}

/*
    Upload current active track, notificatioCallback is used to show user info
*/
function uploadToSportsTracker(sharing, comment, notificationCallback){
    loginstate = 0;
    stComment = comment;
    stSharing = sharing;
    if (settings.stSessionkey === ""){
        notificationCallback(qsTr("Logging in..."),"info",25000);
        ST.loginSportsTracker(sendGPX,
                              displayNotification,
                              settings.stUsername,
                              settings.stPassword);
    }
    else{
        recycledlogin = true;
        SESSIONKEY = settings.stSessionkey; //Read stored sessionkey and use it.
        console.log("Already authenticated, trying to use existing sessionkey");
        sendGPX(notificationCallback);
    }
}

/*
    Reads local GPX-file and sends it to Sports-Tracker.com
    Timeouts are set to 25s
*/
function sendGPX(notificationCallback){
    loginstate = 1;
    notificationCallback("Reading GPX file...","info", 25000);
    var gpx = trackLoader.readGpx();
    notificationCallback(qsTr("Uploading..."), "info", 25000);
    importGPX(gpx, notificationCallback, stSharing, stComment);
}
