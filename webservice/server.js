// modules =================================================
var express        = require('express');
var app            = express();
var mongoose       = require('mongoose');
var bodyParser     = require('body-parser');
var methodOverride = require('method-override');

// configuration ===========================================

// config files
var db = require('./config/db');

var port = process.env.PORT || 8080; // set our port
 mongoose.connect(db.url); // connect to our mongoDB database (commented out after you enter in your own credentials)


//MQTT SERVER
var temperaturePost = require(__dirname + "/app/models/Temperature");
var path = require('path');
var mqtt    = require('mqtt');
var client  = mqtt.connect('mqtt://test.mosquitto.org');
var deviceRoot = 'emdo/devices/#' ;


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


//MQTT SERVER

// get all data/stuff of the body (POST) parameters
app.use(bodyParser.json()); // parse application/json 
//app.use(bodyParser.json({ type: 'application/vnd.api+json' })); // parse application/vnd.api+json as json
app.use(bodyParser.urlencoded({ extended: true })); // parse application/x-www-form-urlencoded

app.use(methodOverride('X-HTTP-Method-Override')); // override with the X-HTTP-Method-Override header in the request. simulate DELETE/PUT
app.use(express.static(__dirname + '/public')); // set the static files location /public/img will be /img for users

// routes ==================================================
require('./app/routes')(app); // pass our application into our routes


// start app ===============================================
app.listen(port);	
console.log('Magic happens on port ' + port); 			// shoutout to the user
exports = module.exports = app; 						// expose app