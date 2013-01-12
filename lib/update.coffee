util = require('util')
clc  = require('cli-color')
fs   = require('fs')
path = require('path')
jade = require('jade')
moment = require('moment')
file = require('./file')
usage = require('./usage')
parseArg = require('./arg').parse
MyUtil = require('./MyUtil')
RSS = require('rss')

templateDir = './public/template/'
projectDir = './'
projectInfo = null

fileApi =
	getJadeFile: (type) ->
		file.read(path.resolve(templateDir, type + '.jade'))

	getSrcFile: (type) ->
		switch type
			when 'page'
				path.resolve(projectDir, 'data/pages')
			when 'post'
				path.resolve(projectDir, 'data/posts')
			when 'archive'
				path.resolve(projectDir, 'data/posts')


	getDestFile: (type) ->
		switch type
			when 'archive'
				path.resolve(projectDir, 'post')
			when 'post'
				path.resolve(projectDir, 'post')
			when 'page'
				path.resolve(projectDir, 'page')
			when 'index'
				path.resolve(projectDir, 'index.html')
			when 'rss'
				path.resolve(projectDir, 'rss.xml')
			else
				projectDir

	srcToDest: (type, srcFilePath) ->
		relativePath = path.relative(this.getSrcFile(type), srcFilePath)
		fileUrl = path.resolve(this.getDestFile(type), relativePath)
		file.mdToHtml(fileUrl)

	srcToUrl: (type, srcFilePath) ->
		relativePath = path.relative(this.getSrcFile(type), srcFilePath)
		fileUrl = path.resolve(this.getDestFile(type), relativePath)
		file.pathToUrl(file.mdToHtml(fileUrl), projectDir)

	# if not found info, it will generate it by file info on current machine!
	getInfo: (type, filePath) ->
		projectInfo = projectInfo || MyUtil.getInfos(projectDir)
		list = projectInfo[type]
		filePath = path.relative(projectDir, filePath)
		result = null;
		list.forEach (item) =>
			if (item.file is filePath)
				result = item
		if not result
			result = this.addInfo(type, filePath, projectDir)
		return result

	addInfo: (type, filePath) ->
		return MyUtil.addInfo(type, filePath, projectDir)

	getMTime: (type, filePath) ->
		info = this.getInfo(type, filePath)
		if info then info.mtime

	getCTime: (type, filePath) ->
		info = this.getInfo(type, filePath)
		if info then info.ctime

	sortByCreateTime: (type, files) ->
		return files.sort (a, b) =>
			return this.getCTime(type, a) < this.getCTime(type, b)


