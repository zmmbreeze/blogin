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

copy = exports.copy = (src, dest) ->
	content = read(src)
	write(dest, content)

readJSON = exports.readJSON = (src) ->
	content = read(src)
	JSON.parse(content)

getFileName = exports.getFileName = (filePath) ->
	filePath.replace(path.dirname(filePath) + '/', '')

# './data/post/hello-world.md' => 'Hello world'
# './data/post/hello-world-border\\-left.md' => 'Hello world'
exports.pathToTitle = (filePath) ->
	fileName = getFileName(filePath).slice(0, -3)
	fileName = fileName
		.replace(/([^\\])\-/g, '$1 ')
		.replace(/\\-/g, '-')
	fileName.slice(0, 1).toUpperCase() + fileName.slice(1)
	

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
	format = format || 'YYYY-MM-DD'
	moment(stat.ctime).format(format)

exports.getMTime = (filePath, format) ->
	stat = fs.statSync(filePath)
	format = format || 'YYYY-MM-DD'
	moment(stat.mtime).format(format)

exports.mdToHtml = (filePath) ->
	if filePath.slice(-3) is '.md'
			filePath = filePath.slice(0, -3) + '.html'
	return filePath

exports.isMd = (filePath) ->
	return filePath.slice(-3) is '.md'

exports.readMdToHtml = (filePath) ->
	file = marked(read(filePath))