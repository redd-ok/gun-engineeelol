local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

-- Compiled with roblox-ts v1.3.3
local easing = require(script.easing)
local Signal = require(script.Parent.Signal)
local TS = require(script.TS.RuntimeLib)

-- easing.d.ts isn't exported when the package is packed so the types have to be copied over into here
local cached_tracks = {}
local active_caching_requests = {}
local cache_get_keyframe_sequence
cache_get_keyframe_sequence = function(id)
	-- prevents a race condition
	while active_caching_requests[id] do
		RunService.Heartbeat:Wait()
	end
	local sequence = cached_tracks[id]
	if sequence then
		return sequence:Clone()
	end
	local success, fail = pcall(function()
		active_caching_requests[id] = true
		sequence = KeyframeSequenceProvider:GetKeyframeSequenceAsync(id)
		active_caching_requests[id] = false
	end)
	if not success or not sequence then
		warn("GetKeyframeSequenceAsync() failed for id " .. id)
		warn(fail)
		active_caching_requests[id] = false
		return cache_get_keyframe_sequence(id)
	end
	-- a new call is made to clone the keyframe
	cached_tracks[id] = sequence
	return cache_get_keyframe_sequence(id)
end
local map = function(value, in_min, in_max, out_min, out_max)
	return ((value - in_min) * (out_max - out_min)) / (in_max - in_min) + out_min
end
-- conversion functions that go from Roblox format to canim
local convert_pose_instance = function(pose)
	return {
		cframe = pose.CFrame,
		name = pose.Name,
		weight = pose.Weight,
	}
end
local convert_keyframe_instance = function(keyframe)
	local children = {}
	for _, value in keyframe:GetDescendants() do
		local _value = value:IsA("Pose") and value.Weight
		if _value ~= 0 and (_value == _value and _value) then
			children[value.Name] = convert_pose_instance(value)
		end
	end
	return {
		name = keyframe.Name,
		time = keyframe.Time,
		children = children,
	}
end
local convert_keyframe_sequence_instance = function(sequence)
	local children = {}
	for _, value in sequence:GetChildren() do
		if value:IsA("Keyframe") then
			local _children = children
			local _arg0 = convert_keyframe_instance(value)
			table.insert(_children, _arg0)
		end
	end
	return {
		name = sequence.Name,
		children = children,
	}
end
local CanimPose
do
	CanimPose = setmetatable({}, {
		__tostring = function()
			return "CanimPose"
		end,
	})
	CanimPose.__index = CanimPose
	function CanimPose.new(...)
		local self = setmetatable({}, CanimPose)
		return self:constructor(...) or self
	end
	function CanimPose:constructor()
		self.keyframe_reached = Signal.new()
		self.finished_loading = Signal.new()
		self.started = Signal.new()
		self.finished = Signal.new()
		self.transitions = {}
		self.bone_weights = {}
		self.name = "animation_track"
		self.loaded = false
		self.priority = 0
		self.weight = 1
		self.time = 0
		self.looped = false
		self.stopping = false
		self.fade_time = 0.3
		self.fade_start = os.clock()
	end
	function CanimPose:load_sequence(id)
		task.spawn(function()
			local sequence = if typeof(id) == "Instance" then id else cache_get_keyframe_sequence(id)
			if sequence:IsA("Keyframe") then
				local actual_keyframe = convert_keyframe_instance(sequence)
				self.keyframe = actual_keyframe
			else
				local actual_sequence = convert_keyframe_sequence_instance(sequence)
				self.keyframe = actual_sequence.children[1]
			end
			-- a race condition may happen if the event isn't deferred
			task.defer(function()
				self.loaded = true
				self.finished_loading:Fire()
			end)
		end)
	end
