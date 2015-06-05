'use strict';

var Streamer = require('NativeModules').RADOUAudioStreamer;

class DouAudio {}

DouAudio.createSound = function (options) {
  Streamer.createSound(options, function (error, id) {
    console.log(arguments);
    return Streamer.play(id);
  });
}

module.exports = DouAudio;
