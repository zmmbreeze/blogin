BFile = require './BFile'
PostBFile = require './PostBFile'
PageBFile = require './PageBFile'
PathApi = require './PathApi'

DataApi =
  getPostList: () ->
    postDir = PathApi.getSrcFile('post')
    fileList = File.getChildren(postDir, true)
    
    items = []
    fileList.forEach (filePath) =>
      pFile = new PostBFile(filePath);
      if not (pFile.getExtension() == '.md')
        return;
      items.push
        title: pFile.getTitle()
        url: pFile.toUrl()
    return items

  getPageList: () ->
    pageDir = PathApi.getSrcFile('page')
    fileList = File.getChildren(pageDir, true)
    
    items = []
    fileList.forEach (filePath) =>
      pFile = new PageBFile(filePath);
      if not (pFile.getExtension() == '.md')
        return;
      items.push
        title: pFile.getTitle()
        url: pFile.toUrl()
    return items

  getArchiveList: () ->
    archiveDir = PathApi.getSrcFile('post')
    archiveList = File.getChildren(archiveDir)

    items = []
    archiveList.forEach (filePath) =>
      file = new ArchiveBFile(filePath);
      items.push
        title: file.getFileName()
        url: file.toUrl()
    return items

  getArchivePostList: (archiveName) ->
    postDir = path.resolve(PathApi.getSrcFile('post'), archiveName)
    fileList = File.getChildren(postDir, true)
    
    items = []
    fileList.forEach (filePath) =>
      if not (new BFile(filePath).getExtension() == '.md')
        return;
      items.push
        title: file.pathToTitle(filePath)
        url: PathApi.srcToUrl('post', filePath)
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