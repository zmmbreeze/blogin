util = require('util')
clc  = require('cli-color')
# command description
commandsDesc =
  deploy: 'Generate static files and deploy to github.'
  server: 'Start a server on http://localhost:3000 .'
  update: 'Generate the static files.'
  post: 'New post.'
  page: 'New page.'
  init: 'Init the project directory.'
  help: 'Display help.'
#command usage
commandsUsage =
  deploy: 'Generate static files and deploy to github.'
  server: 'Start a server on http://localhost:3000 .'
  update: 
    '''
    [-q] [project directory]
    [-q]                    Use quiet mod, do not print log.
    [project directory]     If not set directory then use current directory.
    '''
  post: 
    '''
    [-f] <postname>

    <postname> Post name also file name, can't be 'index'
    -f         Force to rewrite exist file.
    '''
  page:
    '''
    [-f] <pagename>

    -f     Force to rewrite exist file.
    '''
  init: 'Init the project directory.'
# create space to display
createSpace = (command, maxLength) ->
  spaceLength = maxLength - command.length
  str = ''
  i = 0
  while spaceLength > i
    str += ' '
    i++
  return str

module.exports =
  # help command
  help: () ->
    util.puts(require('../package.json').name + ' is ' + require('../package.json').description)
    util.puts('')
    # calculate maxLength
    maxLength = 1
    for command of commandsDesc
      if command.length > maxLength
        maxLength = command.length
    maxLength += 5; # add space
    # output commands description
    for command, description of commandsDesc
      util.print('   ' + clc.yellow(command) + createSpace(command, maxLength))
      console.log(description)
    util.puts('')

  # show usage
  puts: (commandName) ->
    util.puts('Usage: blogin ' + commandName + ' ' + commandsUsage[commandName])
