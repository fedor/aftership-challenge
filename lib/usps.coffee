tools = require './tools'


get_checkpoint = (checkpoint) ->
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
			# Ensure we are not "falling apart",
			# try Simple scenario parsing instead 

	if not date_set
		# Simple scenario with pre-formatted date string
		try
			chunks = checkpoint.split ', '
			message = chunks[0]
			month_date = chunks[1]
			year = chunks[2]
			day_time = if chunks.length > 3 then chunks[3] else "12:00 am"
		catch
			# We failed to parse checkpoint string
			# Here we need two actions:
			# 1. Send email with unparsed string
			# 2. Set default/backup values
			# 2.1 Better to have full checkpoint string in the message
			#     instead of error message
			message = checkpoint
			# 2.2 But timestamp is not known
			month_date = '1 January'
			day_time = '12:00 am'
			year = '1990'

	date = tools.utc_date "#{month_date} #{year} #{day_time}"

	# return tracking object
	country_name: ''
	message: message
	checkpoint_time: date


exports.usps = (tracking_number, callback) ->
	api_key = "971NA0002771"
	result = checkpoints: []

	url = "http://production.shippingapis.com/ShippingAPI.dll?API=TrackV2&XML=\
		<TrackRequest USERID=\"#{api_key}\">\
			<TrackID ID=\"#{tracking_number}\"></TrackID>\
		</TrackRequest>"

	# Make API call
	tools.request_xml url, (error, body) ->
		return callback error if error

		try
			track_info = body.TrackResponse.TrackInfo[0]
			track_summary = track_info.TrackSummary[0]
			points = track_info.TrackDetail.reverse()
			points.push track_summary
			
			# Get checkpoints in desired object model
			result.checkpoints = (get_checkpoint point for point in points)
			callback null, result
		catch error
			# Checkpoint parsing failed
			callback error


# Dev run command
# exports.usps('9405903699300184125060')
