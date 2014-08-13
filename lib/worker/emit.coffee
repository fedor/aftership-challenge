fivebeans   = require 'fivebeans'
winston     = require 'winston'
beans_tools = require './beans_tools'

winston.remove winston.transports.Console
winston.add    winston.transports.Console, 'timestamp': true

emitter = new fivebeans.client()

emitter.on 'connect', () ->
	emitter.use 'requests_flow', (err, tube) ->
		winston.info "using #{tube}"

		beans_tools.put_wrap emitter, tube, 0, 0, 60, {'slug': 'dpduk', 'number': '15502370264989N'}
		# put_wrap emitter, tube, 0, 0, 60, ['payload 2']

		# process.exit()

emitter.connect()