//
//  main.cpp
//  AudioDSPBasics
//
//  Examples of some very basic audio programming, using portable
//  non-real-time C++ code.
//
//  Created by Gerry on 2016-06-19.
//  Copyright © 2016 cognosonic. All rights reserved.
//

#include <cstdio>
#include <cmath>
#include <ctgmath>
#include <vector>
#include <string>
#include <cassert>
#include "WavUtils.h"
#include "Biquad.h"

using namespace std;

const int SAMPLE_RATE = 44100;
const string IN_DIR = "InputFiles/";
const string OUT_DIR = "OutputFiles/";

// Create a tone and write it to file
void
createTone ()
{
  printf ("createTone\n");

  // Set up a buffer for the output. Note that the buffer is two-dimensional,
  // as we'll be creating a stereo output file.
  float durSecs = 5.0;
  int numFrames = SAMPLE_RATE * durSecs;
  vector < float >outBuf (numFrames);

  // For each output frame
  for (int i = 0; i < numFrames; i++)
    {
      // Generate a sample value
      float freq = 440.0;
      float x = 0.0;

      // Fundamental
      x += 0.30 * sin (2 * M_PI * i * freq / SAMPLE_RATE);

      // Adding harmonics doesn't change the pitch, but
      // changes the timbre.
      x += 0.25 * sin (2 * M_PI * 2 * i * freq / SAMPLE_RATE);
      x += 0.20 * sin (2 * M_PI * 3 * i * freq / SAMPLE_RATE);
      x += 0.15 * sin (2 * M_PI * 4 * i * freq / SAMPLE_RATE);
      x += 0.10 * sin (2 * M_PI * 5 * i * freq / SAMPLE_RATE);

      // Write it to the left and right channels
      outBuf[i] = x;		// Left
    }

  // Write the audio to file
  string outPath = OUT_DIR + "ToneOut.wav";
  audioWrite (outPath, outBuf, SAMPLE_RATE);
}

// Read a mono audio file, write to an output file.
void
readWriteAudio ()
{
  printf ("readWriteAudio\n");

  // Read the input file
  vector < float >sourceBuf;
  int sr;
  int numCh;
  string sourcePath = IN_DIR + "RickAstleyMono.wav";
  audioRead (sourcePath, sourceBuf, sr, numCh);
  auto numFrames = sourceBuf.size ();

  // Set up an output buffer
  vector < float >outBuf (numFrames);

  // For each output frame
  for (int i = 0; i < numFrames; i++)
    {
      // Get input sample
      float x = sourceBuf[i];

      // Copy it to the output buffer
      float gain = 0.5;
      outBuf[i] = gain * x;
    }

  // Write the audio to file
  string outPath = OUT_DIR + "RickAstleyMonoCopy.wav";
  audioWrite (outPath, outBuf, SAMPLE_RATE);
}

// Read an audio file, and copy it to another file
void
mixAudioFiles ()
{
  printf ("mixAudioFiles\n");

  // Set up buffers for all the audio.
  vector < float >bass;
  vector < float >guitar;
  vector < float >keys;
  vector < float >kit;

  // Read in all the audio sources
  int sr;
  int numCh;
  audioRead (IN_DIR + "AcesHigh/Bass.wav", bass, sr, numCh);
  audioRead (IN_DIR + "AcesHigh/Guitar.wav", guitar, sr, numCh);
  audioRead (IN_DIR + "AcesHigh/Keys.wav", keys, sr, numCh);
  audioRead (IN_DIR + "AcesHigh/Kit.wav", kit, sr, numCh);

  // Set up an output buffer
  float durSecs = 30.0;
  int numFrames = SAMPLE_RATE * durSecs;
  vector < float >outBuf (numFrames);

  // For each output frame
  for (int i = 0; i < numFrames; i++)
    {
      // Add in contribution of each source
      float x = 0.0;
      x += bass[i];
      x += guitar[i];
      x += keys[i];
      x += kit[i];

      // Write mix to L/R output channels
      outBuf[i] = x;
    }

  // Write the audio to file
  string outPath = OUT_DIR + "AcesHigh_Mix.wav";
  audioWrite (outPath, outBuf, SAMPLE_RATE);
}

