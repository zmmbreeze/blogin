util = require('util')
moment = require('moment')
file = require('./file')
usage = require('./usage')
parseArg = require('./arg').parse
MyUtil = require('./MyUtil')

dirnameWithYearMap =
	post: './data/posts/{year}/'
	page: './data/pages/{year}/'

dirnameMap =
	post: './data/posts'
	page: './data/pages'

module.exports = (args) ->
	type = 'post'
	arg = parseArg(args)
	if (args.length is 0)
		listFile(type)
		return

	if (arg.req.length is 0)
		usage.puts(type)
		return

	filename = file.titleToPath(arg.req)
	if filename is 'index.md'
		usage.puts(type)
		return
	newFile(arg, filename, type)

# new file
newFile = module.exports.newFile = (arg, filename, type) ->
	# word sperate by one space
	postTitle = arg.req.join(' ')
	# add head
	content = postTitle + '\n======\n'
	# full file name
	dirname = (dirnameWithYearMap[type]).replace('{year}', moment().format('YYYY'))
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

# show file tree
listFile = module.exports.listFile = (type) ->
	dirname = dirnameMap[type]
	filter = (filename) =>
		return (file.isDir(filename) or file.isMd(filename))
	root = file.tree(dirname, filter)

	if root.notExists
		util.puts('Path "' + root.name + '" not existed.')
		return

	# print tree
	printTree = (root, highlightLineNum) ->
		level = -1
		iterate = (node) ->
			level++
			indent = ''
			i = 0
			l = level * 4
			limit = l - 3
			while i < l
				i++
				(symbol = ' ') if i < limit
				(symbol = '|') if i is limit
				(symbol = '-') if i > limit
				indent += symbol
			util.puts(indent + file.getFileName(node.name))
			if (node.children)
				for child in node.children
					iterate(child)

			level--

		iterate(root)

	# interact
	tip =
		"""
====================================
Shortcut: 
    "q"  ==>  quit.
    "d"  ==>  delete #{ type }.
    "j"  ==>  selection up.
    "k"  ==>  selection down.
		"""

	updateCommandLine = () ->
		printTree(root)
		util.puts(tip)

	updateCommandLine()
	stdin = process.stdin
	stdin.setRawMode(true);
	stdin.resume();
	stdin.setEncoding('utf8');
	stdin.on('data', (key) ->
		switch key
			when 'q' then process.exit()
			when 'd' then util.print('delete')
			when 'j' then util.print('up')
			when 'k' then util.print('down')
	)

	stdin.on('end',() ->
		process.stdout.write('end')
	)

# delete file
deleteFile = module.exports.deleteFile = (filename, type) ->
	return;
