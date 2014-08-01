request = require 'request'
tools =   require './tools'

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


get_checkpoint = (checkpoint) ->
	date = utc_date "#{month_date} #{year} #{day_time}"

	# return tracking object
	country_name: ''
	message: message
	checkpoint_time: date


exports = (tracking_number, callback) ->
	tracking_result = checkpoints: []

	url_4_datail = "http://app3.hongkongpost.hk/CGI/mt/e_detail4.jsp?\
		mail_type=ems_out&tracknbr=#{tracking_number}&\
		localno=#{tracking_number}"
	# url_4_summary = "http://app3.hongkongpost.hk/CGI/mt/mt4result.jsp"
	# form_4_summary = tracknbr: 'EA999580311HK'
	url_4_summary = "http://app3.hongkongpost.hk/CGI/mt/mtZresult.jsp?\
		tracknbr=#{tracking_number}"

	tools.request_html_get url_4_summary, (error, dom) ->
		return callback error if error

# Dev run command
exports('EA999580311HK')
