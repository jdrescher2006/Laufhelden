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
var loginurl = "http://www.sports-tracker.com/apiserver/v1/login";
var importurl = "http://www.sports-tracker.com/apiserver/v1/workout/importGpx";
var saveurl = "http://www.sports-tracker.com/apiserver/v1/workouts/header";

/*
    Decode SportsTracker sharing options to List index values
    These are used in Settings and Sharing pages.
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
            notificationcallback("Oops, username of password error","error", 3000);
            console.log(xmlhttp.responseText);
        }
    };
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
            notificationcallback("Some kind of error happened on GPX import","error", 3000);
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
                notificationcallback("Workout uploaded!","success", 3000);
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
            notificationcallback("Some kind of error happened on Saving data","error", 3000);
        }
    };
    xmlhttp.send(JSON.stringify(data));
}
