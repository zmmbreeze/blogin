// Generated by CoffeeScript 1.4.0
(function() {
  var app, connect, path, util;

  connect = require('connect');

  util = require('util');

  path = require('path');

  app = connect().use(connect.logger('dev')).use(connect["static"]('./')).listen(3000);

  util.puts('Server running on port 3000.');

}).call(this);