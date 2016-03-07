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

#if TARGET_OS_IPHONE

#import "DOUAudioVisualizer.h"
#import "DOUAudioStreamer.h"
#include <Accelerate/Accelerate.h>

#define kBarHeight 6.0
#define kBarHorizontalPadding 2.0
#define kBarVerticalPadding 1.0

@interface DOUAudioVisualizer () {
@private
  struct {
    float current[kDOUAudioAnalyzerLevelCount];
    float last[kDOUAudioAnalyzerLevelCount];
    float pacing[kDOUAudioAnalyzerLevelCount];
  } _levels;

  float _coefficient;
  NSUInteger _step;
  NSUInteger _stepCount;
  DOUAudioVisualizerInterpolationType _interpolationType;

  struct {
    CGFloat width;
    CGFloat height;
    CGFloat horizontalPadding;
    CGFloat verticalPadding;

    NSUInteger horizontalCount;
    NSUInteger verticalCount;
  } _bar;

  GLuint _vbo;
  GLuint _ibo;
}
@end

@implementation DOUAudioVisualizer

@synthesize stepCount = _stepCount;
@synthesize interpolationType = _interpolationType;

#pragma mark - Shared Analyzer

+ (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
  [[self _sharedAnalyzer] setEnabled:NO];
}

+ (void)_applicationWillEnterForegroundNotification:(NSNotification *)notification
{
  [[self _sharedAnalyzer] setEnabled:YES];
}

+ (void)_setupNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_applicationDidEnterBackgroundNotification:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_applicationWillEnterForegroundNotification:)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
}

+ (DOUAudioAnalyzer *)_sharedAnalyzer
{
  static DOUAudioAnalyzer *sharedAnalyzer = nil;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedAnalyzer = [DOUAudioAnalyzer frequencyAnalyzer];
    [sharedAnalyzer setEnabled:YES];
    [DOUAudioStreamer setAnalyzers:@[sharedAnalyzer]];

    [self performSelector:@selector(_setupNotifications)
               withObject:nil
               afterDelay:0.0];
  });

  return sharedAnalyzer;
}

#pragma mark - Miscellaneous

- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
  [self setPaused:YES];
}

- (void)_applicationWillEnterForegroundNotification:(NSNotification *)notification
{
  [self setPaused:NO];
}

- (void)_setupNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_applicationDidEnterBackgroundNotification:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_applicationWillEnterForegroundNotification:)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
}

- (void)_setupVisualizer
{
  _coefficient = 0.0f;
  _step = 0;
  _stepCount = 6;
  _interpolationType = DOUAudioVisualizerLinearInterpolation;
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self _setupNotifications];
    [self _setupVisualizer];
  }

  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self _setupNotifications];
    [self _setupVisualizer];
  }

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Animation

- (void)_updateStepAndLevels
{
#define COEFFICIENT ((float)_step / _stepCount)
#define INTERPOLATED_COEFFICIENT_LINEAR (COEFFICIENT)
#define INTERPOLATED_COEFFICIENT_SMOOTH (sinf(COEFFICIENT * M_PI - M_PI_2) * 0.5f + 0.5f)

  switch (_interpolationType) {
  default:
  case DOUAudioVisualizerLinearInterpolation:
      _coefficient = INTERPOLATED_COEFFICIENT_LINEAR;
    break;

  case DOUAudioVisualizerSmoothInterpolation:
    _coefficient = INTERPOLATED_COEFFICIENT_SMOOTH;
    break;
  }

  if (_coefficient >= 1.0f) {
    _coefficient = 0.0f;
  }

#undef COEFFICIENT
#undef INTERPOLATED_COEFFICIENT_LINEAR
#undef INTERPOLATED_COEFFICIENT_SMOOTH

  if (++_step > _stepCount) {
    _step = 0;
    memcpy(_levels.last, _levels.current, sizeof(float) * kDOUAudioAnalyzerLevelCount);
    [[[self class] _sharedAnalyzer] copyLevels:_levels.current];
  }
}

- (void)_updatePacingLevels
{
  vDSP_vintb(_levels.last, 1,
             _levels.current, 1,
             &_coefficient,
             _levels.pacing, 1,
             kDOUAudioAnalyzerLevelCount);
}

#pragma mark - Pre-calculation

- (void)_updateBarGeometries
{
  CGFloat width = CGRectGetWidth([self bounds]);
  CGFloat height = CGRectGetHeight([self bounds]);

  _bar.width = width / kDOUAudioAnalyzerLevelCount;
  _bar.height = kBarHeight;
  _bar.horizontalPadding = kBarHorizontalPadding;
  _bar.verticalPadding = kBarVerticalPadding;

  _bar.horizontalCount = kDOUAudioAnalyzerLevelCount;
  _bar.verticalCount = (NSUInteger)lrint(floor(height / kBarHeight));
}

