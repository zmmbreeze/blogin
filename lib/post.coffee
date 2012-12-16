util = require('util')
moment = require('moment')
file = require('./file')
usage = require('./usage')
parseArg = require('./arg').parse


module.exports = (args, dirname) ->
  arg = parseArg(args)
  if (args.length is 0) or (arg.req.length is 0)
    usage.puts('post')
    return

  filename = file.titleToPath(arg.req)
  if filename is 'index.md'
    usage.puts('post')
    return
  # word sperate by one space
  postTitle = arg.req.join(' ')
  # add head
  content = postTitle + '\n======\n'
  # full file name
  dirname = (dirname || './data/posts/{year}/').replace('{year}', moment().format('YYYY'))
  dataFile = dirname + filename

  # force write or not
  if ~arg.opt.indexOf('f')
    file.write(dataFile, content)
    util.puts('Created at ' + dataFile)
  else
    if file.writeIfNotExist(dataFile, content)
      util.puts('Created at ' + dataFile)
    else
      util.puts('Fail to create, file "' + dataFile + '" was existed.\nUse [-f] option to rewrite the file.')

