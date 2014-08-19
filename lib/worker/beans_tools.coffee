logger     = require 'winston'

# Set logging
logger.remove logger.transports.Console
logger.add    logger.transports.Console, 'timestamp': true

default_put_callback = (tube, payload, delay, ttr, who) ->
	return (err, jobid) ->
		logger.info "\tsent job ##{jobid} to #{tube}, #{delay}s. delay, #{ttr}s. TTR,
			payload: #{JSON.stringify payload}#{who}"

exports.put_wrap = (emitter, tube, priority, delay, ttr, payload, who="", callback=null) ->
	emitter.use tube, (err, tube) ->
		load = {type: tube, payload: payload}
		if who != ""
			who = ", by #{who}"

		if callback == null
			callback = default_put_callback(tube, payload, delay, ttr, who)

		emitter.put priority, delay, ttr, JSON.stringify(load), callback