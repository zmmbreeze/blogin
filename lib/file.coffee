fs = require('fs')
path = require('path')
moment = require('moment')
marked = require('marked')

marked.setOptions
	gfm: true
	pedantic: false
	sanitize: false

mkdir = exports.mkdir = (dest) ->
	dest = path.resolve(dest)
	parent = path.dirname(dest)

	if fs.existsSync(parent)
		fs.mkdirSync(dest)
	else
		mkdir(parent)
		fs.mkdirSync(dest)

dir = exports.dir = (src, notRecursive, onlyDir) ->
	return [] if not fs.existsSync(src)

	if !fs.statSync(src).isDirectory()
		return [src]

	filePaths = []
	fs.readdirSync(src).forEach (filename, i) =>
		# resolve file name to full path
		filename = path.resolve(src, filename)

		if fs.statSync(filename).isDirectory()
			if not notRecursive
				filePaths = filePaths.concat(dir(filename, notRecursive, onlyDir))
			else
				filePaths.push(filename)
		else
			if not onlyDir
				filePaths.push(filename)
	return filePaths

read = exports.read = (src) ->
	if fs.existsSync(src)
		return fs.readFileSync(src, 'utf8')
	else
		return ''

write = exports.write = (src, content) ->
	parent = path.dirname(src)
	if not fs.existsSync(parent)
		mkdir(parent)
	fs.writeFileSync(src, content, 'utf8')

exports.writeIfNotExist = (src, content) ->
	if not fs.existsSync(src)
		write(src, content)
		return true
	else
		return false

###
	src: '/home/user/a'
	dest: '/home/user/b'
	force: true
###
BUF_LENGTH = 64 * 1024
_buff = new Buffer(BUF_LENGTH)
copy = exports.copy = (src, dest, force) ->
	destExist = fs.existsSync(dest)
	if not force and destExist
		return false

	if fs.statSync(src).isDirectory()
		# mkdir
		if not destExist
			mkdir(dest)
		# copy child
		fs.readdirSync(src).forEach (filename, i) =>
			copy(path.resolve(src, filename), path.resolve(dest, filename), force)
	else
		###
		if force and destExist
			console.log(dest)
			fs.unlinkSync(dest) # remove dest file
		fs.createReadStream(src).pipe(fs.createWriteStream(dest))
		###
		fdr = fs.openSync(src, 'r')
		fdw = fs.openSync(dest, 'w')
		bytesRead = 1
		pos = 0
		while (bytesRead > 0)
			bytesRead = fs.readSync(fdr, _buff, 0, BUF_LENGTH, pos)
			fs.writeSync(fdw, _buff, 0, bytesRead)
			pos += bytesRead
		fs.closeSync(fdr)
		fs.closeSync(fdw)

	return true

readJSON = exports.readJSON = (src) ->
	content = read(src)
	if content
		return JSON.parse(content)
	else
		return ''

getFileName = exports.getFileName = (filePath) ->
	filePath.replace(path.dirname(filePath) + '/', '')

# './data/post/hello-world.md' => 'Hello world'
# './data/post/hello-world-border\\-left.md' => 'Hello world'
exports.pathToTitle = (filePath) ->
	###
	fileName = getFileName(filePath).slice(0, -3)
	fileName = fileName
		.replace(/([^\\])\-/g, '$1 ')
		.replace(/\\-/g, '-')
	fileName.slice(0, 1).toUpperCase() + fileName.slice(1)
	###
	content = read(filePath)
	return content.slice(0, content.indexOf('\n'))
	

# 'Hello World' => 'hello-world.md'
# '  Hello   World  ' => 'hello-world.md'
# 'Hello World border-left' => 'hello-world-border\\-left'
exports.titleToPath = (title) ->
	if typeof (title) is 'object'
		words = title
	else
		words = [title]

	escapedWords = []

	words.forEach (word, i) ->
		escapedWords[i] = word.replace(/\-/g, '\\$1')
	filename = escapedWords.join('-').toLowerCase()
	# add suffix
	filename = filename + '.md' if filename.slice(-3) isnt '.md'

# '/home/mzhou/blogin/data/posts', '/home/mzhou/blogin'
# 	==> '/data/posts'
exports.pathToUrl = (filePath, root) ->
	'/' + path.relative(root, filePath)

exports.getCTime = (filePath, format) ->
	stat = fs.statSync(filePath)
	format = format || 'YYYY-MM-DD hh:mm:ss'
	moment(stat.ctime).format(format)

exports.getMTime = (filePath, format) ->
	stat = fs.statSync(filePath)
	format = format || 'YYYY-MM-DD hh:mm:ss'
	moment(stat.mtime).format(format)

exports.mdToHtml = (filePath) ->
	if filePath.slice(-3) is '.md'
			filePath = filePath.slice(0, -3) + '.html'
	return filePath

exports.isMd = (filePath) ->
	return filePath.slice(-3) is '.md'

exports.isHide = (filePath) ->
	return getFileName(filePath)[0] is '.'

exports.readMdToHtml = (filePath) ->
	file = marked(read(filePath))

exports.sortByCreateTime = (paths) ->
	return paths.sort (a, b) =>
		return this.getCTime(a) < this.getCTime(b)

# path = './path/file' || ['./file1', './file2']
exports.exists = (path) ->
	if typeof path is not 'string'
		result = true
		for p in path
			do (p) ->
				if not fs.existsSync p
					result = false
		return result
	else
		return fs.existsSync(path)