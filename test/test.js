var should = require('should'),
	_ = require('underscore'),
	Courier = require('../lib/couriers/index');

describe('Test: .is', function() {

	// Courier: http://www.usps.com
	// Hints: You can apply the API from their web site
	// Time need: less than an hour if you have the api key

	describe('Track @ usps(\'9405903699300184125060\')', function() {

		var usps = {
			checkpoints: [
				// Modified by Fedor

				// {
				// 	country_name: '',
				// 	message: 'Delivered',
				// 	checkpoint_time: '2014-05-16T12:00:00'
				// }

				{
					checkpoint_time: "2014-05-13T00:00:00",
					country_name: "",
					message: "Pre-Shipment Info Sent to USPS"
				}, {
					checkpoint_time: "2014-05-15T15:22:00",
					country_name: "",
					message: "Arrived at Post Office"
				}, {
					checkpoint_time: "2014-05-16T09:16:00",
					country_name: "",
					message: "Sorting Complete"
				}, {
					checkpoint_time: "2014-05-16T09:26:00",
					country_name: "",
					message: "Out for Delivery"
				}, {
					checkpoint_time: "2014-05-16T12:00:00",
					country_name: "",
					message: "Your item was delivered"
				}
			]
		};
		it('Expect return true', function(done) {
			Courier.usps('9405903699300184125060', function(err, result) {
				if (err) return done(err);
				result.should.eql(usps);
				done();
			});
		});
	});

	// Courier: http://www.hongkongpost.com/
	// Hints: There is no official API from hongkongpost, but you may use web or other method to get the result easily.
	// Time need: less than an hour if you find the correct way

	describe('Track @ hkpost(\'EA999580311HK\') — detailed tracking info', function() {

		var hkpost_1 = {
			checkpoints: [
				{
					checkpoint_time: "2014-07-31T00:00:00",
					country_name: "United States of America",
					message: "Delivered."
				}, {
					checkpoint_time: "2014-07-31T00:00:00",
					country_name: "United States of America",
					message: "Arrived the delivery office and is being processed."
				}, {
					checkpoint_time: "2014-07-29T00:00:00",
					country_name: "United States of America",
					message: "Arrived and is being processed."
				}, {
					checkpoint_time: "2014-07-28T00:00:00",
					country_name: "Hong Kong",
					message: "The item left Hong Kong for its destination on 29-Jul-2014"
				}, {
					checkpoint_time: "2014-07-28T00:00:00",
					country_name: "Hong Kong",
					message: "The item arrived at processing centre."
				}, {
					checkpoint_time: "2014-07-28T00:00:00",
					country_name: "Hong Kong",
					message: "Item posted and is being processed."
				}
			]
		};

		it('Expect return true', function(done) {
			this.timeout(5000);
			var result = Courier.hkpost('EA999580311HK', function(err, result) {
				if (err) return done(err);
				result.should.eql(hkpost_1);
				done();
			});
		});
	});

	describe('Track @ hkpost(\'RT215770195HK\') — limited tracking info', function() {

		var hkpost_1 = {
			checkpoints: [
				{
					checkpoint_time: "2014-07-06T00:00:00",
					country_name: "Brazil",
					message: "The item (RT215770195HK) left Hong Kong for its destination on 6-Jul-2014"
				}
			]
		};

		it('Expect return true', function(done) {
			this.timeout(10000);
			var result = Courier.hkpost('RT215770195HK', function(err, result) {
				if (err) return done(err);
				result.should.eql(hkpost_1);
				done();
			});
		});
	});

	describe('Track @ dpduk(\'15502370264989N\')', function() {
		// Courier: http://www.dpd.co.uk
		// Hints: Not that easy, if you can't find the magic in the cookies
		// Time need: We spent two days to dig out the magic. Once you know it, can be done within 2 hours.

		var dpduk = {'checkpoints': [
			{
				country_name: 'Hub 3 - Birmingham',
				message: 'We have your parcel, and it\'s on its way to your nearest depot',
				checkpoint_time: '2014-01-08T22:33:50'
			},
			{
				country_name: 'Hub 3 - Birmingham',
				message: 'We have your parcel, and it\'s on its way to your nearest depot',
				checkpoint_time: '2014-01-08T22:34:58'
			},
			{
				country_name: 'Hub 3 - Birmingham',
				message: 'Your parcel has left the United Kingdom and is on its way to Saudi Arabia',
				checkpoint_time: '2014-01-09T03:56:57'
			},
			{
				country_name: 'United Kingdom',
				message: 'The parcel is in transit on its way to its final destination.',
				checkpoint_time: '2014-01-09T22:34:00'
			},
			{
				country_name: 'Bahrain',
				message: 'Your parcel has arrived at the local delivery depot',
				checkpoint_time: '2014-01-10T09:39:00'
			},
			{
				country_name: 'Bahrain',
				message: 'The parcel is in transit on its way to its final destination.',
				checkpoint_time: '2014-01-10T13:45:00'
			},
			{
				country_name: 'Bahrain',
				message: 'The parcel is in transit on its way to its final destination.',
				checkpoint_time: '2014-01-12T13:17:00'
			},
			{
				country_name: 'Saudi Arabia',
				message: 'Your parcel has arrived at the local delivery depot',
				checkpoint_time: '2014-01-14T06:30:00'
			},
			{
				country_name: 'Saudi Arabia',
				message: 'Your parcel is at the local depot awaiting collection',
				checkpoint_time: '2014-01-14T21:18:00'
			},
			{
				country_name: 'Saudi Arabia',
				message: 'Your parcel is on the vehicle for delivery',
				checkpoint_time: '2014-01-15T08:34:00'
			},
			{
				country_name: 'Saudi Arabia',
				message: 'The parcel has been delivered, signed for by BILAL',
				checkpoint_time: '2014-01-15T19:23:00'
			}
		]
		};

		it('Expect return true', function(done) {
			var result = Courier.dpduk('15502370264989N', function(err, result) {
				if (err) return done(err);
				result.should.eql(dpduk);
				done();
			});
		});
	});
});
