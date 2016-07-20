
var temperaturePost = require(__dirname + "/models/Temperature");
var Device = require(__dirname + "/models/Device");


module.exports = function(app) {

	// server routes ===========================================================
	// handle things like api calls
	// authentication routes
	app.get('/getTemperatures', function(req, res) {
		temperaturePost.find({}, function (err, docs) {
			if (err) return handleError(err);
			res.json(docs);
		})
	});


	app.post('/addDevice', function(req, res) {

		var newDevice = new Device(
		{
			user_id: req.body.user_id,
			uuid:  req.body.uuid,
			name:  req.body.name,
			lat:   req.body.lat,
			lon:   req.body.lon
		});

     	//save model to MongoDB
     	newDevice.save(function (err) {
     		if (err) {
     			return err;
     		}
     		else {
     			console.log("Post saved");
     		}
     	});

     	console.log(req.body);
     	res.json(req.body);
     });
	
	app.get('/getDevices', function(req, res) {

	 	// Uses Mongoose schema to run the search (empty conditions)
	 	var query = Device.find({});
	 	query.exec(function(err, users){
	 		if(err)
	 			res.send(err);

            // If no errors are found, it responds with a JSON of all users
            res.json(users);
        });
	 });


	// frontend routes =========================================================
	// route to handle all angular requests
	app.get('*', function(req, res) {
		res.sendfile('./public/index.html');
	});
};