// Play audio at different speed using linear interpolation. Changing the speed
// also changes the pitch.
void
changeSpeed ()
{
  printf ("changeSpeed\n");

  //int pitchChangeSemitones = 2.0;
  //const float SEMITONES_PER_OCTAVE = 12;
  //float speed = pow(2, pitchChangeSemitones/SEMITONES_PER_OCTAVE);

  float speed = 1.0;

  // Read the input file
  vector < float >sourceBuf;
  int sr;
  int numCh;
  string sourcePath = IN_DIR + "RickAstleyMono.wav";
  audioRead (sourcePath, sourceBuf, sr, numCh);
  auto sourceLen = sourceBuf.size ();

  // Set up an output buffer
  int outLen = sourceLen / speed;
  vector < float >outBuf (outLen);

  // For each output frame
  float pos = 0.0;
  for (int i = 0; i < outLen && pos < sourceLen - 1; i++)
    {
      // Break the current position into integer and fraction parts
      int intPos = floor (pos);
      float frac = pos - intPos;

      // Get samples at integer positions just before and after current position
      float prev = sourceBuf[intPos];
      float next = sourceBuf[intPos + 1];

      // Linearly interpolate between the samples
      outBuf[i] = (1 - frac) * prev + frac * next;

      // Increment the position based on the current speed
      pos += speed;
    }

  // Write the audio to file
  string outPath = OUT_DIR + "ChangeSpeedOut.wav";
  audioWrite (outPath, outBuf, SAMPLE_RATE, 1);
}

// Apply a filter
void
applyFilter ()
{
  printf ("applyFilter\n");

  // Read the input file
  vector < float >sourceBuf;
  int sr;
  int numCh;
  string sourcePath = IN_DIR + "RickAstleyMono.wav";
  audioRead (sourcePath, sourceBuf, sr, numCh);
  auto sourceLen = sourceBuf.size ();

  // Set up an output buffer
  vector < float >outBuf (sourceLen);

  // Set up a filter
  Biquad filter (SAMPLE_RATE);

  //float cutoffFreqHz = 1000;
  //filter.initHPF(cutoffFreqHz);
  float cutoffFreqHz = 400;
  filter.initLPF (cutoffFreqHz);

  // For each output frame
  for (int i = 0; i < sourceLen; i++)
    {
      // Get the input sample
      float x = sourceBuf[i];

      // Pass it to the filer
      float y = filter.tick (x);

      // And put it in the output buffer
      outBuf[i] = y;
    }

  // Write the audio to file
  string outPath = OUT_DIR + "FilterOut.wav";
  audioWrite (outPath, outBuf, SAMPLE_RATE, 1);
}

// Reads audio from one file, writes it to another file
// while applying gain to the left and right channels.
void
applyBalance ()
{
  const int NUM_CHANNELS = 2;

  const int L = 0;		// Left channel
  const int R = 1;		// Right channel

  printf ("applyBalance\n");

  // Read the input file
  int sr;
  vector < vector < float >>sourceBuf;
  string sourcePath = IN_DIR + "StairwayExcerpt.wav";
  audioRead (sourcePath, sourceBuf, sr);
  assert (sourceBuf.size () == NUM_CHANNELS);	// Expecting stereo
  auto numFrames = sourceBuf[L].size ();

  // Set up an output buffer
  vector < vector < float >>outBuf (NUM_CHANNELS);
  outBuf[L].resize (numFrames);
  outBuf[R].resize (numFrames);

  // For each output frame
  for (int i = 0; i < numFrames; i++)
    {
      // Get left and right input samples
      float xL = sourceBuf[L][i];
      float xR = sourceBuf[R][i];

      // Copy them to the output buffer
      float balance = 0.0;	// Range -1 (full left) to +1 (full right)
      float gainL = balance < 0.0 ? 1.0 : 1.0 - balance;
      float gainR = balance > 0.0 ? 1.0 : 1.0 + balance;

      outBuf[L][i] = gainL * xL;
      outBuf[R][i] = gainR * xR;
    }

  // Write the audio to file
  string outPath = OUT_DIR + "BalanceOut.wav";
  audioWrite (outPath, outBuf, SAMPLE_RATE);
}

int
main (int argc, const char *argv[])
{
  printf ("Audio DSP Basics\n");

  createTone ();
  //readWriteAudio();
  //mixAudioFiles();
  //changeSpeed();
  //applyFilter();
  //applyBalance();

  return 0;
}

