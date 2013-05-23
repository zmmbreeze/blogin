util = require('util')
clc  = require('cli-color')
# command description
commandsDesc =
	deploy: 'Deploy static files to git server, like github.'
	server: 'Start a server on http://localhost:3000 .'
	update: 'Generate the static files.'
	post: 'Create post.'
	page: 'Create page.'
	init: 'Init the blog directory.'
	help: 'Display help.'
#command usage
commandsUsage =
	deploy: ''
	server: 'Start a server on http://localhost:3000 .'
	update: 
		'''
		[-q] [blog directory]

		[-q]                 Use quiet mod, do not print log.
		[blog directory]     If not set directory then use current directory.
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
	init:
		'''
		[blog directory]

		[blog directory]     If not set directory then use current directory.
		'''
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
		package = require('../package.json')
		util.puts(package.name + ' is ' + package.description)
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
			util.puts(description)
		util.puts('')

	# show usage
	puts: (commandName) ->
		util.puts('Usage: blogin ' + commandName + ' ' + commandsUsage[commandName])
