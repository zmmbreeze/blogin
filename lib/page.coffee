newFile = require('./post')
usage = require('./usage')
parseArg = require('./arg').parse

module.exports = (args) ->
	arg = parseArg(args)
	if (args.length is 0) or (arg.req.length is 0)
		usage.puts('pages')
		return

	filename = file.titleToPath(arg.req)
	newFile(arg, filename, './data/pages/', 'page')