end
local CanimTrack
do
	CanimTrack = setmetatable({}, {
		__tostring = function()
			return "CanimTrack"
		end,
	})
	CanimTrack.__index = CanimTrack
	function CanimTrack.new(...)
		local self = setmetatable({}, CanimTrack)
		return self:constructor(...) or self
	end
	function CanimTrack:constructor()
		self.transition_disable = {}
		self.transitions = {}
		self.keyframe_reached = Signal.new()
		self.finished_loading = Signal.new()
		self.finished = Signal.new()
		self.started = Signal.new()
		self.signals = {}
		self.bone_weights = {}
		self.disable_rebasing = {}
		self.name = "animation_track"
		self.stopping = false
		self.loaded = false
		self.priority = 0
		self.weight = 1
		self.speed = 1
		self.time = 0
		self.length = 0
		self.looped = false
		self.fade_time = 0.3
		self.transition_disable_all = false
		self.playing = false
	end
	function CanimTrack:load_sequence(id)
		task.spawn(function()
			self.signals = {}
			local sequence = if typeof(id) == "Instance" then id else cache_get_keyframe_sequence(id)
			sequence.Name = self.name
			local actual_sequence = convert_keyframe_sequence_instance(sequence)
			local highest_keyframe
			for _, keyframe in actual_sequence.children do
				local _exp = keyframe.time
				local _result = highest_keyframe
				if _result ~= nil then
					_result = _result.time
				end
				local _condition = _result
				if not (_condition ~= 0 and (_condition == _condition and _condition)) then
					_condition = 0
				end
				if _exp > _condition then
					highest_keyframe = keyframe
				end
				if keyframe.name ~= "Keyframe" then
					local _signals = self.signals
					local _arg0 = {
						played = false,
						time = keyframe.time,
						name = keyframe.name,
					}
					table.insert(_signals, _arg0)
				end
				-- idk what this does
				for rawindex, pose in keyframe.children do
					if pose.weight == 0 then
						task.defer(function()
							keyframe.children[rawindex] = nil
							return true
						end)
					end
				end
			end
			if not highest_keyframe then
				return nil
			end
			self.sequence = actual_sequence
			self.length = highest_keyframe.time
			-- roblox-ts types fucked up, https://developer.roblox.com/en-us/api-reference/property/KeyframeSequence/Loop
			self.looped = sequence.Loop
			self.last_keyframe = highest_keyframe
			-- a race condition may happen if the event isn't deferred
			task.defer(function()
				self.loaded = true
				self.finished_loading:Fire()
			end)
		end)
	end
