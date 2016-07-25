var express       = require('express');
var app           = express();
var bodyParser    = require('body-parser');
var multer        = require('multer'); 
var passport      = require('passport');
var cookieParser  = require('cookie-parser');
var session       = require('express-session');
var mongoose      = require('mongoose');


mongoose.connect('mongodb://localhost/mqtt');

//MQTT SERVER
var temperaturePost = require(__dirname + "/app/models/user/temperature.model.server.js");
var path = require('path');
var mqtt    = require('mqtt');
var client  = mqtt.connect('mqtt://test.mosquitto.org');
var deviceRoot = 'emdo/devices/#' ;

//MQTT SERVER

client.on('connect', function () {
	console.log('Estoy arriba: ' + deviceRoot);
	client.subscribe('emdo/devices/#');
});

client.on('message', function (topic, message) {
  // message is Buffer 

  var uuid = topic.split("/")[2];  
  message = JSON.parse(message);
  console.log(JSON.stringify(message));
  
  var post = new temperaturePost(
  {
  	uuid:  uuid,
  	kw1:   message.kw1,
  	kw2:   message.kw2,
  });

	//save model to MongoDB
	post.save(function (err) {
		if (err) {
			return err;
		}
		else {
			console.log("Post saved");
		}
	});
});





app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
multer();
app.use(session({
	secret: 'this is the secret',
	resave: true,
	saveUninitialized: true
}));
app.use(cookieParser());
app.use(passport.initialize());
app.use(passport.session());
app.use(express.static(__dirname + '/public'));

require("./app/app.js")(app);

app.listen(3000);
console.log('Ready on 3000'); 			// shoutout to the user