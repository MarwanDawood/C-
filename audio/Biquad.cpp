// =============================================================================================================
// Biquad.cpp
//
// The biquad topology is very flexible in that it allows you to place a conjugate pair
// of poles and a conjugate pair of zeros basically anywhere on the z-plane, though for
// stability, the poles should be within the unit circle.
//
// The topology in this implementation is known as "Direct Form II".  Different authors have
// different conventions for the names of the coefficients and even their signs.  I'm using
// the conventions from Julius O. Smith:
//
// 	http://ccrma-www.stanford.edu/~jos/filters/Direct_ForII.html
//
// x ---->o--------->o--- b0 -->o-----> y
//        ^          |v         ^
//        |          |          |
//        |        z^-1         |
//        |          |          |
//        |          v          |
//        o<-- -a1 --o--- b1 -->o
//        ^          |v1        ^
//        |          |          |
//        |        z^-1         |
//        |          |          |
//        |          v          |
//        o<-- -a2 --o--- b2 -->o
//                    v2
//
// The difference equation can be written as
//
//		v(n) = x(n) - a1 v(n-1) - a2 v(n-2)
//		y(n) = b0 v(n) + b1 v(n-1) - b2 v(n-2)
//
// which can be interpreted as a two-pole filter followed by a two-zero filter.
//
// The z-transform works out to be:
//
//		V(z)/X(z) = 1/(1 + a1 z^-1 + a2 ^ z-2)
//		Y(z)/V(z) = b0 + b1 z^-1 + b2 z^-2
//
// and therefore:
//
//		Y(z)	(b0 + b1 z^-1 + b2 z^-2)
//		---- =	------------------------
//  	X(z)	(1 + a1 z^-1 + a2 ^ z-2)
//
// Since the numerator and denominator are both quadratics, this type of filter
// is known as a biquad.
//
// Appropriate choice of pole/zero positions result in various types of filters - high-pass,
// low-pass, bandpass, etc.  Formulae for computing the required coefficients can be found in
// "Cookbook formulae for audio EQ biquad filter coefficients" by Robert Bristow-Johnson
// which can be found here:
// http://www.musicdsp.org/files/Audio-EQ-Cookbook.txt
// This is reproduced in full in a comment at the bottom of this file.
//
// RBJ's derivations assume that the first term of the denominator is a0 rather than 1. We deal with that
// by normalizing the other coefficients, dividing them all by a0.
//
// See also
// http://en.wikipedia.org/wiki/Digital_biquad_filter
//
//
// Released under the MIT License
//
// Copyright (c) 2014 Gerald T. Beauregard
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
// =============================================================================================================

#include "Biquad.h"

// Low-pass filter
void Biquad::initLPF(float f0, float q)
{
	float w0 = 2*M_PI*f0/m_sr;
	float alpha = sin(w0)/(2*q);
	float a0;
	
	m_b0 = (1 - cos(w0))/2;
	m_b1 =  1 - cos(w0);
	m_b2 = (1 - cos(w0))/2;
	  a0 =  1 + alpha;
	m_a1 = -2*cos(w0);
	m_a2 =  1 - alpha;
	normalize(a0);
}


// High-pass filter
void Biquad::initHPF(float f0, float q)
{
	float w0 = 2*M_PI*f0/m_sr;
	float alpha = sin(w0)/(2*q);
	float a0;
	
	m_b0 =  (1 + cos(w0))/2;
	m_b1 = -(1 + cos(w0));
	m_b2 =  (1 + cos(w0))/2;
	  a0 =   1 + alpha;
	m_a1 =  -2*cos(w0);
	m_a2 =   1 - alpha;
	normalize(a0);
}


// Band-pass filter. g is gain at peak. For unity gain in
// 'skirt', make g = q.
void Biquad::initBPF(float f0, float g, float q)
{
	float w0 = 2*M_PI*f0/m_sr;
	float alpha = sin(w0)/(2*q);
	float a0;
	
	m_b0 =   g*alpha;
	m_b1 =   0;
	m_b2 =  -g*alpha;
	  a0 =   1 + alpha;
	m_a1 =  -2*cos(w0);
	m_a2 =   1 - alpha;
	normalize(a0);
}


// Notch filter.
void Biquad::initNotch(float f0, float q)
{
	float w0 = 2*M_PI*f0/m_sr;
	float alpha = sin(w0)/(2*q);
	float a0;
	
	m_b0 =   1;
	m_b1 =  -2*cos(w0);
	m_b2 =   1;
	  a0 =   1 + alpha;
	m_a1 =  -2*cos(w0);
	m_a2 =   1 - alpha;
	
	normalize(a0);
}



