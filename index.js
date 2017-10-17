'use strict';

import { processColor } from "react-native";

var React = require('react-native');
var {
    NativeModules,
    Platform
} = React;

var CardIO = {};

function _processProperties(properties) {
  for (var property in properties) {
    if (properties.hasOwnProperty(property)) {
      if (property === 'icon' || property.endsWith('Icon') || property.endsWith('Image')) {
        properties[property] = resolveAssetSource(properties[property]);
      }
      if (property === 'color' || property.endsWith('Color')) {
        properties[property] = processColor(properties[property]);
      }
    }
  }
}

console.log("NativeModules", NativeModules);

var ReactCardIOModule = NativeModules.ReactCardIOModule;

CardIO.scan = function (options) {
  let nativeOptions = {
    ...options
  };
  if (Platform.OS === "ios") {
    _processProperties(nativeOptions);
  }
  return ReactCardIOModule.scan(nativeOptions);
};

CardIO.canScan = function () {
  return ReactCardIOModule.canScan();
}

module.exports = CardIO;
