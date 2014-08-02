request = require 'request'
cheerio = require 'cheerio'
{parseString} = require 'xml2js'


get = (request_args..., callback) ->
	request.apply this, request_args.concat (error, response, body) ->
		# HTTP call failed
		return callback error if error
		if response.statusCode != 200
			return callback new Error "HTTP returned #{ response.statusCode }"

		callback null, body


exports.request_xml = (request_args..., callback) ->
	get.apply null, request_args.concat (error, body) ->
		return callback error if error

		parseString body, callback  # Parse XML


exports.request_json = (request_args..., callback) ->
	get.apply null, request_args.concat (error, body) ->
		return callback error if error

		try
			obj = JSON.parse body
			return callback null, obj
		catch error
			return callback error


exports.request_html_get = (request_args..., callback) ->
	get.apply null, request_args.concat (error, body) ->
		return callback error if error

		callback null, cheerio.load(body)  # get DOM


exports.request_form_submit = (request_args..., callback) ->
	request.post.apply request, request_args.concat (error, response, body) ->
		# HTTP call failed
		return callback error if error
		if response.statusCode != 200
			return callback new Error "HTTP returned #{ response.statusCode }"

		callback null, cheerio.load(body)  # get DOM