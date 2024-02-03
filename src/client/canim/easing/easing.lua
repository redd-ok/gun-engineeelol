--
-- Adapted from
-- Tweener's easing functions (Penner's Easing Equations)
-- and http://code.google.com/p/tweener/ (jstweener javascript version)
--

--[[
Disclaimer for Robert Penner's Easing Equations license:

TERMS OF USE - EASING EQUATIONS

Open source under the BSD License.

Copyright © 2001 Robert Penner
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

-- For all easing functions:
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)

-- file was auto-formatted and converted to be more Luau friendly

local function linear(t, b, c, d)
	return c * t / d + b
end

local function inQuad(t, b, c, d)
	t = t / d
	return c * math.pow(t, 2) + b
end

local function outQuad(t, b, c, d)
	t = t / d
	return -c * t * (t - 2) + b
end

local function inOutQuad(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * math.pow(t, 2) + b
	else
		return -c / 2 * ((t - 1) * (t - 3) - 1) + b
	end
end

local function outInQuad(t, b, c, d)
	if t < d / 2 then
		return outQuad(t * 2, b, c / 2, d)
	else
		return inQuad((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inCubic(t, b, c, d)
	t = t / d
	return c * math.pow(t, 3) + b
end

local function outCubic(t, b, c, d)
	t = t / d - 1
	return c * (math.pow(t, 3) + 1) + b
end

local function inOutCubic(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * t * t * t + b
	else
		t = t - 2
		return c / 2 * (t * t * t + 2) + b
	end
end

local function outInCubic(t, b, c, d)
	if t < d / 2 then
		return outCubic(t * 2, b, c / 2, d)
	else
		return inCubic((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inQuart(t, b, c, d)
	t = t / d
	return c * math.pow(t, 4) + b
end

local function outQuart(t, b, c, d)
	t = t / d - 1
	return -c * (math.pow(t, 4) - 1) + b
end

local function inOutQuart(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * math.pow(t, 4) + b
	else
		t = t - 2
		return -c / 2 * (math.pow(t, 4) - 2) + b
	end
end

local function outInQuart(t, b, c, d)
	if t < d / 2 then
		return outQuart(t * 2, b, c / 2, d)
	else
		return inQuart((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inQuint(t, b, c, d)
	t = t / d
	return c * math.pow(t, 5) + b
end

local function outQuint(t, b, c, d)
	t = t / d - 1
	return c * (math.pow(t, 5) + 1) + b
end

local function inOutQuint(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * math.pow(t, 5) + b
	else
		t = t - 2
		return c / 2 * (math.pow(t, 5) + 2) + b
	end
end

local function outInQuint(t, b, c, d)
	if t < d / 2 then
		return outQuint(t * 2, b, c / 2, d)
	else
		return inQuint((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inSine(t, b, c, d)
	return -c * math.cos(t / d * (math.pi / 2)) + c + b
end

local function outSine(t, b, c, d)
	return c * math.sin(t / d * (math.pi / 2)) + b
end

local function inOutSine(t, b, c, d)
	return -c / 2 * (math.cos(math.pi * t / d) - 1) + b
end

local function outInSine(t, b, c, d)
	if t < d / 2 then
		return outSine(t * 2, b, c / 2, d)
	else
		return inSine((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inExpo(t, b, c, d)
	if t == 0 then
		return b
	else
		return c * math.pow(2, 10 * (t / d - 1)) + b - c * 0.001
	end
end

local function outExpo(t, b, c, d)
	if t == d then
		return b + c
	else
		return c * 1.001 * (-math.pow(2, -10 * t / d) + 1) + b
	end
end

local function inOutExpo(t, b, c, d)
	if t == 0 then
		return b
	end
	if t == d then
		return b + c
	end
	t = t / d * 2
	if t < 1 then
		return c / 2 * math.pow(2, 10 * (t - 1)) + b - c * 0.0005
	else
		t = t - 1
		return c / 2 * 1.0005 * (-math.pow(2, -10 * t) + 2) + b
	end
end

local function outInExpo(t, b, c, d)
	if t < d / 2 then
		return outExpo(t * 2, b, c / 2, d)
	else
		return inExpo((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inCirc(t, b, c, d)
	t = t / d
	return (-c * (math.sqrt(1 - math.pow(t, 2)) - 1) + b)
end

local function outCirc(t, b, c, d)
	t = t / d - 1
	return (c * math.sqrt(1 - math.pow(t, 2)) + b)
end

local function inOutCirc(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return -c / 2 * (math.sqrt(1 - t * t) - 1) + b
	else
		t = t - 2
		return c / 2 * (math.sqrt(1 - t * t) + 1) + b
	end
end

local function outInCirc(t, b, c, d)
	if t < d / 2 then
		return outCirc(t * 2, b, c / 2, d)
	else
		return inCirc((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inElastic(t, b, c, d, a, p)
	if t == 0 then
		return b
	end

	t = t / d

	if t == 1 then
		return b + c
	end

	if not p then
		p = d * 0.3
	end

	local s

	if not a or a < math.abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * math.pi) * math.asin(c / a)
	end

	t = t - 1

	return -(a * math.pow(2, 10 * t) * math.sin((t * d - s) * (2 * math.pi) / p)) + b
end

-- a: amplitud
-- p: period
local function outElastic(t, b, c, d, a, p)
	if t == 0 then
		return b
	end

	t = t / d

	if t == 1 then
		return b + c
	end

	if not p then
		p = d * 0.3
	end

	local s

	if not a or a < math.abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * math.pi) * math.asin(c / a)
	end

	return a * math.pow(2, -10 * t) * math.sin((t * d - s) * (2 * math.pi) / p) + c + b
end

-- p = period
-- a = amplitud
local function inOutElastic(t, b, c, d, a, p)
	if t == 0 then
		return b
	end

	t = t / d * 2

	if t == 2 then
		return b + c
	end

	if not p then
		p = d * (0.3 * 1.5)
	end
	if not a then
		a = 0
	end

	local s

	if not a or a < math.abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * math.pi) * math.asin(c / a)
	end

	if t < 1 then
		t = t - 1
		return -0.5 * (a * math.pow(2, 10 * t) * math.sin((t * d - s) * (2 * math.pi) / p)) + b
	else
		t = t - 1
		return a * math.pow(2, -10 * t) * math.sin((t * d - s) * (2 * math.pi) / p) * 0.5 + c + b
	end
end

-- a: amplitud
-- p: period
local function outInElastic(t, b, c, d, a, p)
	if t < d / 2 then
		return outElastic(t * 2, b, c / 2, d, a, p)
	else
		return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
	end
end

local function inBack(t, b, c, d, s)
	if not s then
		s = 1.70158
	end
	t = t / d
	return c * t * t * ((s + 1) * t - s) + b
end

local function outBack(t, b, c, d, s)
	if not s then
		s = 1.70158
	end
	t = t / d - 1
	return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function inOutBack(t, b, c, d, s)
	if not s then
		s = 1.70158
	end
	s = s * 1.525
	t = t / d * 2
	if t < 1 then
		return c / 2 * (t * t * ((s + 1) * t - s)) + b
	else
		t = t - 2
		return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
	end
end

local function outInBack(t, b, c, d, s)
	if t < d / 2 then
		return outBack(t * 2, b, c / 2, d, s)
	else
		return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
	end
end

local function outBounce(t, b, c, d)
	t = t / d
	if t < 1 / 2.75 then
		return c * (7.5625 * t * t) + b
	elseif t < 2 / 2.75 then
		t = t - (1.5 / 2.75)
		return c * (7.5625 * t * t + 0.75) + b
	elseif t < 2.5 / 2.75 then
		t = t - (2.25 / 2.75)
		return c * (7.5625 * t * t + 0.9375) + b
	else
		t = t - (2.625 / 2.75)
		return c * (7.5625 * t * t + 0.984375) + b
	end
end

local function inBounce(t, b, c, d)
	return c - outBounce(d - t, 0, c, d) + b
end

local function inOutBounce(t, b, c, d)
	if t < d / 2 then
		return inBounce(t * 2, 0, c, d) * 0.5 + b
	else
		return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * 0.5 + b
	end
end

local function outInBounce(t, b, c, d)
	if t < d / 2 then
		return outBounce(t * 2, b, c / 2, d)
	else
		return inBounce((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function port(f)
	return function(alpha)
		return f(alpha, 0, 1, 1)
	end
end

return {
	linear = port(linear),
	quad_in = port(inQuad),
	quad_out = port(outQuad),
	quad_in_out = port(inOutQuad),
	quad_out_in = port(outInQuad),

	cubic_in = port(inCubic),
	cubic_out = port(outCubic),
	cubic_in_out = port(inOutCubic),
	cubic_out_in = port(outInCubic),

	quart_in = port(inQuart),
	quart_out = port(outQuart),
	quart_in_out = port(inOutQuart),
	quart_out_in = port(outInQuart),

	quint_in = port(inQuint),
	quint_out = port(outQuint),
	quint_in_out = port(inOutQuint),
	quint_out_in = port(outInQuint),

	sine_in = port(inSine),
	sine_out = port(outSine),
	sine_in_out = port(inOutSine),
	sine_out_in = port(outInSine),

	expo_in = port(inExpo),
	expo_out = port(outExpo),
	expo_in_out = port(inOutExpo),
	expo_out_in = port(outInExpo),

	circ_in = port(inCirc),
	circ_out = port(outCirc),
	circ_in_out = port(inOutCirc),
	circ_out_in = port(outInCirc),

	elastic_in = port(inElastic),
	elastic_out = port(outElastic),
	elastic_in_out = port(inOutElastic),
	elastic_out_in = port(outInElastic),

	back_in = port(inBack),
	back_out = port(outBack),
	back_in_out = port(inOutBack),
	back_out_in = port(outInBack),

	bounce_in = port(inBounce),
	bounce_out = port(outBounce),
	bounce_in_out = port(inOutBounce),
	bounce_out_in = port(outInBounce),
}
