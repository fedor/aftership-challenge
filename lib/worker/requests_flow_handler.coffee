fivebeans   = require 'fivebeans'
Beanworker  = require('fivebeans').worker
config      = require './config.json'
redis       = require 'redis'
logger      = require 'winston'
beans_tools = require './beans_tools'
Courier     = require '../couriers/index'
MongoClient = require('mongodb').MongoClient

# set magic numbers
calls_per_sec = 2
max_calls_number = 20

# Set logging
logger.remove logger.transports.Console
logger.add    logger.transports.Console, 'timestamp': true

# Set mongo connection
MongoClient.connect 'mongodb://127.0.0.1:27017/bucket', (err, db) ->

	# Set beanstalkd connection
	beans_client = new fivebeans.client()

	# Set Redis connection
	redis_client = redis.createClient()

	# Code layout explanation: https://github.com/ceejbot/fivebeans#handlers
	# module.exports = () ->
	RequestsFlowHandler = () ->
		this.type = 'requests_flow'  # Same as tube name

	RequestsFlowHandler.prototype.work = (payload, callback) ->
		logger.info "Job recieved, payload: #{JSON.stringify payload}"
		slug = payload.slug

		redis_multi = redis_client.multi()

		# 1. Get total simultaneous calls for slug
		# 2. Get number of calls per second
		redis_multi.get "calls_number:#{slug}"
		redis_multi.get "last_sec_calls:#{slug}"

		redis_multi.exec (err, replies) ->
			calls_number   = if replies[0] == null then 0 else parseInt(replies[0])
			last_sec_calls = if replies[1] == null then 0 else parseInt(replies[1])

			# 3. If a number of max semultaneous calls per slug reached
			# or if we out of "per second" quota add request to waiting line
			if calls_number >= max_calls_number or last_sec_calls >= calls_per_sec
				add_request_to_waiting_line payload
				return callback 'success'

			redis_multi = redis_client.multi()

			# 5. Perform getting track info
			# 5.1 Increment total calls number
			# 5.2 Increment current second calls number
			redis_multi.incr "calls_number:#{slug}"
			redis_multi.incr "last_sec_calls:#{slug}"

			redis_multi.exec (err, replies) ->
				calls_number   = if replies[0] == null then 0 else parseInt(replies[0])
				last_sec_calls = if replies[1] == null then 0 else parseInt(replies[1])

				# 5.3 Check if race condition occured, if yes retry request in 1 sec
				if calls_number > max_calls_number or last_sec_calls > calls_per_sec
					beans_tools.put_wrap beans_client, 'requests_flow', 0, 1, 60, payload
					return redis_client.decr "calls_number:#{slug}", (err, reply) ->
						callback 'success'
					
				# 5.4 Job reserved, get tracking info
				start_time = new Date().getTime()
				tracking_number = payload.number
				logger.info "Getting tracking of #{slug} - #{tracking_number} (#{start_time})"
				Courier[slug] tracking_number, (err, tracking) ->
					last_msg = tracking.checkpoints[tracking.checkpoints.length-1].message.lower()
					delivered = false

					if last_msg.indexOf("delivered") > -1
						delivered = true
					else if slug == "hkpost"
						last_dst = tracking.checkpoints[tracking.checkpoints.length-1].country_name
						if last_msg.indexOf("left hong kong") > -1 and last_dst != "Hong Kong"
							delivered = true

					# 5.5 If delivered save to Mongo DB, if not retry in 3 hours
					if delivered
						# TODO: save results to mongo
						tracking.slug = slug
						tracking.tracking_number = tracking_number

						db.collection('tracking').insert tracking, (err, docs) ->
							delta_time = new Date().getTime() - start_time
							logger.info "#{slug} - #{tracking_number} delivered and saved to mongo,\
								took #{delta_time} ms. (#{start_time})"
					else
						beans_tools.put_wrap beans_client, 'requests_flow', 0, 3600*3, 60, payload
						logger.info "#{slug} - #{tracking_number} is not delivered yet,\
							took #{delta_time} ms. (#{start_time})"

					# 6. Finish the job
					callback 'success'


	# Run Beanstalkd worker
	config.handlers = {requests_flow: new RequestsFlowHandler()}
	worker = new Beanworker config
	worker.start config.tubes
