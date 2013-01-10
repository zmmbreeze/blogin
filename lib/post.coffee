util = require('util')
moment = require('moment')
file = require('./file')
usage = require('./usage')
parseArg = require('./arg').parse
MyUtil = require('./MyUtil')

dirnameMap =
	post: './data/posts/{year}/'
	page: './data/pages/{year}/'

module.exports = (args) ->
	arg = parseArg(args)
	if (args.length is 0) or (arg.req.length is 0)
		usage.puts('post')
		return

	filename = file.titleToPath(arg.req)
	if filename is 'index.md'
		usage.puts('post')
		return
	newFile(arg, filename, 'post')

newFile = module.exports.newFile = (arg, filename, type) ->
	# word sperate by one space
	postTitle = arg.req.join(' ')
	# add head
	content = postTitle + '\n======\n'
	# full file name
	dirname = (dirnameMap[type]).replace('{year}', moment().format('YYYY'))
	dataFile = dirname + filename

	# force write or not
	if ~arg.opt.indexOf('f')
		file.write(dataFile, content)
		util.puts('Created at ' + dataFile)
		MyUtil.addInfo(type, dataFile)
	else
		if file.writeIfNotExist(dataFile, content)
			util.puts('Created at ' + dataFile)
			MyUtil.addInfo(type, dataFile)
		else
			util.puts('Fail to create, file "' + dataFile + '" was existed.\nUse [-f] option to rewrite the file.')