end
local Canim
do
	Canim = setmetatable({}, {
		__tostring = function()
			return "Canim"
		end,
	})
	Canim.__index = Canim
	function Canim.new(...)
		local self = setmetatable({}, Canim)
		return self:constructor(...) or self
	end
	function Canim:constructor()
		self.identified_bones = {}
		self.playing_animations = {}
		self.playing_poses = {}
		self.animations = {}
		self.transitions = {}
		self.debug = {}
		self.fadeout_easing = easing.quad_in_out
	end
	function Canim:assign_model(model)
		self.model = model
		local _exp = self.model:GetDescendants()
		local _arg0 = function(element)
			if element:IsA("Motor6D") and element.Part1 then
				self.identified_bones[element.Part1.Name] = element
			end
		end
		for _k, _v in _exp do
			_arg0(_v, _k - 1, _exp)
		end
	end
	function Canim:destroy()
		for _, track in self.animations do
			track.finished_loading:Destroy()
			track.keyframe_reached:Destroy()
			track.started:Destroy()
			track.finished:Destroy()
		end
		for _, value in self.identified_bones do
			value.Transform = CFrame.new()
		end
	end
	function Canim:load_animation(name, priority, id)
		local track = CanimTrack.new()
		track.name = name
		track.priority = priority
		track:load_sequence(id)
		self.animations[name] = track
		return track
	end
	function Canim:load_pose(name, priority, id)
		local track = CanimPose.new()
		track.name = name
		track.priority = priority
		track:load_sequence(id)
		self.animations[name] = track
		return track
	end
	function Canim:play_animation(id)
		local track = self.animations[id]
		if not track then
			return warn("invalid animation: ", id)
		end
		if TS.instanceof(track, CanimPose) then
			error("attempted to play a pose as an playedanimation")
		end
		track.time = 0
		local _signals = track.signals
		local _arg0 = function(element)
			element.played = false
		end
		for _k, _v in _signals do
			_arg0(_v, _k - 1, _signals)
		end
		if not (table.find(self.playing_animations, track) ~= nil) then
			local _playing_animations = self.playing_animations
			table.insert(_playing_animations, track)
			track.started:Fire()
		end
		return track
	end
	function Canim:play_pose(id)
		local track = self.animations[id]
		if not track then
			return warn("invalid animation: ", id)
		end
		if TS.instanceof(track, CanimTrack) then
			error("attempted to play a pose as an animation")
		end
		if not (table.find(self.playing_poses, track) ~= nil) then
			local _playing_poses = self.playing_poses
			table.insert(_playing_poses, track)
		end
		return track
	end
	function Canim:stop_animation(name)
		for _, value in self.playing_animations do
			if value.name == name then
				value.stopping = true
			end
		end
		for _, value in self.playing_poses do
			if value.name == name then
				value.stopping = true
			end
		end
	end
	function Canim:update(delta_time)
		local weight_sum = {}
		local weight_sum_rebased = {}
		local bone_totals = {}
		local new_playing_animations = {}
		local debug = {}
		-- manage the state of currently playing animations before displaying the result
		-- if this was done inside the first loop the rig would flicker randomly
		-- manages the playback of the animations before they are finally rendered
		for _, track in self.playing_animations do
			track.time += delta_time * track.speed
			if track.time >= track.length or (track.time < 0 or track.stopping) then
				for _, element in track.signals do
					if track.time >= element.time and not element.played then
						element.played = true
						task.spawn(function()
							track.keyframe_reached:Fire(element.name)
						end)
					end
				end
				if track.looped and not track.stopping then
					track.playing = false
					track.finished:Fire()
					for _, element in track.signals do
						element.played = false
					end
				else
					track.stopping = false
					track.playing = false
					track.finished:Fire()
					-- transition to idle once the animation is ready for it
					if track.last_keyframe then
						if track.queued_animation then
							self:play_animation(track.queued_animation.name)
						elseif not track.rebase_target then
							for _, value in track.last_keyframe.children do
								local _exp = self.transitions
								local _index = value.name
								if _exp[_index] == nil then
									_exp[_index] = {}
								end
								if not track.transition_disable[value.name] and not track.transition_disable_all then
									local cframe = value.cframe
									local _exp_1 = self.transitions[value.name]
									local _arg0 = {
										start = os.clock(),
										finish = os.clock() + track.fade_time,
										cframe = cframe,
									}
									table.insert(_exp_1, _arg0)
								end
							end
						end
						continue
					end
				end
			end
			table.insert(new_playing_animations, track)
		end
		for _, track in new_playing_animations do
			if not track.loaded or not track.sequence then
				continue
			end
			if track.time >= track.length and track.looped then
				track.time -= track.length
			end
			local _arg0 = "Track " .. (string.format("%.2f", track.time) .. (" " .. (string.format("%.2f", track.weight) .. (" " .. (track.name .. (" " .. tostring(track.looped)))))))
			table.insert(debug, _arg0)
			track.playing = true
			local first = nil
			local last = nil
			for _, keyframe in track.sequence.children do
				if keyframe.time >= track.time and not last then
					last = keyframe
				elseif keyframe.time <= track.time then
					first = keyframe
				end
			end
			if not first or not last then
				local _arg0_1 = "Invalid KeyframeSequence for track named " .. (track.name .. (", time: " .. tostring(track.time)))
				table.insert(debug, _arg0_1)
				continue
			end
			for _, element in track.signals do
				if track.time >= element.time and not element.played then
					element.played = true
					task.spawn(function()
						track.keyframe_reached:Fire(element.name)
					end)
				end
			end
			track.last_keyframe = first
			local bias = map(track.time, first.time, last.time, 0, 1)
			for _, value in first.children do
				local bone = self.identified_bones[value.name]
				if bone and bone.Part1 then
					local a = value
					local b = last.children[value.name]
					local unblended_cframe = a.cframe:Lerp(b.cframe, bias)
					local weight = track.bone_weights[value.name] or (track.bone_weights.__CANIM_DEFAULT_BONE_WEIGHT or { { 1, 1, 1 }, { 1, 1, 1 } })
					local blended_cframe = unblended_cframe
					local part1_name = bone.Part1.Name
					if not track.disable_rebasing[part1_name] and (track.rebase_target and (track.rebase_target.keyframe and track.rebase_target.keyframe.children[part1_name])) then
						if track.rebase_basis and (track.rebase_basis.keyframe and track.rebase_basis.keyframe.children[part1_name]) then
							local basis = track.rebase_basis.keyframe.children[part1_name].cframe
							local _blended_cframe = blended_cframe
							local _arg0_1 = basis:Inverse()
							blended_cframe = _blended_cframe * _arg0_1
						else
							local _blended_cframe = blended_cframe
							local _arg0_1 = track.rebase_target.keyframe.children[part1_name].cframe:Inverse()
							blended_cframe = _blended_cframe * _arg0_1
						end
						local components = { blended_cframe:ToEulerAnglesXYZ() }
						blended_cframe = CFrame.new(blended_cframe.X * weight[1][1] * track.weight, blended_cframe.Y * weight[1][2] * track.weight, blended_cframe.Z * weight[1][3] * track.weight)
						local _blended_cframe = blended_cframe
						local _arg0_1 = CFrame.Angles(components[1] * weight[2][1] * track.weight, components[2] * weight[2][2] * track.weight, components[3] * weight[2][3] * track.weight)
						blended_cframe = _blended_cframe * _arg0_1
						local sum = weight_sum_rebased[bone] or {}
						local _sum = sum
						local _arg0_2 = { track.priority, blended_cframe }
						table.insert(_sum, _arg0_2)
						local _sum_1 = sum
						weight_sum_rebased[bone] = _sum_1
					else
						local components = { blended_cframe:ToEulerAnglesXYZ() }
						blended_cframe = CFrame.new(unblended_cframe.X * weight[1][1] * track.weight, unblended_cframe.Y * weight[1][2] * track.weight, unblended_cframe.Z * weight[1][3] * track.weight)
						local _blended_cframe = blended_cframe
						local _arg0_1 = CFrame.Angles(components[1] * weight[2][1] * track.weight, components[2] * weight[2][2] * track.weight, components[3] * weight[2][3] * track.weight)
						blended_cframe = _blended_cframe * _arg0_1
						local sum = weight_sum[bone] or {}
						local _sum = sum
						local _arg0_2 = { track.priority, blended_cframe }
						table.insert(_sum, _arg0_2)
						local _sum_1 = sum
						weight_sum[bone] = _sum_1
					end
				end
			end
		end
		for _, track in self.playing_poses do
			local _arg0 = "Pose " .. (track.name .. (" " .. tostring(track.time)))
			table.insert(debug, _arg0)
			if not track.loaded or not track.keyframe then
				continue
			end
			local first = track.keyframe
			if not first then
				local _arg0_1 = "Invalid KeyframeSequence for pose named " .. (track.name .. (", time: " .. tostring(track.time)))
				table.insert(debug, _arg0_1)
				continue
			end
			for _, value in first.children do
				local bone = self.identified_bones[value.name]
				if bone then
					local sum = weight_sum[bone] or {}
					local _sum = sum
					local _arg0_1 = { track.priority, value.cframe }
					table.insert(_sum, _arg0_1)
					local _sum_1 = sum
					weight_sum[bone] = _sum_1
				end
			end
		end
		for index, value in self.identified_bones do
			local sum = weight_sum[value] or {}
			local _sum = sum
			local _arg0 = { -1000, CFrame.new() }
			table.insert(_sum, _arg0)
			local _sum_1 = sum
			weight_sum[value] = _sum_1
		end
		for index, value in weight_sum do
			table.sort(value, function(a, b)
				return a[1] > b[1]
			end)
			-- transitions only work inbetween the last animation to play and any poses.
			if index.Part1 then
				local target_cframe = value[1][2]
				local transitions = self.transitions[index.Part1.Name]
				if transitions then
					for transition_index, transition in transitions do
						if transition.finish == 0 then
							transition.finish = os.clock() + math.huge
							transitions[transition_index - 1 + 1] = nil
						end
						if transition.finish >= os.clock() and #weight_sum[index] <= 2 then
							local alpha = self.fadeout_easing(map(os.clock(), transition.start, transition.finish, 1, 0))
							target_cframe = target_cframe:Lerp(transition.cframe, alpha)
						elseif transition.finish <= os.clock() then
							transitions[transition_index - 1 + 1] = nil
						end
					end
				end
				local _target_cframe = target_cframe
				bone_totals[index] = _target_cframe
			end
		end
		-- rebased transitions are probably disabled again?
		for index, value in weight_sum_rebased do
			if not index.Part1 then
				continue
			end
			for _, data in value do
				local target_cframe = data[2]
				-- let transitions = this.transitions[index.Part1.Name];
				-- if (transitions) {
				-- for (const [transition_index, transition] of pairs(transitions)) {
				-- if (transition && transition.finish >= os.clock() && weight_sum.get(index)!.size() === 1) {
				-- let alpha = this.fadeout_easing(map(os.clock(), transition.start, transition.finish, 1, 0));
				-- target_cframe = target_cframe.Lerp(transition.cframe, alpha);
				-- } else {
				-- delete transitions[transition_index];
				-- }
				-- }
				-- }
				local _target_cframe = target_cframe
				local _arg0 = bone_totals[index] or CFrame.new()
				bone_totals[index] = _target_cframe * _arg0
			end
		end
		for index, value in bone_totals do
			index.Transform = value
		end
		self.playing_animations = new_playing_animations
		self.debug = debug
	end
end

local CanimEasing = easing

return {
	cache_get_keyframe_sequence = cache_get_keyframe_sequence,
	CanimPose = CanimPose,
	CanimTrack = CanimTrack,
	Animator = Canim,
	CanimEasing = CanimEasing,
}