dataApi =
	getPostList: () ->
		postDir = fileApi.getSrcFile('post')
		fileList = file.dir(postDir)
		
		items = []
		fileList = fileApi.sortByCreateTime('post', fileList)
		fileList.forEach (filePath) =>
			if not file.isMd(filePath)
				return;
			items.push
				title: file.pathToTitle(filePath)
				url: fileApi.srcToUrl('post', filePath)
				time: fileApi.getCTime('post', filePath)
		return items

	getPageList: () ->
		pageDir = fileApi.getSrcFile('page')
		fileList = file.dir(pageDir)
		
		items = []
		fileList = fileApi.sortByCreateTime('page', fileList)
		fileList.forEach (filePath) =>
			if not file.isMd(filePath)
				return;
			items.push
				title: file.pathToTitle(filePath)
				url: fileApi.srcToUrl('page', filePath)
				time: fileApi.getCTime('page', filePath)
		return items

	getArchiveList: () ->
		archiveDir = fileApi.getSrcFile('post')
		archiveList = file.dir(archiveDir, true)

		items = []
		archiveList = archiveList.sort (a, b) =>
			return a < b
		archiveList.forEach (filePath) =>
			if file.isHide(filePath)
				return;
			items.push
				title: file.getFileName(filePath)
				url: fileApi.srcToUrl('archive', filePath) + '/'
		return items

	getArchivePostList: (archiveName) ->
		postDir = path.resolve(fileApi.getSrcFile('post'), archiveName)
		fileList = file.dir(postDir)
		
		items = []
		fileList = fileApi.sortByCreateTime('post', fileList)
		fileList.forEach (filePath) =>
			if not file.isMd(filePath)
				return;
			items.push
				title: file.pathToTitle(filePath)
				url: fileApi.srcToUrl('post', filePath)
				time: fileApi.getCTime('post', filePath)
		return items

	getLocals: (type, arg1) ->
		locals =
			site: file.readJSON(path.resolve(projectDir, './blogin.json'))
			pageName: ''
		siteUrl = locals.site.siteUrl
		rssPath = if (siteUrl[siteUrl.length-1] == '/') then 'rss.xml' else '/rss.xml'
		locals.site.rssUrl = siteUrl + rssPath

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
			if file.isHide(archivePath)
				return;
			archiveName = file.getFileName(archivePath)
			archiveDestFile = path.resolve(destDir, archiveName, 'index.html')
			file.write(archiveDestFile, compile(dataApi.getLocals('archive', archiveName)))
			if not keepQuiet
				util.puts('File ' + archiveDestFile + ' created.')

	page: (keepQuiet) ->
		srcDir = fileApi.getSrcFile('page')
		pages = file.dir(srcDir, true)
		compile = jade.compile(fileApi.getJadeFile('page'), 
			filename: path.resolve(templateDir, 'includes')
		)

		pages.forEach (pagePath) =>
			if not file.isMd(pagePath)
				return
			pageTitle = file.pathToTitle(pagePath)
			entry =
				title: pageTitle
				content: file.readMdToHtml(pagePath)
				time: fileApi.getMTime('page', pagePath)
			pageFile = fileApi.srcToDest('page', pagePath)
			file.write(pageFile, compile(dataApi.getLocals('page', entry)))
			if not keepQuiet
				util.puts('File ' + pageFile + ' created.')

	post: (keepQuiet) ->
		srcDir = fileApi.getSrcFile('post')
		posts = file.dir(srcDir)
		compile = jade.compile(fileApi.getJadeFile('post'), 
			filename: path.resolve(templateDir, 'includes')
		)

		posts.forEach (postPath) =>
			if not file.isMd(postPath)
				return
			postTitle = file.pathToTitle(postPath)
			entry =
				title: postTitle
				content: file.readMdToHtml(postPath)
				time: fileApi.getMTime('post', postPath)
			postFile = fileApi.srcToDest('post', postPath)
			file.write(postFile, compile(dataApi.getLocals('post', entry)))
			if not keepQuiet
				util.puts('File ' + postFile + ' created.')

	rss: (keepQuiet) ->
		srcDir = fileApi.getSrcFile('post')
		posts = file.dir(srcDir)
		posts = file.sortByCreateTime(posts)
		locals = dataApi.getLocals('index')
		feedFile = fileApi.getDestFile('rss')
		feed = new RSS
			title: locals.site.name
			description: locals.site.description
			feed_url: path.join(locals.site.siteUrl, '/rss.xml')
			site_url: locals.site.siteUrl
			image_url: locals.site.favicon
			author: locals.site.author

		posts.forEach (postPath) =>
			if not file.isMd(postPath)
				return
			postTitle = file.pathToTitle(postPath)
			feed.item
				title:  postTitle
				description: file.readMdToHtml(postPath)
				url: fileApi.srcToUrl('post', postPath)
				date: fileApi.getMTime('post', postPath)

		file.write(feedFile, feed.xml())
		if not keepQuiet
			util.puts('File ' + feedFile + ' created.')

module.exports = (args) ->
	arg = parseArg(args)
	projectDir = path.resolve(process.cwd(), arg.req[0] || './')
	if not MyUtil.checkProjectDir(projectDir)
		usage.puts('update')
		return
	templateDir = path.resolve(projectDir, './public/template/')

	if not file.exists(templateDir)
		usage.puts('update')
		return
	# rend html
	keepQuiet = arg.opt.indexOf('q') > 0
	rendApi.index(keepQuiet)
	rendApi.archive(keepQuiet)
	rendApi.page(keepQuiet)
	rendApi.post(keepQuiet)
	rendApi.rss(keepQuiet)
	util.puts('Update complete.')

