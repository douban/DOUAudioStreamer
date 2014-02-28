/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/DOUAudioStreamer
 *
 *  Copyright 2013-2014 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <i@lembacon.com>
 *
 */

#import "DOUAudioFrequencyAnalyzer.h"
#import "DOUAudioAnalyzer_Private.h"
#include <Accelerate/Accelerate.h>

@interface DOUAudioFrequencyAnalyzer () {
@private
  size_t _log2Count;
  float _hammingWindow[kDOUAudioAnalyzerCount];

  struct {
    float real[kDOUAudioAnalyzerCount / 2];
    float imag[kDOUAudioAnalyzerCount / 2];
  } _complexSplitBuffer;

  DSPSplitComplex _complexSplit;
  FFTSetup _fft;
}
@end

@implementation DOUAudioFrequencyAnalyzer

- (id)init
{
  self = [super init];
  if (self) {
    _log2Count = (size_t)lrintf(log2f(kDOUAudioAnalyzerCount));
    vDSP_hamm_window(_hammingWindow, kDOUAudioAnalyzerCount, 0);

    _complexSplit.realp = _complexSplitBuffer.real;
    _complexSplit.imagp = _complexSplitBuffer.imag;
    _fft = vDSP_create_fftsetup(_log2Count, kFFTRadix2);
  }

  return self;
}

- (void)dealloc
{
  vDSP_destroy_fftsetup(_fft);
}

- (void)_splitInterleavedComplexVectors:(const float *)vectors
{
  vDSP_vmul(vectors, 1, _hammingWindow, 1, (float *)vectors, 1, kDOUAudioAnalyzerCount);
  vDSP_ctoz((const DSPComplex *)vectors, 2, &_complexSplit, 1, kDOUAudioAnalyzerCount / 2);
}

- (void)_performForwardDFTWithVectors:(const float *)vectors
{
  vDSP_fft_zrip(_fft, &_complexSplit, 1, _log2Count, kFFTDirection_Forward);
  vDSP_zvabs(&_complexSplit, 1, (float *)vectors, 1, kDOUAudioAnalyzerCount / 2);

  static const float scale = 0.5f;
  vDSP_vsmul(vectors, 1, &scale, (float *)vectors, 1, kDOUAudioAnalyzerCount / 2);
}

- (void)_normalizeVectors:(const float *)vectors toLevels:(float *)levels
{
  static const int size = kDOUAudioAnalyzerCount / 4;
  vDSP_vsq(vectors, 1, (float *)vectors, 1, size);
  vvlog10f((float *)vectors, vectors, &size);

  static const float multiplier = 1.0f / 16.0f;
  const float increment = sqrtf(multiplier);
  vDSP_vsmsa((float *)vectors, 1, (float *)&multiplier, (float *)&increment, (float *)vectors, 1, kDOUAudioAnalyzerCount / 2);

  for (size_t i = 0; i < kDOUAudioAnalyzerLevelCount; ++i) {
    levels[i] = vectors[1 + ((size - 1) / kDOUAudioAnalyzerLevelCount) * i];
  }
}

- (void)processChannelVectors:(const float *)vectors toLevels:(float *)levels
{
  [self _splitInterleavedComplexVectors:vectors];
  [self _performForwardDFTWithVectors:vectors];
  [self _normalizeVectors:vectors toLevels:levels];
}

@end
