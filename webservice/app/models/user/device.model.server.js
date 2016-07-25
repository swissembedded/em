
var mongoose = require("mongoose");


//compile schema to model
module.exports = mongoose.model('Device', {
  user_id: String,
  uuid:  String,
  name:  String,
  lat:   String,
  lon:   String,
  comments: [{ body: String, date: Date }],
  date: { type: Date, default: Date.now },
  hidden: Boolean
});