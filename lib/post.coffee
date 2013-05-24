util = require('util')
moment = require('moment')
clc = require('cli-color')
charm = require('charm')()
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
			"""
		@shortcutTip =
			"""
====================================
Shortcut: 
    #{clc.yellow('"q"')}  ==>  quit.
    #{clc.yellow('"j"')}  ==>  selection up.
    #{clc.yellow('"k"')}  ==>  selection down.
    #{clc.yellow('"d"')}  ==>  delete #{ type }.
			"""
		# #{clc.yellow('"a"')}  ==>  add new #{ type }.
		this._createRoot()
		charm.pipe(process.stdout)
		charm.reset()
		this._rend()
		this._bindEvent()

	_createRoot: () ->
		@rootNode = file.tree(@dirname, @filter)

		if @rootNode.notExists
			util.puts('Path "' + @rootNode.name + '" not existed.')

		@mdLength = this.getMdFiles().length

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
		if (selectFile && not selectFile.children)
			# remove
			# MyUtil.removeInfo(@type, selectFile.name)
			file.trash(selectFile.name)
			# set msg
			@msg = '\nFile "' + file.getFileName(selectFile.name) + '" deleted.\nUse "blogin trash" command to recover deleted file.'
			# rend
			this._createRoot()
			this._rend()
		else
			@msg = 'Nothing selected.'
			this._rend()

	newFile: (titles) ->
		filename = file.titleToPath(titles)
		if filename is 'index.md'
			util.puts("Can\'t use \"index\" as #{@type} title")
			return

		# add head
		content = titles + '\n======\n'
		# full file name
		dirname = (dirnameWithYearMap[type]).replace('{year}', moment().format('YYYY'))
		dataFile = dirname + filename

		if file.writeIfNotExist(dataFile, content)
			@msg = 'Created at ' + dataFile
			MyUtil.addInfo(type, dataFile)
			# rend
			this._createRoot()
			this._rend()
		else
			@msg = 'Fail to create, file "' + dataFile + '" was existed.\nUse [-f] option to rewrite the file.'
			this._rend()

	_resolveNum: (num) ->
		if (num?)
			return if num < 0 then num + @mdLength else num % @mdLength
		else
			return @num

	_rend: () ->
		charm.erase('screen')
		# process.stdout.write('\x1B[J')
		charm.cursor(false)
		charm.position(0, 0)
		# process.stdout.write('\x1B[0;0H')
		this._rendTree()
		util.puts(@shortcutTip)
		charm.cursor(true)
		this._printStatus()

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
					indent = indent.replace(/-/g, '>')
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
		newTitle = ''
		stdin.on('data', (key) =>
			if (key is '\u0003')
				process.exit()

			###
			if (key is '\u000A' or key is '\u000D')
				@_isPrompting = false
				this.newFile(newTitle)

			if (@_isPrompting)
				newTitle += key
				process.stdout.write(key)
				return
			###

			switch key
				when 'q' then process.exit()
				when 'd'
					this.deleteFile()
				when 'j'
					this.selectFile(@num + 1)
				when 'k'
					this.selectFile(@num - 1)
			###
			when 'a'
				@_isPrompting = true
				util.print('\nPlease input post title:')
			###
		)

	_printStatus: () ->
		if (@msg?)
			util.puts(@msg)



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
	# TODO make sure it's not exist in trash and info file
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
