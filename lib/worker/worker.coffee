fivebeans   = require 'fivebeans'
Beanworker  = require('fivebeans').worker
redis       = require 'redis'
logger      = require 'winston'
beans_tools = require './beans_tools'
Courier     = require '../couriers/index'
MongoClient = require('mongodb').MongoClient
crypto      = require 'crypto'


worker_id = crypto.createHash('md5').update(new Date().getTime().toString()).digest('hex')
config = {
	"id":   "worker_#{worker_id}",
	"host": "127.0.0.1",
	"port": 11300,
	"tubes": ["requests_flow", "wait_list"],
	"ignoreDefault": true
}

# Code layout explanation for 'Handlers': https://github.com/ceejbot/fivebeans#handlers

# set magic numbers
calls_per_sec = 2
max_calls_number = 20

# Set logging
logger.remove logger.transports.Console
logger.add    logger.transports.Console, 'timestamp': true

# Set mongo connection
MongoClient.connect 'mongodb://127.0.0.1:27017/bucket', (err, db) ->

	# Set beanstalkd & Redis connections
	beans_client = new fivebeans.client()
	redis_client = redis.createClient()

	beans_client.on 'connect', () ->
		# User send requests here
		RequestsFlowHandler = () ->
			this.type = 'requests_flow'  # Same as tube name


		# Used by requests_flow and recursively by itself if number of requests is above limits
		WaitListHandler = () ->
			this.type = 'wait_list'  # Same as tube name


		start_time = () ->
			start_time = new Date().getTime()
			logger.info "Getting tracking of #{slug} - #{payload.number} (#{start_time})"
			return start_time


		get_wait_request = (slug) ->
			() ->
				redis_client.get "calls_number:#{slug}", (calls_number, err) ->
					if calls_number >= max_calls_number
						return

					redis_client.lpop "wait_list:#{slug}", (err, number) ->
						if number == null
							return
						payload = {slug: slug, number: number}
						Courier[slug] tracking_number, courier_callback(callback, payload, start_time())


		error_callback = (error, message, callback) ->
			logger.error "#{message}: #{error}"
			callback 'error'


		WaitListHandler.prototype.work = (payload, callback) ->
			slug = payload.slug
			# Ensures we will not get into race condition
			redis_client.watch  "wait_list_activated:#{slug}"
			redis_client.exists "wait_list_activated:#{slug}", (err, reply) ->
				if reply == 1
					# Wait list already activated
					return callback 'success'
				
				redis_multi = redis_client.multi()
				redis_multi.set    "wait_list_activated:#{slug}", 1
				redis_multi.expire "wait_list_activated:#{slug}", 10
				redis_multi.llen   "wait_list:#{slug}"
				redis_multi.exec (err, replies) ->
					if err == null and replies == null
						# Race condition, someone activated wait list first
						return callback 'success'

					len     = parseInt replies[1]
					seconds = Math.ceil(len / calls_per_sec)
					for sec in [1..seconds]
						for call in [1..calls_per_sec]
							setTimeout get_wait_request(slug), sec*1000

					redis_client.expire "wait_list_activated:#{slug}", seconds, (err, reply) ->
						beans_tools.put_wrap beans_client, 'wait_list', 0, seconds, 10, payload
						callback 'success'


		add_request_to_waiting_line = (payload) ->
			redis_client.rpush "wait_list:#{payload.slug}", payload.number, (err, reply) ->
				beans_tools.put_wrap beans_client, 'wait_list', 0, 0, 10, {slug: payload.slug}


		courier_callback = (bean_callback, payload, start_time) ->
			(err, tracking) ->
				try
					redis_client.decr "calls_number:#{slug}"

					if err
						logger.error "issue in courier callback: #{err}"
						return bean_callback 'error'

					slug         = payload.slug
					number       = payload.number

					checkpoints  = tracking.checkpoints
					last_point   = checkpoints[checkpoints.length-1]
					last_country = last_point.country_name.toLowerCase()
					last_message = last_point.message.toLowerCase()
					if last_message.indexOf("delivered") > -1
						delivered = true
					else if slug == "hkpost" and last_country != "hong kong" and last_message.indexOf("left hong kong") > -1
						delivered = true
					else
						delivered = false

					# 4.5 If delivered save to Mongo DB, if not retry in 3 hours
					if delivered
						tracking.slug = slug
						tracking.tracking_number = number
						db.collection('tracking').insert tracking, (err, docs) ->
							if err
								logger.error "insertion to Mongo DB failed: #{err}"
								return bean_callback 'error'
							delta_time = new Date().getTime() - start_time
							logger.info "#{slug} - #{number} delivered and saved to mongo,\
							             took #{delta_time} ms. (#{start_time})"
					else
						beans_tools.put_wrap beans_client, 'requests_flow', 0, 3600*3, 60, payload
						logger.info "#{slug} - #{number} is not delivered yet,\
						             took #{delta_time} ms. (#{start_time})"

					# 5. Finish the job
					bean_callback 'success'
				catch error
					logger.error "issue on handling courier callback data: #{error}"
					return bean_callback 'error'

		RequestsFlowHandler.prototype.work = (payload, callback) ->
			try
				logger.info "Job recieved, payload: #{JSON.stringify payload}"
				slug = payload.slug

				# 1. Get total simultaneous calls for slug
				# 2. Get number of calls per second
				redis_multi = redis_client.multi()
				redis_multi.llen "wait_list:#{slug}"
				redis_multi.incr "calls_number:#{slug}"
				redis_multi.incr "sec_calls:#{slug}"
				redis_multi.exec (err, replies) ->
					try
						return error_callback(err, "redis error", callback) if err

						wait_count   = parseInt(replies[0])
						calls_number = replies[1]
						sec_calls    = replies[2]

						if sec_calls == 1
							redis_client.expire "sec_calls:#{slug}", 1

						# 3. If a number of max semultaneous calls per slug reached
						# or if we out of "per second" quota add request to waiting line
						if wait_count > 0 or calls_number > max_calls_number or sec_calls > calls_per_sec
							redis_multi.decr "calls_number:#{slug}"
							redis_multi.decr "sec_calls:#{slug}"
							redis_multi.exec (err, replies) ->
								return error_callback(err, "redis error", callback) if err
								add_request_to_waiting_line payload
								return callback 'success'
							return

						# 4 Job reserved, get tracking info
						Courier[slug] payload.number, courier_callback(callback, payload, start_time())
					catch error
						error_callback(error, "issue on handling requests_flow tube", callback)

			catch error
				error_callback(error, "issue on handling requests_flow tube", callback)

		# Run Beanstalkd worker
		config.handlers = 
			requests_flow: new RequestsFlowHandler()
			wait_list: new WaitListHandler()
		worker = new Beanworker config
		worker.start config.tubes


	beans_client.connect()