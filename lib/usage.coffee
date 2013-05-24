util = require('util')
clc  = require('cli-color')
# command description
commandsDesc =
	deploy: 'Deploy static files to git server, like github.'
	server: 'Start a server on http://localhost:3000 .'
	update: 'Generate the static files.'
	post: 'Create post, show post tree, delete post.'
	page: 'Create page, show page tree, delete page.'
	init: 'Init the blog directory.'
	help: 'Display help.'
	trash: 'Show trash tree, recovery deleted file.'
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

		<postname> [optional] Post name also file name, can't be 'index'
		-f         Force to rewrite exist file.
		
		`blogin post` to show post tree or delete post.
		'''
	page:
		'''
		[-f] <pagename>

		-f     Force to rewrite exist file.
		
		`blogin page` to show page tree or delete page.
		'''
	init:
		'''
		[blog directory]

		[blog directory]     If not set directory then use current directory.
		'''
	trash:
		'''
		`blogin trash` show trash tree, recovery deleted file.
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
	help: (args) ->
		arg = parseArg(args)
		# for `blogin help commandName`
		if (args.length isnt 0 && arg.req.length isnt 0)
			commandName = arg.req[0]
			if (commandsUsage[commandName])
				this.puts(commandName)
				return

		# for `blogin help`
		pacage = require('../package.json')
		util.puts(pacage.name + ' is ' + pacage.description)
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
