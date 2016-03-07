/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/DOUAudioStreamer
 *
 *  Copyright 2013-2016 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <i@lembacon.com>
 *
 */

#import <Foundation/Foundation.h>
#import "DOUAudioStreamer.h"

#include <Python.h>
#include <structmember.h>

typedef struct {
  PyObject_HEAD
  PyObject *url;
  CFTypeRef streamer;
} Streamer;

@interface AudioStreamer : DOUAudioStreamer <DOUAudioFile> {
@private
  NSURL *_url;
}
- (instancetype)initWithURL:(NSString *)url;
@end

@implementation AudioStreamer
- (instancetype)initWithURL:(NSString *)url
{
  if (url == nil ||
      (_url = [NSURL URLWithString:url]) == nil) {
    return nil;
  }

  self = [super initWithAudioFile:self];
  if (self) {
  }

  return self;
}

- (NSURL *)audioFileURL
{
  return _url;
}
@end

static void
Streamer_dealloc(Streamer *self)
{
  Py_XDECREF(self->url);
  if (self->streamer != NULL) {
    @autoreleasepool {
      CFBridgingRelease(self->streamer);
    }
  }
  self->ob_type->tp_free((PyObject *)self);
}

static PyObject *
Streamer_new(PyTypeObject *type, PyObject *args, PyObject *kwds)
{
  Streamer *self;

  self = (Streamer *)type->tp_alloc(type, 0);
  if (self != NULL) {
    self->url = PyString_FromString("");
    if (self->url == NULL) {
      Py_DECREF(self);
      return NULL;
    }

    self->streamer = NULL;
  }

  return (PyObject *)self;
}

static int
Streamer_init(Streamer *self, PyObject *args, PyObject *kwds)
{
  static char *kwlist[] = { "url", NULL };

  const char *url = NULL;
  if (!PyArg_ParseTupleAndKeywords(args, kwds, "s", kwlist, &url)) {
    return -1;
  }

  Py_XDECREF(self->url);
  self->url = PyString_FromString(url);

  @autoreleasepool {
    NSString *nsurl = @(url);
    AudioStreamer *s = [[AudioStreamer alloc] initWithURL:nsurl];
    self->streamer = CFBridgingRetain(s);
  }

  if (self->streamer == NULL) {
    PyErr_SetString(PyExc_AttributeError, "url");
    return -1;
  }

  return 0;
}

static PyMemberDef Streamer_members[] = {
  { "url", T_OBJECT, offsetof(Streamer, url), 0, NULL },
  { NULL, 0, 0, 0, NULL }
};

