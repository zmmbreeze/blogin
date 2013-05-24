util = require('util')
moment = require('moment')
clc = require('cli-color')
charm = require('charm')()
file = require('./file')
usage = require('./usage')
parseArg = require('./arg').parse
MyUtil = require('./MyUtil')

class TrashList
	constructor: () ->
		@dirname = './trash'
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
    #{clc.yellow('"r"')}  ==>  recovery delete file.
			"""
		# #{clc.yellow('"a"')}  ==>  add new #{ type }.
		this._createRoot()
		charm.pipe(process.stdout)
		charm.reset()
		this._rend()
		this._bindEvent()

	_createRoot: () ->
		@rootNode = file.tree(@dirname, (filename) ->
			return file.isMd(filename) or file.isDir(filename)
		)

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

	recoveryFile: (num) ->
		selectFile = this.getSelectedFile(num)
		if (selectFile && not selectFile.children)
			# remove
			file.recovery(selectFile.name)
			# set msg
			@msg = '\nFile "' + file.getFileName(selectFile.name) + '" recovered.'
			# rend
			this._createRoot()
			this._rend()
		else
			@msg = 'Nothing selected.'
			this._rend()

	_resolveNum: (num) ->
		if (num?)
			return if num < 0 then num + @mdLength else num % @mdLength
		else
			return @num

	_rend: () ->
		charm.erase('screen')
		charm.cursor(false)
		charm.position(0, 0)
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

			switch key
				when 'q' then process.exit()
				when 'r'
					this.recoveryFile()
				when 'j'
					this.selectFile(@num + 1)
				when 'k'
					this.selectFile(@num - 1)
		)

	_printStatus: () ->
		if (@msg?)
			util.puts(@msg)


module.exports = (args) ->
	arg = parseArg(args)
	new TrashList()