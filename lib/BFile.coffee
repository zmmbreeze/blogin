fs = require 'fs-extra'
path = require 'path'
moment = require 'moment'


###
BFile
###
class BFile
  constructor: (@pwd, @encoding) ->

  _slice: Array.prototype.slice

  this.toArray = (argument, from, to) ->
    this._slice.call(argument, from, to)

  getState: ->
    fs.statSync(@pwd)

  isFile: ->
    this.getState().isFile()

  isDirectory: ->
    this.getState().isDirectory()

  exists: ->
    fs.existsSync(this.pwd)

  create: (isDirectory) ->
    if (this.exists())
      return this
    else
      if (isDirectory)
        this.constructor.mkdir(@pwd)
      else
        this.constructor.touch(@pwd, @encoding)

  getFileName: ->
    @pwd.replace(path.dirname(@pwd) + '/', '')

  getBaseName: ->
    fileName = this.getFileName()
    lastPoint = fileName.lastIndexOf('.')
    lastPoint = if (lastPoint == -1) then 0 else lastPoint
    return fileName.substring(0, lastPoint)

  getExtension: ->
    fileName = this.getFileName()
    lastPoint = fileName.lastIndexOf('.')
    lastPoint = if (lastPoint == -1) then 0 else lastPoint
    return fileName.slice(lastPoint)

  getCTime: (format = 'YYYY-MM-DD') ->
    stat = fs.statSync(filePath)
    moment(stat.ctime).format(format)

  lastModified: (format = 'YYYY-MM-DD') ->
    stat = fs.statSync(filePath)
    moment(stat.mtime).format(format)

  getChildren: (recursive) ->
    return this.constructor.getChildren(recursive)

  getChildrenDir: (recursive) ->
    return this.constructor.getChildrenDir(recursive)

  write: (content) ->
    this.create()
    fs.writeFileSync(@pwd, content, @encoding)
    return this

  read: ->
    this.create()
    return fs.readFileSync(@pwd, @encoding)

  readByJSON: ->
    content = this.read()
    return JSON.parse(content)

  append: (content) ->
    this.create()
    fs.appendFileSync(@pwd, content, @encoding)
    return this

  copyTo: (dest) ->
    content = this.read()
    new BFile(dest).write(content)
    return this




BFile.getChildrenDir = (recursive) ->
  filePaths = this.getChildren(recursive)
  re = []
  for file in filePaths
    do (file) ->
      if fs.statSync(file).isDirectory()
        re.push(file)
  return re

BFile.getChildren = (recursive) ->
  src = this.pwd
  return [] if not fs.existsSync(src)

  self = this
  filePaths = []
  fs.readdirSync(src).forEach (filename, i) =>
    # resolve file name to full path
    filename = path.resolve(src, filename)

    if fs.statSync(filename).isDirectory()
      if recursive
        filePaths = filePaths.concat(self.getChildren(recursive))
      else
        filePaths.push(filename)
    else
      filePaths.push(filename)
  return filePaths

BFile.mkdir = (dest) ->
  dest = path.resolve(dest)
  parent = path.dirname(dest)

  if fs.existsSync(parent)
    fs.mkdirSync(dest)
  else
    this.mkdir(parent)
    fs.mkdirSync(dest)

BFile.touch = (dest, encoding) ->
  dest = path.resolve(dest)
  parent = path.dirname(dest)

  if fs.existsSync(parent)
    fs.writeFileSync(dest, '', encoding)
  else
    this.mkdir(parent)
    fs.writeFileSync(dest, '', encoding)

exports.File = BFile