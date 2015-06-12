'use strict';
// var Promise = require('promise');

var { DeviceEventEmitter } = require('react-native');
var Streamer = require('NativeModules').RADOUAudioStreamer;
var {EventEmitter} = require('events');

class DouAudio extends EventEmitter {

  constructor(id) {
    super();
    this.id = id;

    this.nativeEventSubscription = DeviceEventEmitter.addListener(
      "EventAudio-" + this.id,
      this._dispatchEvent.bind(this)
    );

    Object.assign(this, {
      bufferingRatio: null,
      bytesLoaded: null,
      bytesTotal: null,
      downloadSpeed: null,

      position: null,
      duration: null,

      // 0 = stopped/uninitialised
      // 1 = playing or buffering sound (play has been called, waiting for data etc.)
      playState: 0,

      // Numeric value indicating a sound's current load status
      // 0 = uninitialised
      // 1 = loading
      // 2 = failed/error
      // 3 = loaded/success
      readyState: 0,

      paused: true
    });

    for(let command of ['play', 'pause', 'stop', 'setPosition']) {
      this[command] = (...args) => {
        return Streamer[command].call(this, this.id, ...args);
      }
    }

  }

  _dispatchEvent(o) {
    console.log(o);
    Object.assign(this, o.value);
    this.emit(o.name, o.value);
  }

  destruct() {
    // @todo tell the objc to destroy the sound
    this.nativeEventSubscription.remove();
    Streamer.destruct(this.id);
  }

}

DouAudio.createSound = function (options, callback) {
  // pollingInterval
  Streamer.createSound(options, function (error, id) {
    // console.log(arguments);
    if(options.autoPlay){
      Streamer.play(id);
    }
    var audio = new DouAudio(id);
    callback && callback(audio);
  });
}

module.exports = DouAudio;
