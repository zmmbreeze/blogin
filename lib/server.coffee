connect = require('connect')
util = require('util')
path = require('path')

app = connect()
	.use(connect.logger 'dev')
	.use(connect.static(process.cwd()))
	.listen(3000)

util.puts('Server running on port 3000.')