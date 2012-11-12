connect = require('connect')
util = require('util')
path = require('path')

app = connect()
	.use(connect.logger 'dev')
	# must use path.resolve!
	.use(connect.static(path.resolve('./')))
	.listen(3000)

util.puts('Server running on port 3000.')