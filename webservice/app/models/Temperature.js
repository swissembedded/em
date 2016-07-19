
var mongoose = require("mongoose");


//compile schema to model
module.exports = mongoose.model('Temperature', {
  uuid:  String,
  name:  String,
  kw1:   String,
  kw2:   String,
  comments: [{ body: String, date: Date }],
  date: { type: Date, default: Date.now },
  hidden: Boolean
});