static PyObject *
Streamer_status(Streamer *self)
{
  if (self->streamer != NULL) {
    @autoreleasepool {
      switch ([(__bridge AudioStreamer *)self->streamer status]) {
      case DOUAudioStreamerPlaying:
        return PyString_FromString("playing");

      case DOUAudioStreamerPaused:
        return PyString_FromString("paused");

      case DOUAudioStreamerFinished:
        return PyString_FromString("finished");

      case DOUAudioStreamerBuffering:
        return PyString_FromString("buffering");

      default:
        return PyString_FromString("unknown");
      }
    }
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
Streamer_error(Streamer *self)
{
  if (self->streamer != NULL) {
    @autoreleasepool {
      NSError *error = [(__bridge AudioStreamer *)self->streamer error];
      if (error != nil) {
        return PyString_FromString([[error description] UTF8String]);
      }
    }
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
Streamer_volume(Streamer *self)
{
  if (self->streamer != NULL) {
    @autoreleasepool {
      return PyFloat_FromDouble([(__bridge AudioStreamer *)self->streamer volume]);
    }
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
Streamer_set_volume(Streamer *self, PyObject *args)
{
  double volume = 0.0;
  if (!PyArg_ParseTuple(args, "d", &volume)) {
    return NULL;
  }

  if (self->streamer != NULL) {
    @autoreleasepool {
      [(__bridge AudioStreamer *)self->streamer setVolume:volume];
    }
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
Streamer_duration(Streamer *self)
{
  if (self->streamer != NULL) {
    @autoreleasepool {
      return PyFloat_FromDouble([(__bridge AudioStreamer *)self->streamer duration]);
    }
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
Streamer_current_time(Streamer *self)
{
  if (self->streamer != NULL) {
    @autoreleasepool {
      return PyFloat_FromDouble([(__bridge AudioStreamer *)self->streamer currentTime]);
    }
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
Streamer_download_speed(Streamer *self)
{
  if (self->streamer != NULL) {
    @autoreleasepool {
      return PyLong_FromUnsignedLong([(__bridge AudioStreamer *)self->streamer downloadSpeed]);
    }
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
Streamer_play(Streamer *self)
{
  if (self->streamer != NULL) {
    @autoreleasepool {
      [(__bridge AudioStreamer *)self->streamer play];
    }
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
Streamer_pause(Streamer *self)
{
  if (self->streamer != NULL) {
    @autoreleasepool {
      [(__bridge AudioStreamer *)self->streamer pause];
    }
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyObject *
Streamer_stop(Streamer *self)
{
  if (self->streamer != NULL) {
    @autoreleasepool {
      [(__bridge AudioStreamer *)self->streamer stop];
    }
  }

  Py_INCREF(Py_None);
  return Py_None;
}

static PyMethodDef Streamer_methods[] = {
  { "status", (PyCFunction)Streamer_status, METH_NOARGS, "" },
  { "error", (PyCFunction)Streamer_error, METH_NOARGS, "" },
  { "volume", (PyCFunction)Streamer_volume, METH_NOARGS, "" },
  { "set_volume", (PyCFunction)Streamer_set_volume, METH_VARARGS, "" },
  { "duration", (PyCFunction)Streamer_duration, METH_NOARGS, "" },
  { "current_time", (PyCFunction)Streamer_current_time, METH_NOARGS, "" },
  { "download_speed", (PyCFunction)Streamer_download_speed, METH_NOARGS, "" },
  { "play", (PyCFunction)Streamer_play, METH_NOARGS, "" },
  { "pause", (PyCFunction)Streamer_pause, METH_NOARGS, "" },
  { "stop", (PyCFunction)Streamer_stop, METH_NOARGS, "" },
  { NULL, NULL, 0, NULL }
};

static PyTypeObject StreamerType = {
  PyObject_HEAD_INIT(NULL)
  0,                         /*ob_size*/
  "douas.Streamer",          /*tp_name*/
  sizeof(Streamer),          /*tp_basicsize*/
  0,                         /*tp_itemsize*/
  (destructor)Streamer_dealloc, /*tp_dealloc*/
  0,                         /*tp_print*/
  0,                         /*tp_getattr*/
  0,                         /*tp_setattr*/
  0,                         /*tp_compare*/
  0,                         /*tp_repr*/
  0,                         /*tp_as_number*/
  0,                         /*tp_as_sequence*/
  0,                         /*tp_as_mapping*/
  0,                         /*tp_hash */
  0,                         /*tp_call*/
  0,                         /*tp_str*/
  0,                         /*tp_getattro*/
  0,                         /*tp_setattro*/
  0,                         /*tp_as_buffer*/
  Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE, /*tp_flags*/
  "Streamer objects",        /* tp_doc */
  0,		                     /* tp_traverse */
  0,		                     /* tp_clear */
  0,		                     /* tp_richcompare */
  0,		                     /* tp_weaklistoffset */
  0,		                     /* tp_iter */
  0,                         /* tp_iternext */
  Streamer_methods,          /* tp_methods */
  Streamer_members,          /* tp_members */
  0,                         /* tp_getset */
  0,                         /* tp_base */
  0,                         /* tp_dict */
  0,                         /* tp_descr_get */
  0,                         /* tp_descr_set */
  0,                         /* tp_dictoffset */
  (initproc)Streamer_init,   /* tp_init */
  0,                         /* tp_alloc */
  Streamer_new,              /* tp_new */
};

static PyMethodDef module_methods[] = {
  { NULL, NULL, 0, NULL }
};

PyMODINIT_FUNC
initdouas(void)
{
  PyObject *module;

  StreamerType.tp_new = PyType_GenericNew;
  if (PyType_Ready(&StreamerType) < 0) {
    return;
  }

  module = Py_InitModule("douas", module_methods);

  Py_INCREF(&StreamerType);
  PyModule_AddObject(module, "Streamer", (PyObject *)&StreamerType);
}
