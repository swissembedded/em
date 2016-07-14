
var temperaturePost = require("./model/temperature");
var express = require('express');
var app = express();
var path = require('path');
var mqtt    = require('mqtt');
var client  = mqtt.connect('mqtt://test.mosquitto.org');

var deviceRoot = 'emdo/devices/#' ;


client.on('connect', function () {
  console.log('Estoy arriba: ' + deviceRoot);
  client.subscribe('emdo/devices/#');
  //client.subscribe(deviceRoot);
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

  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'html');
  app.set('view options', {layout: false});
  app.use('/bower_components',  express.static(__dirname + '/bower_components'));
  app.use(express.static(path.join(__dirname, 'public')));

app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
});

app.get('/', function(req, res) {
    res.sendFile(path.join(__dirname + '/public/index.html'));
});

app.get('/getTemperatures', function(req, res) {
	  temperaturePost.find({}, function (err, docs) {
      res.json(docs);
    });
});
