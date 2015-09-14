var _                  = require('lodash');
var debug              = require('debug')('christacheio');
var deepGet            = require('lodash-deep').deepGet;
var deepSet            = require('lodash-deep').deepSet;
var escapeStringRegexp = require('escape-string-regexp');

var christacheio = function(tags, jsonString, obj, transformation) {
  var regexStr, map, newJsonString;
  transformation = transformation || function(data) { return data; }
  tags = tags || ['{{', '}}'];
  regexStr = tags[0] + '(.*?)' + tags[1];
  map = {};
  newJsonString = _.clone(jsonString);

  function regexMatches(regexString, string){
    var regex, matches, match;
    regex = new RegExp(regexString, 'g');
    matches = [];
    while(match = regex.exec(string)){
      matches.push(match[1]);
    }
    return matches;
  };

  _.each(regexMatches(regexStr, jsonString), function(key) {
    var value = deepGet(obj, key);
    value = transformation(value);
    map[key] = value || null;
  });

  _.each(map, function(value, key){
    var escapedKey = escapeStringRegexp(key);
    var regex = new RegExp(tags[0] + escapedKey + tags[1], 'g');
    newJsonString = newJsonString.replace(regex, map[key]);
  });

  return newJsonString;
}

module.exports = christacheio;
