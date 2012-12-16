PostBFile = require './PostBFile'

class ArchiveBFile extends PostBFile
  constructor: (@pwd, @encoding) ->
    super(@pwd, @encoding)
    this.type = 'archive'

  toUrl: () ->
    return super() + '/'

exports = ArchiveBFile