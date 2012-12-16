path = require('path')

PathApi =
  templateDir: './public/template/'
  projectDir: './'
  getJadeFile: (type) ->
    path.resolve(this.templateDir, type + '.jade')

  getSrcFile: (type) ->
    switch type
      when 'page'
        path.resolve(this.projectDir, 'data/pages')
      else
        path.resolve(this.projectDir, 'data/posts')

  getDestFile: (type) ->
    switch type
      when 'archive'
        path.resolve(this.projectDir, 'post')
      when 'post'
        path.resolve(this.projectDir, 'post')
      when 'page'
        path.resolve(this.projectDir, 'page')
      else
        path.resolve(this.projectDir, 'index.html')

  toUrl: (filePath) ->
    '/' + path.relative(this.projectDir, filePath)

exports = PathApi