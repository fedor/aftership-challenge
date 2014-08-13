tools =   require './tools'


# This function is SAFE, would always return array
points_from_detailed_dom = (dom) ->
	try
		tokens = (i.children[0].data for i in dom('.detail td').get().slice 3)
		points = []
		while tokens.length
			try
				detail = tokens.splice 0, 3
				points.push
					message:         detail[2]
					country_name:    detail[1]
					checkpoint_time: tools.utc_date detail[0]
			catch
				# Failed to parse checkpoint, but we don't want to fall apart
		return points
	catch
		return []


# This function is NOT SAFE, could throw exception
points_from_summary_dom = (dom) ->
	detail = dom('#clfContent').text().split('\n').slice 29, 31
	dst_detail = detail[0].trim().split ' - '
	msg = detail[1]

	dst = null
	if dst_detail[0] == "Destination"
		dst = dst_detail[1]

	time = null
	for token in msg.split(' ').reverse()
		try
			time = tools.utc_date token
			break  # Found date, exit the loop
		catch
			# Time not found yet

	if not msg
		throw new Error 'Message not avalible'
	
	# Set stub value if date is not avalible
	if not time
		time = tools.utc_date '1-Jan-1990'

	[
		message:         msg
		checkpoint_time: time
		country_name:    if dst then dst else 'not avalible'
	]


exports.hkpost = (tracking_number, callback) ->
	tracking_result = checkpoints: []

	# There is two possible scenarious
	# 1. Outside HK tracking possible
	# 2. Outside HK tracking is not provided
	# We try to get detail info first, if failed try to get basic info

	url_4_datail = "http://app3.hongkongpost.hk/CGI/mt/e_detail4.jsp?\
		mail_type=ems_out&tracknbr=#{tracking_number}&\
		localno=#{tracking_number}"

	tools.request_html_get url_4_datail, (error, dom) ->
		return callback error if error
		
		points = points_from_detailed_dom dom
		if points.length > 0
			tracking_result.checkpoints = points.reverse()
			return callback null, tracking_result

		url_4_summary = "http://app3.hongkongpost.hk/CGI/mt/mtZresult.jsp?\
			tracknbr=#{tracking_number}"

		tools.request_html_get url_4_summary, (error, dom) ->
			return callback error if error
			try
				tracking_result.checkpoints = points_from_summary_dom dom
				return callback null, tracking_result
			catch error
				return callback error


# Dev run commands

# Full info avalible
# exports.hkpost('EA999580311HK')

# Summary only avalible
# exports.hkpost('RT215770195HK')
