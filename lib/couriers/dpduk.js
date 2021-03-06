// Generated by CoffeeScript 1.7.1
(function() {
  var get_checkpoint, tools;

  tools = require('./tools');

  get_checkpoint = function(checkpoint) {
    var time;
    time = checkpoint.trackingEventDate;
    return {
      country_name: checkpoint.trackingEventLocation,
      message: checkpoint.trackingEventStatus,
      checkpoint_time: time.substring(0, time.length - 5)
    };
  };

  exports.dpduk = function(tracking_number, callback) {
    var result, url_4_api_id, url_4_tracking_json;
    result = {
      checkpoints: []
    };
    url_4_api_id = "http://www.dpd.co.uk/esgServer/shipping/shipment/_/parcel/?filter=id&searchCriteria=deliveryReference%3D" + tracking_number + "%26postcode%3D&searchPage=0&searchPageSize=25";
    url_4_tracking_json = "http://www.dpd.co.uk/esgServer/shipping/delivery/?parcelCode=" + tracking_number;
    return tools.request_json(url_4_api_id, function(error, json) {
      var options;
      if (error) {
        return callback(error);
      }
      try {
        options = {
          url: url_4_tracking_json,
          headers: {
            Cookie: "tracking=" + json.obj.searchSession
          }
        };
        return tools.request_json(options, function(error, json) {
          var p, points;
          if (error) {
            return callback(error);
          }
          try {
            points = json.obj.trackingEvent.reverse();
            result.checkpoints = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = points.length; _i < _len; _i++) {
                p = points[_i];
                _results.push(get_checkpoint(p));
              }
              return _results;
            })();
            return callback(null, result);
          } catch (_error) {
            error = _error;
            return callback(error);
          }
        });
      } catch (_error) {
        error = _error;
        return callback(error);
      }
    });
  };

}).call(this);
