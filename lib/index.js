usps = require('./usps');
hkpost = require('./hkpost');
dpduk = require('./dpduk');

(function() {
	function Courier() {
		this.usps = usps.usps;
		this.hkpost = hkpost.hkpost;
		this.dpduk = dpduk.dpduk;
	}

	module.exports = new Courier();
}());

