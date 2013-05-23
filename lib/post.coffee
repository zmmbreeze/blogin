util = require('util')
moment = require('moment')
clc = require('cli-color')
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

class ControlList
	constructor: (@type, @dirname, @filter) ->
		@num = 0;
		@listTip =
			"""
====================================
#{ @type } list:
			"""
		@shortcutTip =
			"""
====================================
Shortcut: 
    #{clc.yellow('"q"')}  ==>  quit.
    #{clc.yellow('"j"')}  ==>  selection up.
    #{clc.yellow('"k"')}  ==>  selection down.
    #{clc.yellow('"d"')}  ==>  delete #{ type }.
    #{clc.yellow('"a"')}  ==>  add new #{ type }.
			"""
		this._createRoot()
		@mdLength = this.getMdFiles().length
		this._rend()
		this._bindEvent()

	_createRoot: () ->
		@rootNode = file.tree(@dirname, @filter)

		if @rootNode.notExists
			util.puts('Path "' + @rootNode.name + '" not existed.')

	iterate: (callback) ->
		iterate = (node) ->
			if (node.children)
				for child in node.children
					iterate(child)
			else
				callback(node)
		iterate(@rootNode)

	getMdFiles: () ->
		files = [];
		this.iterate (node) ->
			files.push(node)
		return files

	selectFile: (num) ->
		@num = this._resolveNum(num)
		this._rend()

	getSelectedFile: () ->
		num = this._resolveNum(num)
		return this.getMdFiles()[num]

	deleteFile: (num) ->
		selectFile = this.getSelectedFile(num)
		file.trash(selectFile.name)
		###
		this._createRoot()
		this._rend()
		###

	_resolveNum: (num) ->
		if (num)
			return if num < 0 then num + @mdLength else num % @mdLength
		else
			return @num

	_rend: () ->
		util.puts(clc.reset)
		util.puts(clc.moveTo(0, 0))
		this._rendTree()
		util.puts(@shortcutTip)

	_rendTree: () ->
		util.puts(@listTip)
		level = -1
		num = -1
		iterate = (node) =>
			# calculate indent
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

			# setup filename
			if (file.isMd(node.name))
				# markdown(md) file
				filename = file.pathToTitle(node.name)
				num++
				# underline selected filename
				if (num is @num)
					filename = clc.underline(filename)
			else
				# directory
				filename = file.getFileName(node.name)

			# iterate children
			util.puts(indent + ' ' + filename)
			if (node.children)
				for child in node.children
					iterate(child)
			level--

		iterate(@rootNode)

	_bindEvent: () ->
		stdin = process.stdin
		stdin.setRawMode(true);
		stdin.resume();
		stdin.setEncoding('utf8');
		stdin.on('data', (key) =>
			switch key
				when 'q', '\u0003' then process.exit()
				when 'd'
					this.deleteFile()
				when 'j'
					this.selectFile(@num + 1)
				when 'k'
					this.selectFile(@num - 1)
		)


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

	new ControlList(type, dirname, filter)

# delete file
deleteFile = module.exports.deleteFile = (filename, type) ->
	return;
