# vim: set ft=python fenc=utf-8 sw=4 ts=4 et:
#
#  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
#
#      https://github.com/douban/DOUAudioStreamer
#
#  Copyright 2013-2016 Douban Inc.  All rights reserved.
#
#  Use and distribution licensed under the BSD license.  See
#  the LICENSE file for full text.
#
#  Authors:
#      Chongyu Zhu <i@lembacon.com>
#
#

from distutils.core import setup, Extension
import glob

FRAMEWORKS = ["Accelerate",
              "CFNetwork",
              "CoreAudio",
              "AudioToolbox",
              "AudioUnit",
              'CoreServices']

DOUAS_MODULE = Extension("douas",
                         sources=glob.glob("../src/*.m") + ["douas.m"],
                         include_dirs=["../src"],
                         extra_compile_args=["-fobjc-arc"],
                         extra_link_args=[item for f in FRAMEWORKS
                                               for item in ["-framework", f]])

setup(
    name="douas",
    version="0.2.15",
    description="A Core Audio based streaming audio player for iOS/Mac",
    url="https://github.com/douban/DOUAudioStreamer",
    ext_modules=[DOUAS_MODULE],
    keywords=["douas", "audio", "streamer"],
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Environment :: MacOS X",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: BSD License",
        "Operating System :: MacOS :: MacOS X",
        "Programming Language :: Objective C",
        "Topic :: Software Development :: Libraries :: Python Modules"
    ],
    license="BSD",
    author="Chongyu Zhu",
    author_email="i@lembacon.com"
)
