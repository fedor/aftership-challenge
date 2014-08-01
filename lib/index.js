usps = require('./usps');
hkpost = require('./hkpost');

(function() {
	function Courier() {
		this.usps = usps;
		this.hkpost = hkpost;

		this.dpduk = function(tracking_number) {
			var tracking_result = {}; // save your result to this object

			// do your job here
			return tracking_result;

		};
	}

	module.exports = new Courier();
}());

