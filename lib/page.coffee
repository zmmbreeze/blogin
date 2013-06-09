post = require('./post')
usage = require('./usage')
parseArg = require('./arg').parse
file = require('./file')

module.exports = (args) ->
	type = 'page'
	arg = parseArg(args)
	if (args.length is 0)
		post.listFile(type)
		return

	if (arg.req.length is 0)
		usage.puts(type)
		return

	filename = file.titleToPath(arg.req)
	post.newFile(arg, filename, 'page')
