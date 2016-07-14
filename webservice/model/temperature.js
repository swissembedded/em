
var mongoose = require("mongoose");

//connect to database
var db = mongoose.connect('mongodb://localhost/mqtt');

//create schema for blog post
var temperatureSchema = new mongoose.Schema({
  uuid:  String,
  name:  String,
  kw1:   String,
  kw2:   String,
  comments: [{ body: String, date: Date }],
  date: { type: Date, default: Date.now },
  hidden: Boolean
});

//compile schema to model
module.exports = db.model('Temperature', temperatureSchema)