request = require 'request'
{parseString} = require 'xml2js'
user_id = "971NA0002771"


# from goo.gl/RyLeWV
utc_date = (date_string) ->
	date = new Date date_string
	date = new Date Date.UTC(
		date.getFullYear(),
		date.getMonth(),
		date.getDate(),
		date.getHours(),
		date.getMinutes(),
		date.getSeconds())
	date = date.toISOString()
	date = date.substring(0, date.length-5)


usps_checkpoint = (checkpoint) ->
	date_set = false
	chunks = checkpoint.split ' at '

	if chunks.length > 1
		# Most likely complex scenario without pre-formatted date string
		try
			message = chunks[0]
			chunks = chunks[1].split ' on '
			day_time = chunks[0]
			chunks = chunks[1].split ', '
			month_date = chunks[0]
			chunks = chunks[1].split ' '
			year = chunks[0]
			date_set = true
		catch
			# ensure we are not "falling apart"

	if not date_set
		# Simple scenario with pre-formatted date string
		chunks = checkpoint.split ', '
		message = chunks[0]
		month_date = chunks[1]
		year = chunks[2]
		day_time = if chunks.length > 3 then chunks[3] else "12:00 am"

	date = utc_date "#{month_date} #{year} #{day_time}"

	# return tracking object
	country_name: ''
	message: message
	checkpoint_time: date


exports.usps = (tracking_number, callback) ->
	tracking_result = 
		checkpoints: []

	url = "http://production.shippingapis.com/ShippingAPI.dll?API=TrackV2&XML=\
		<TrackRequest USERID=\"#{ user_id }\">\
			<TrackID ID=\"#{ tracking_number }\"></TrackID>\
		</TrackRequest>"

	request(url, (error, response, body) ->
		if !error and response.statusCode == 200
			parseString body, (err, result) ->
				if err
					callback err

				try
					checkpoints = result.TrackResponse.TrackInfo[0].TrackDetail
					last = result.TrackResponse.TrackInfo[0].TrackSummary[0]
					checkpoints.unshift last
					
					for checkpoint in checkpoints
						tracking_result.checkpoints.unshift usps_checkpoint(checkpoint)

				catch error
					callback error

				callback null, tracking_result
		else if error
			callback error
		else
			callback new Error "HTTP returned #{ response.statusCode }"
	)

# Dev run command
# this.usps('9405903699300184125060')