- (void)_updateVBO
{
  [self _updateBarGeometries];

  NSUInteger verticesCount = _bar.verticalCount * 4 * 2;
  GLfloat *vertices = (GLfloat *)malloc(sizeof(GLfloat) * verticesCount);

  NSUInteger indicesCount = _bar.verticalCount * 4;
  GLuint *indices = (GLuint *)malloc(sizeof(GLuint) * indicesCount);

  for (NSUInteger i = 0; i < _bar.verticalCount; ++i) {
    CGRect rect;
    rect.origin.x = _bar.horizontalPadding;
    rect.origin.y = _bar.verticalPadding + _bar.height * i;
    rect.size.width = _bar.width - 2.0 * _bar.horizontalPadding;
    rect.size.height = _bar.height - 2.0 * _bar.verticalPadding;

    if (i & 1) {
      vertices[i * 4 * 2 + 0 * 2 + 0] = CGRectGetMaxX(rect);
      vertices[i * 4 * 2 + 0 * 2 + 1] = CGRectGetMinY(rect);

      vertices[i * 4 * 2 + 1 * 2 + 0] = CGRectGetMaxX(rect);
      vertices[i * 4 * 2 + 1 * 2 + 1] = CGRectGetMaxY(rect);

      vertices[i * 4 * 2 + 2 * 2 + 0] = CGRectGetMinX(rect);
      vertices[i * 4 * 2 + 2 * 2 + 1] = CGRectGetMinY(rect);

      vertices[i * 4 * 2 + 3 * 2 + 0] = CGRectGetMinX(rect);
      vertices[i * 4 * 2 + 3 * 2 + 1] = CGRectGetMaxY(rect);
    }
    else {
      vertices[i * 4 * 2 + 0 * 2 + 0] = CGRectGetMinX(rect);
      vertices[i * 4 * 2 + 0 * 2 + 1] = CGRectGetMinY(rect);

      vertices[i * 4 * 2 + 1 * 2 + 0] = CGRectGetMinX(rect);
      vertices[i * 4 * 2 + 1 * 2 + 1] = CGRectGetMaxY(rect);

      vertices[i * 4 * 2 + 2 * 2 + 0] = CGRectGetMaxX(rect);
      vertices[i * 4 * 2 + 2 * 2 + 1] = CGRectGetMinY(rect);

      vertices[i * 4 * 2 + 3 * 2 + 0] = CGRectGetMaxX(rect);
      vertices[i * 4 * 2 + 3 * 2 + 1] = CGRectGetMaxY(rect);
    }

    indices[i * 4 + 0] = (GLuint)i * 4 + 0;
    indices[i * 4 + 1] = (GLuint)i * 4 + 1;
    indices[i * 4 + 2] = (GLuint)i * 4 + 2;
    indices[i * 4 + 3] = (GLuint)i * 4 + 3;
  }

  glBindBuffer(GL_ARRAY_BUFFER, _vbo);
  glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)(sizeof(GLfloat) * verticesCount), vertices, GL_STATIC_DRAW);

  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ibo);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, (GLsizeiptr)(sizeof(GLuint) * indicesCount), indices, GL_STATIC_DRAW);

  free(vertices);
  free(indices);
}

#pragma mark - Renderer

- (void)prepare
{
  glGenBuffers(1, &_vbo);
  glGenBuffers(1, &_ibo);

  glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
  glColor4f(0.784f, 0.867f, 0.839f, 1.0f);

  glEnable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)cleanup
{
  glDeleteBuffers(1, &_vbo);
  glDeleteBuffers(1, &_ibo);
}

- (void)reshape
{
  CGFloat width = CGRectGetWidth([self bounds]);
  CGFloat height = CGRectGetHeight([self bounds]);
  CGFloat scale = [[UIScreen mainScreen] scale];

  glViewport(0, 0, (GLsizei)lrint(width * scale), (GLsizei)lrint(height * scale));

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();

  glOrthof(0.0f, width, 0.0f, height, -100.0f, 100.0f);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  [self _updateVBO];
}

- (void)render
{
  glClear(GL_COLOR_BUFFER_BIT);

  [self _updateStepAndLevels];
  [self _updatePacingLevels];

  glEnableClientState(GL_VERTEX_ARRAY);
  for (NSUInteger i = 0; i < _bar.horizontalCount; ++i) {
    NSUInteger verticalCount = (NSUInteger)lroundf(_levels.pacing[i] * _bar.verticalCount);

    glPushMatrix();
    glTranslatef(_bar.width * i, 0.0f, 0.0f);

    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glVertexPointer(2, GL_FLOAT, 0, NULL);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ibo);
    glDrawElements(GL_TRIANGLE_STRIP, (GLsizei)verticalCount * 4, GL_UNSIGNED_INT_OES, NULL);

    glPopMatrix();
  }
  glDisableClientState(GL_VERTEX_ARRAY);
}

@end

#endif /* TARGET_OS_IPHONE */
