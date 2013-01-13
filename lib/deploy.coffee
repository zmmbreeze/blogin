path = require('path')
moment = require('moment')
util = require('util')
parseArg = require('./arg').parse
MyUtil = require('./MyUtil')
usage = require('./usage')

projectDir = './'

exec = (command, args, callback) ->
	MyUtil.spawn
		command: command
		args: args
		options:
			cwd: projectDir
		exit: (code) ->
			if code is 0 and callback
				callback()

module.exports = (args) ->
	arg = parseArg(args)
	projectDir = path.resolve(process.cwd(), arg.req[0] || './')
	if not MyUtil.checkProjectDir(projectDir)
		usage.puts('deploy')
		return

	exec 'git', ['add', '-A'], () =>
		msg = 'Update:' + moment().format('YYYY-MM-DD hh:mm:ss')
		args = ['commit', '-m', msg]
		exec 'git', args, () =>
			exec 'git', ['push'], () =>
				util.puts('Deploy complete.')