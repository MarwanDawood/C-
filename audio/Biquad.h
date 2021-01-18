// =============================================================================================================
// Biquad.h
//
// Implementation of a biquad filter, i.e. a filter with 2 poles and 2 zeroes.
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
//
// =============================================================================================================

#ifndef __Biquad__
#define __Biquad__

#include <cmath>

class Biquad
{
public:

	Biquad(float sr) { m_sr = sr; clear(); }
	~Biquad() {}

	// Low-pass filter
	void initLPF(float f0, float q = M_SQRT1_2);
	
	// High-pass filter
	void initHPF(float f0, float q = M_SQRT1_2);
	
	// Band-pass filter. g is gain at peak.
	void initBPF(float f0, float g = 1, float q = M_SQRT1_2);
	
	// Notch filter.
	void initNotch(float f0, float q = M_SQRT1_2);

	void clear()
	{
		m_v1 = 0.0;
		m_v2 = 0.0;
	}
	
	void process(const float *x, float *y, int n)
	{
		for (int i = 0; i < n; i++)
			*y++ = tick(*x++);
	}
	
	inline float tick(float x)
	{
		// Direct form 1:
		//float y = b0*x + b1*xd1 + b2*xd2 - a0*yd1 - a2*yd2;
		//yd2 = yd1;	yd1 = y;
		//xd2 = xd1;	xd1 = x;
	
		// Direct form 2:
		float v =      x - m_a1*m_v1 - m_a2*m_v2;
		float y = m_b0*v + m_b1*m_v1 + m_b2*m_v2;
		m_v2 = m_v1;
		m_v1 = v;
		return y;
	}
	
private:

	float m_sr;		// Sample rate
	float m_b0;		// Coefficients of numerator; these determine the zero positions.
	float m_b1;
	float m_b2;
	float m_a1;		// Coefficients of denominator; these determine the pole positions.
	float m_a2;
	float m_v1;		// v delayed by 1 sample
	float m_v2;		// v delayed by 2 samples
	
	void normalize(float a0)
	{
		m_b0 /= a0;
		m_b1 /= a0;
		m_b2 /= a0;
		m_a1 /= a0;
		m_a2 /= a0;
	}
};

#endif /* defined(__Biquad__) */

