BFile = require './BFile'
PathApi = require './PathApi'
marked = require('marked')

marked.setOptions
  gfm: true
  pedantic: false
  sanitize: false

class PostBFile extends BFile
  constructor: (@pwd, @encoding) ->
    super(@pwd, @encoding)
    this.type = 'post'

  getTitle: ->
    content = this.read()
    firstLineLength = content.indexOf('\n')
    return content.slice(0, firstLineLength)

  getEscapeTitle: ->
    return this.constructor.escapeName(str)

  getJadeFile: ->
    return new BFile(PathApi.getJadeFile(@type)).read()

  # '/home/mzhou/blogin/data/posts', '/home/mzhou/blogin'
  #     ==> '/data/posts'
  getUrl: ->
    return PathApi.toUrl(@pwd)

  getHtml: ->
    return marked(this.read())

  createHtml: ->
    dest = PathApi.getDestFile(@type) + this.getEscapeTitle() + '.html'
    new BFile(dest).write(this.getHtml());

PostBFile.createPostFile = (fileName) ->


PostBFile.capitalize = (str) ->
  str[0].toUpperCase() + str.slice(1)


###
unescape name
  'hello-world.md' => 'Hello world'
  'hello-world-border\\-left.md' => 'Hello world border-left.md'
@param {string} str input string
@return {string} 
###
PostBFile.unescapeName = (str) ->
  return str
    .replace(/([^\\])\-/g, '$1 ')
    .replace(/\\-/g, '-')


###
escape name
  'Hello World' => 'hello-world'
  '  Hello   World  ' => 'hello-world'
  'Hello World border-left' => 'hello-world-border\\-left'
@param {string|array} str
@return {string}
###
PostBFile.escapeName = (str) ->
  if typeof (str) is 'object'
    words = str
  else
    words = [str]
  escapedWords = []

  words.forEach (word, i) ->
    escapedWords[i] = word.replace(/\-/g, '\\$1')
  filename = escapedWords.join('-').toLowerCase()

exports = PostBFile
