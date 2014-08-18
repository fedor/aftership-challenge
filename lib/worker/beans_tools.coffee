logger     = require 'winston'

# Set logging
logger.remove logger.transports.Console
logger.add    logger.transports.Console, 'timestamp': true

default_put_callback = (err, jobid) ->
	logger.info "Sent #{jobid} job"

exports.put_wrap = (emitter, tube, priority, delay, ttr, payload, callback=default_put_callback) ->
	emitter.use tube, (err, tube) ->
		load = {type: tube, payload: payload}
		emitter.put priority, delay, ttr, JSON.stringify(load), callback