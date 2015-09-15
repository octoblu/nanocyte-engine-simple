'use strict';
var christacheio = require('./christacheio');
var debug = require('debug')('flow-runner:dynamicNode');

var escapeDoubleQuote = function(data) {
  if(!data) {
     return data;
  }
  return data.toString().replace(/"/g, '\\"');
}

var dynamicNode = function(node, msg){
  var nodeString = christacheio(['"{{', '}}"'], JSON.stringify(node), {msg: msg}, JSON.stringify);
  debug('first pass: ', nodeString);
  nodeString = christacheio(['{{', '}}'], nodeString, {msg: msg}, escapeDoubleQuote); // don't stringify the second time
  debug('got nodeString', nodeString);
  return JSON.parse(nodeString);
};

module.exports = dynamicNode;