/*
        Cookbook formulae for audio EQ biquad filter coefficients
----------------------------------------------------------------------------
           by Robert Bristow-Johnson  <rbj@audioimagination.com>


All filter transfer functions were derived from analog prototypes (that
are shown below for each EQ filter type) and had been digitized using the
Bilinear Transform.  BLT frequency warping has been taken into account for
both significant frequency relocation (this is the normal "prewarping" that
is necessary when using the BLT) and for bandwidth readjustment (since the
bandwidth is compressed when mapped from analog to digital using the BLT).

First, given a biquad transfer function defined as:

            b0 + b1*z^-1 + b2*z^-2
    H(z) = ------------------------                                  (Eq 1)
            a0 + a1*z^-1 + a2*z^-2

This shows 6 coefficients instead of 5 so, depending on your architechture,
you will likely normalize a0 to be 1 and perhaps also b0 to 1 (and collect
that into an overall gain coefficient).  Then your transfer function would
look like:

            (b0/a0) + (b1/a0)*z^-1 + (b2/a0)*z^-2
    H(z) = ---------------------------------------                   (Eq 2)
               1 + (a1/a0)*z^-1 + (a2/a0)*z^-2

or

                      1 + (b1/b0)*z^-1 + (b2/b0)*z^-2
    H(z) = (b0/a0) * ---------------------------------               (Eq 3)
                      1 + (a1/a0)*z^-1 + (a2/a0)*z^-2


The most straight forward implementation would be the "Direct Form 1"
(Eq 2):

    y[n] = (b0/a0)*x[n] + (b1/a0)*x[n-1] + (b2/a0)*x[n-2]
                        - (a1/a0)*y[n-1] - (a2/a0)*y[n-2]            (Eq 4)

This is probably both the best and the easiest method to implement in the
56K and other fixed-point or floating-point architechtures with a double
wide accumulator.



Begin with these user defined parameters:

    Fs (the sampling frequency)

    f0 ("wherever it's happenin', man."  Center Frequency or
        Corner Frequency, or shelf midpoint frequency, depending
        on which filter type.  The "significant frequency".)

    dBgain (used only for peaking and shelving filters)

    Q (the EE kind of definition, except for peakingEQ in which A*Q is
        the classic EE Q.  That adjustment in definition was made so that
        a boost of N dB followed by a cut of N dB for identical Q and
        f0/Fs results in a precisely flat unity gain filter or "wire".)

     _or_ BW, the bandwidth in octaves (between -3 dB frequencies for BPF
        and notch or between midpoint (dBgain/2) gain frequencies for
        peaking EQ)

     _or_ S, a "shelf slope" parameter (for shelving EQ only).  When S = 1,
        the shelf slope is as steep as it can be and remain monotonically
        increasing or decreasing gain with frequency.  The shelf slope, in
        dB/octave, remains proportional to S for all other values for a
        fixed f0/Fs and dBgain.



Then compute a few intermediate variables:

    A  = sqrt( 10^(dBgain/20) )
       =       10^(dBgain/40)     (for peaking and shelving EQ filters only)

    w0 = 2*pi*f0/Fs

    cos(w0)
    sin(w0)

    alpha = sin(w0)/(2*Q)                                       (case: Q)
          = sin(w0)*sinh( ln(2)/2 * BW * w0/sin(w0) )           (case: BW)
          = sin(w0)/2 * sqrt( (A + 1/A)*(1/S - 1) + 2 )         (case: S)

        FYI: The relationship between bandwidth and Q is
             1/Q = 2*sinh(ln(2)/2*BW*w0/sin(w0))     (digital filter w BLT)
        or   1/Q = 2*sinh(ln(2)/2*BW)             (analog filter prototype)

        The relationship between shelf slope and Q is
             1/Q = sqrt((A + 1/A)*(1/S - 1) + 2)

    2*sqrt(A)*alpha  =  sin(w0) * sqrt( (A^2 + 1)*(1/S - 1) + 2*A )
        is a handy intermediate variable for shelving EQ filters.


Finally, compute the coefficients for whichever filter type you want:
   (The analog prototypes, H(s), are shown for each filter
        type for normalized frequency.)


LPF:        H(s) = 1 / (s^2 + s/Q + 1)

            b0 =  (1 - cos(w0))/2
            b1 =   1 - cos(w0)
            b2 =  (1 - cos(w0))/2
            a0 =   1 + alpha
            a1 =  -2*cos(w0)
            a2 =   1 - alpha



HPF:        H(s) = s^2 / (s^2 + s/Q + 1)

            b0 =  (1 + cos(w0))/2
            b1 = -(1 + cos(w0))
            b2 =  (1 + cos(w0))/2
            a0 =   1 + alpha
            a1 =  -2*cos(w0)
            a2 =   1 - alpha



BPF:        H(s) = s / (s^2 + s/Q + 1)  (constant skirt gain, peak gain = Q)

            b0 =   sin(w0)/2  =   Q*alpha
            b1 =   0
            b2 =  -sin(w0)/2  =  -Q*alpha
            a0 =   1 + alpha
            a1 =  -2*cos(w0)
            a2 =   1 - alpha


BPF:        H(s) = (s/Q) / (s^2 + s/Q + 1)      (constant 0 dB peak gain)

            b0 =   alpha
            b1 =   0
            b2 =  -alpha
            a0 =   1 + alpha
            a1 =  -2*cos(w0)
            a2 =   1 - alpha



notch:      H(s) = (s^2 + 1) / (s^2 + s/Q + 1)

            b0 =   1
            b1 =  -2*cos(w0)
            b2 =   1
            a0 =   1 + alpha
            a1 =  -2*cos(w0)
            a2 =   1 - alpha



APF:        H(s) = (s^2 - s/Q + 1) / (s^2 + s/Q + 1)

            b0 =   1 - alpha
            b1 =  -2*cos(w0)
            b2 =   1 + alpha
            a0 =   1 + alpha
            a1 =  -2*cos(w0)
            a2 =   1 - alpha



peakingEQ:  H(s) = (s^2 + s*(A/Q) + 1) / (s^2 + s/(A*Q) + 1)

            b0 =   1 + alpha*A
            b1 =  -2*cos(w0)
            b2 =   1 - alpha*A
            a0 =   1 + alpha/A
            a1 =  -2*cos(w0)
            a2 =   1 - alpha/A



lowShelf: H(s) = A * (s^2 + (sqrt(A)/Q)*s + A)/(A*s^2 + (sqrt(A)/Q)*s + 1)

            b0 =    A*( (A+1) - (A-1)*cos(w0) + 2*sqrt(A)*alpha )
            b1 =  2*A*( (A-1) - (A+1)*cos(w0)                   )
            b2 =    A*( (A+1) - (A-1)*cos(w0) - 2*sqrt(A)*alpha )
            a0 =        (A+1) + (A-1)*cos(w0) + 2*sqrt(A)*alpha
            a1 =   -2*( (A-1) + (A+1)*cos(w0)                   )
            a2 =        (A+1) + (A-1)*cos(w0) - 2*sqrt(A)*alpha



highShelf: H(s) = A * (A*s^2 + (sqrt(A)/Q)*s + 1)/(s^2 + (sqrt(A)/Q)*s + A)

            b0 =    A*( (A+1) + (A-1)*cos(w0) + 2*sqrt(A)*alpha )
            b1 = -2*A*( (A-1) + (A+1)*cos(w0)                   )
            b2 =    A*( (A+1) + (A-1)*cos(w0) - 2*sqrt(A)*alpha )
            a0 =        (A+1) - (A-1)*cos(w0) + 2*sqrt(A)*alpha
            a1 =    2*( (A-1) - (A+1)*cos(w0)                   )
            a2 =        (A+1) - (A-1)*cos(w0) - 2*sqrt(A)*alpha





FYI:   The bilinear transform (with compensation for frequency warping)
substitutes:

                                  1         1 - z^-1
      (normalized)   s  <--  ----------- * ----------
                              tan(w0/2)     1 + z^-1

   and makes use of these trig identities:

                     sin(w0)                               1 - cos(w0)
      tan(w0/2) = -------------           (tan(w0/2))^2 = -------------
                   1 + cos(w0)                             1 + cos(w0)


   resulting in these substitutions:


                 1 + cos(w0)     1 + 2*z^-1 + z^-2
      1    <--  ------------- * -------------------
                 1 + cos(w0)     1 + 2*z^-1 + z^-2


                 1 + cos(w0)     1 - z^-1
      s    <--  ------------- * ----------
                   sin(w0)       1 + z^-1

                                      1 + cos(w0)     1         -  z^-2
                                  =  ------------- * -------------------
                                        sin(w0)       1 + 2*z^-1 + z^-2


                 1 + cos(w0)     1 - 2*z^-1 + z^-2
      s^2  <--  ------------- * -------------------
                 1 - cos(w0)     1 + 2*z^-1 + z^-2


   The factor:

                    1 + cos(w0)
                -------------------
                 1 + 2*z^-1 + z^-2

   is common to all terms in both numerator and denominator, can be factored
   out, and thus be left out in the substitutions above resulting in:


                 1 + 2*z^-1 + z^-2
      1    <--  -------------------
                    1 + cos(w0)


                 1         -  z^-2
      s    <--  -------------------
                      sin(w0)


                 1 - 2*z^-1 + z^-2
      s^2  <--  -------------------
                    1 - cos(w0)


   In addition, all terms, numerator and denominator, can be multiplied by a
   common (sin(w0))^2 factor, finally resulting in these substitutions:


      1         <--   (1 + 2*z^-1 + z^-2) * (1 - cos(w0))

      s         <--   (1         -  z^-2) * sin(w0)

      s^2       <--   (1 - 2*z^-1 + z^-2) * (1 + cos(w0))

      1 + s^2   <--   2 * (1 - 2*cos(w0)*z^-1 + z^-2)


   The biquad coefficient formulae above come out after a little
   simplification.
*/
