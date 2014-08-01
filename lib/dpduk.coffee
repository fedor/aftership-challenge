tools = require 'tools'

get_checkpoint = (checkpoint) ->
	# return tracking object
	country_name: checkpoint.trackingEventLocation
	message: checkpoint.trackingEventStatus
	checkpoint_time: checkpoint.trackingEventDate.substring(0, date.length-5)


exports = (tracking_number, callback) ->
	result = checkpoints: []

	url_4_api_id = "http://www.dpd.co.uk/esgServer/shipping/shipment/_/parcel/\
	?filter=id&searchCriteria=deliveryReference%3D#{tracking_number}\
	%26postcode%3D&searchPage=0&searchPageSize=25"
	url_4_tracking_json = "http://www.dpd.co.uk/esgServer/shipping/delivery/\
	?parcelCode=#{tracking_number}"

	# 1. Get API call
	tools.request_json url_4_api_id, (error, json) ->
		return callback error if error
		try
			options =
				url: url_4_tracking_json,
				headers:
					Cookie: "tracking=#{json.obj.searchSession}"
			tools.request_json options, (error, json) ->
				return callback error if error
				try
					points = json.obj.trackingEvent.reverse()
					# Get checkpoints in desired object model
					result.checkpoints = (get_checkpoint p for p in points)
					callback null, result
				catch error
					return callback error
		catch error
			return callback error


# Dev run command
# this.usps('9405903699300184125060')
