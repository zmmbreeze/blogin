util = require('util')
clc  = require('cli-color')
fs   = require('fs')
path = require('path')
jade = require('jade')
moment = require('moment')
file = require('./file')
usage = require('./usage')
parseArg = require('./arg').parse

templateDir = './public/template/'
projectDir = './'


fileApi =
	getJadeFile: (type) ->
		file.read(path.resolve(templateDir, type + '.jade'))

	getSrcFile: (type) ->
		switch type
			when 'page'
				path.resolve(projectDir, 'data/pages')
			else
				path.resolve(projectDir, 'data/posts')

	getDestFile: (type) ->
		switch type
			when 'archive'
				path.resolve(projectDir, 'post')
			when 'post'
				path.resolve(projectDir, 'post')
			when 'page'
				path.resolve(projectDir, 'page')
			else
				path.resolve(projectDir, 'index.html')

	srcToDest: (type, srcFilePath) ->
		relativePath = path.relative(this.getSrcFile(type), srcFilePath)
		fileUrl = path.resolve(this.getDestFile(type), relativePath)
		file.mdToHtml(fileUrl)

	srcToUrl: (type, srcFilePath) ->
		relativePath = path.relative(this.getSrcFile(type), srcFilePath)
		fileUrl = path.resolve(this.getDestFile(type), relativePath)
		file.pathToUrl(file.mdToHtml(fileUrl), projectDir)



dataApi =
	getPostList: () ->
		postDir = fileApi.getSrcFile('post')
		fileList = file.dir(postDir)
		
		items = []
		fileList.forEach (filePath) =>
			if not file.isMd(filePath)
				return;
			items.push
				title: file.pathToTitle(filePath)
				url: fileApi.srcToUrl('post', filePath)
		return items

	getPageList: () ->
		pageDir = fileApi.getSrcFile('page')
		fileList = file.dir(pageDir)
		
		items = []
		fileList.forEach (filePath) =>
			if not file.isMd(filePath)
				return;
			items.push
				title: file.pathToTitle(filePath)
				url: fileApi.srcToUrl('page', filePath)
		return items

	getArchiveList: () ->
		archiveDir = fileApi.getSrcFile('post')
		archiveList = file.dir(archiveDir, true)

		items = []
		archiveList.forEach (filePath) =>
			items.push
				title: file.getFileName(filePath)
				url: fileApi.srcToUrl('archive', filePath) + '/'
		return items

	getArchivePostList: (archiveName) ->
		postDir = path.resolve(fileApi.getSrcFile('post'), archiveName)
		fileList = file.dir(postDir)
		
		items = []
		fileList.forEach (filePath) =>
			if not file.isMd(filePath)
				return;
			items.push
				title: file.pathToTitle(filePath)
				url: fileApi.srcToUrl('post', filePath)
		return items

	getLocals: (type, arg1) ->
		locals = 
			site: file.readJSON(path.resolve(projectDir, './blogin.json'))
			pageName: ''

		switch type
			when 'index'
				locals.items = this.getPostList()
				locals.archives = this.getArchiveList()
				locals.pages = this.getPageList()
				#rewrite keyword and description
				locals.metaKeywords = locals.site.keywords
				locals.metaDescription = locals.site.description
			when 'archive'
				archiveName = arg1
				locals.pageName = archiveName
				locals.items = this.getArchivePostList(archiveName)
				#rewrite keyword and description
				locals.metaKeywords = locals.site.keywords
				locals.metaDescription = locals.site.description
			when 'page'
				locals.pageName = arg1.title
				locals.entry = arg1
				#rewrite keyword and description
				locals.site.keywords = locals.site.keywords || ''
				keywords = locals.site.keywords.split(',')
				keywords.push(locals.pageName)
				locals.metaKeywords = keywords.join(',')
				locals.metaDescription = locals.pageName
			when 'post'
				locals.pageName = arg1.title
				locals.entry = arg1
				#rewrite keyword and description
				locals.site.keywords = locals.site.keywords || ''
				keywords = locals.site.keywords.split(',')
				keywords.push(locals.pageName)
				locals.metaKeywords = keywords.join(',')
				locals.metaDescription = locals.pageName
		return locals


rendApi =
	index: (keepQuiet) ->
		dest = fileApi.getDestFile('index')
		compile = jade.compile(fileApi.getJadeFile('index'), 
			filename: path.resolve(templateDir, 'includes')
		)

		file.write(dest, compile(dataApi.getLocals('index')))
		if not keepQuiet
			util.puts('File ' + dest + ' created.')

	archive: (keepQuiet) ->
		srcDir = fileApi.getSrcFile('archive')
		destDir = fileApi.getDestFile('archive')
		archives = file.dir(srcDir, true)
		compile = jade.compile(fileApi.getJadeFile('archive'), 
			filename: path.resolve(templateDir, 'includes')
		)

		archives.forEach (archivePath) =>
			archiveName = file.getFileName(archivePath)
			archiveDestFile = path.resolve(destDir, archiveName, 'index.html')
			file.write(archiveDestFile, compile(dataApi.getLocals('archive', archiveName)))
			if not keepQuiet
				util.puts('File ' + archiveDestFile + ' created.')

	page: (keepQuiet) ->
		srcDir = fileApi.getSrcFile('page')
		destDir = fileApi.getDestFile('page')
		pages = file.dir(srcDir, true)
		compile = jade.compile(fileApi.getJadeFile('page'), 
			filename: path.resolve(templateDir, 'includes')
		)

		pages.forEach (pagePath) =>
			pageName = file.getFileName(pagePath).slice(0, -3)
			pageTitle = file.pathToTitle(pagePath)
			entry =
				title: pageTitle
				content: file.readMdToHtml(pagePath)
				time: file.getMTime(pagePath)
			pageFile = fileApi.srcToDest('page', pagePath)
			file.write(pageFile, compile(dataApi.getLocals('page', entry)))
			if not keepQuiet
				util.puts('File ' + pageFile + ' created.')

	post: (keepQuiet) ->
		srcDir = fileApi.getSrcFile('post')
		destDir = fileApi.getDestFile('post')
		posts = file.dir(srcDir)
		compile = jade.compile(fileApi.getJadeFile('post'), 
			filename: path.resolve(templateDir, 'includes')
		)

		posts.forEach (postPath) =>
			postName = file.getFileName(postPath).slice(0, -3)
			postTitle = file.pathToTitle(postPath)
			entry =
				title: postTitle
				content: file.readMdToHtml(postPath)
				time: file.getMTime(postPath)
			postFile = fileApi.srcToDest('post', postPath)
			console.log(file.readMdToHtml(postPath))
			file.write(postFile, compile(dataApi.getLocals('post', entry)))
			if not keepQuiet
				util.puts('File ' + postFile + ' created.')



module.exports = (args) ->
	arg = parseArg(args)
	projectDir = path.resolve('./', arg.req[0] || './')
	templateDir = path.resolve(projectDir, './public/template/')

	if not fs.existsSync(templateDir)
		usage.puts('update')
		return
	keepQuiet = arg.opt.indexOf('q') > 0
	rendApi.index(keepQuiet)
	rendApi.archive(keepQuiet)
	rendApi.page(keepQuiet)
	rendApi.post(keepQuiet)


