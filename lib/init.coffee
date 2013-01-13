path = require('path')
moment = require('moment')
util = require('util')
parseArg = require('./arg').parse
MyUtil = require('./MyUtil')
usage = require('./usage')
file = require('./file')

projectDir = './'

module.exports = (args) ->
	arg = parseArg(args)
	projectDir = path.resolve(process.cwd(), arg.req[0] || './')

	if file.copy(path.resolve(__dirname, '../prototype/'), projectDir)
		util.puts('Blog created at "' + projectDir + '".')
	else
		util.puts('Directory "' + projectDir + '" existed!')
		util.puts('Still create blog? (Y/N)')
		process.stdin.resume();
		process.stdin.setEncoding('utf8');

		yesCallback = () ->
			file.copy(path.resolve(__dirname, '../prototype/'), projectDir, true)
			util.puts('Blog created at "' + projectDir + '".')
			util.puts('Init complete.')
			process.exit()

		noCallback = () ->
			process.exit()

		callback = () ->
			util.puts('Please input Y/N.')
			process.exit()

		process.stdin.on 'data', (chunk) =>
			if chunk[chunk.length - 1] isnt '\n'
				callback()
				return 
			switch chunk.slice(0, -1)
				when 'Y'
					yesCallback()
				when 'y'
					yesCallback()
				when 'yes'
					yesCallback()
				when 'YES'
					yesCallback()
				when 'N'
					noCallback()
				when 'n'
					noCallback()
				when 'no'
					noCallback()
				when 'NO'
					noCallback()
				else
					callback()