PostBFile = require './PostBFile'

class PageBFile extends PostBFile
  constructor: (@pwd, @encoding) ->
    super(@pwd, @encoding)
    this.type = 'page'

exports = PageBFile