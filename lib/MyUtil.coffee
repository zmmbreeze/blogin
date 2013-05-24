path = require('path')
util = require('util')
spawn = require('child_process').spawn
file = require('./file')

checkProjectDir = exports.checkProjectDir = (dirPath) ->
	dirPath = path.resolve(process.cwd(), dirPath || './')
	bloginConfigFile = path.relative(dirPath, './blogin.json')
	if (file.exists(bloginConfigFile))
		return true
	else
		util.puts('Error: ' + dirPath + ' was not the project directory, file blogin.json was not found!\n')
		return false

getInfoFile = exports.getInfoFile = (projectDir) ->
	projectDir = projectDir || './'
	if not checkProjectDir(projectDir)
		return false
	infoFile = path.resolve(projectDir, 'data/info')

exports.getInfo = (type, filePath, projectDir) ->
	projectDir = projectDir || './'
	infoFile = getInfoFile(projectDir)
	if not infoFile
		return false

	projectInfo = file.readJSON(infoFile)
	list = projectInfo[type]
	filePath = path.relative(projectDir, filePath)
	result = null;
	list.forEach (item) =>
		if (item.file is filePath)
			result = item
	return result

exports.removeInfo = (type, filePath, projectDir) ->
	projectDir = projectDir || './'
	infoFile = getInfoFile(projectDir)
	if not infoFile
		return false

	# generate info
	projectInfo = file.readJSON(infoFile)
	list = projectInfo[type]
	filePath = path.relative(projectDir, filePath)
	newList = list.filter (item) =>
		return item.file isnt filePath

	# write this info
	projectInfo[type] = newList
	file.write(infoFile, JSON.stringify(projectInfo, null, 4))

exports.getInfos = (projectDir) ->
	projectDir = projectDir || './'
	infoFile = getInfoFile(projectDir)
	if not infoFile
		return false

	file.readJSON(infoFile)


# add info by absolute file path and type
# type = 'post' | 'page'
exports.addInfo = (type, filePath, projectDir) ->
	projectDir = projectDir || './'
	infoFile = getInfoFile(projectDir)
	if not infoFile
		return false

	# generate info
	info = {}
	info.file = path.relative(projectDir, filePath)
	info.ctime = file.getCTime(filePath)
	info.mtime = file.getMTime(filePath)

	# write this info
	infos = file.readJSON(infoFile) || {}
	infos[type] = infos[type] || []
	infos[type].push(info)
	file.write(infoFile, JSON.stringify(infos, null, 4))

	return info

# XXX developing
exports.updateInfos = () ->
	infoFile = getInfoFile()
	if not infoFile
		return false

	# rewrite info file
	infos = {};
	infos.post = [];
	posts = file.dir(fileApi.getSrcFile('post'))
	posts.forEach (filePath) =>
		post = {};
		post.file = path.relative(projectDir, filePath)
		post.ctime = file.getCTime(filePath)
		post.mtime = file.getMTime(filePath)
		infos.post.push(post)

	infos.page = [];
	pages = file.dir(fileApi.getSrcFile('page'))
	pages.forEach (filePath) =>
		page = {};
		page.file = path.relative(projectDir, filePath)
		page.ctime = file.getCTime(filePath)
		page.mtime = file.getMTime(filePath)
		infos.page.push(page)

	file.write(infoFile, JSON.stringify(infos, null, 4))

###
	command: 'git'
	args: ['add', '-A']
	options:
		cwd: process.cwd
	exit: () ->
	stdout: () ->
###
exports.spawn = (options) ->
	comm = spawn(options.command, options.args, options.options)

	comm.stdout.setEncoding('utf8')
	comm.stderr.setEncoding('utf8')

	comm.stdout.on 'data', options.stdout or (data) ->
		util.puts(data);

	comm.stderr.on 'data', options.stderr or (data) ->
		util.puts(data);

	if options.exit
		comm.on('exit', options.exit)