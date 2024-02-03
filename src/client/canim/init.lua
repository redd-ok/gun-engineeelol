--!nocheck
--# selene: allow(mismatched_arg_count)
--# selene: allow(unused_variable)

local Signal = require(script:WaitForChild("dependencies"):WaitForChild("Signal"))
local Maid = require(script:WaitForChild("dependencies"):WaitForChild("Maid"))
local easing = require(script:WaitForChild("easing"):WaitForChild("easing"))
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
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
local is_pose = function(track)
	return track.animation_type == 1
end
local is_track = function(track)
	return track.animation_type == 0
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
	for _, value in pairs(keyframe:GetDescendants()) do
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
	for _, value in pairs(sequence:GetChildren()) do
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
		self.animation_type = 1
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
		self.fade_start = tick()
	end
	function CanimPose:load_sequence(id)
		task.spawn(function()
			local _id = id
			local sequence = if typeof(_id) == "Instance" then id else cache_get_keyframe_sequence(id)
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
		self.animation_type = 0
		self.transition_disable = {}
		self.keyframe_reached = Signal.new()
		self.finished_loading = Signal.new()
		self.finished = Signal.new()
		self.started = Signal.new()
		self.signals = {}
		self.bone_weights = {}
		self.disable_rebasing = {}
		self.name = "animation_track"
		self.stopping = false
		self.init_transitions = false
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
			local _id = id
			local sequence = if typeof(_id) == "Instance" then id else cache_get_keyframe_sequence(id)
			sequence.Name = self.name
			local actual_sequence = convert_keyframe_sequence_instance(sequence)
			local highest_keyframe
			for _, keyframe in pairs(actual_sequence.children) do
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
				for rawindex, pose in pairs(keyframe.children) do
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
		self.new_animations = {}
		self.queue_to_new_animations = false
		self.animations = {}
		self.transitions = {}
		self.transitions_rebased = {}
		self.maid = Maid.new()
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
		self.maid:DoCleaning()
		for _, track in pairs(self.animations) do
			track.finished_loading:Destroy()
			track.keyframe_reached:Destroy()
			track.started:Destroy()
			track.finished:Destroy()
		end
		for _, value in pairs(self.identified_bones) do
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
		if is_pose(track) then
			error("attempted to play a pose as an animation")
		end
		track.playing = true
		track.time = 0
		track.started:Fire()
		local _signals = track.signals
		local _arg0 = function(element)
			element.played = false
		end
		for _k, _v in _signals do
			_arg0(_v, _k - 1, _signals)
		end
		if self.queue_to_new_animations then
			local _new_animations = self.new_animations
			local _name = track.name
			_new_animations[_name] = track
		else
			local _playing_animations = self.playing_animations
			local _name = track.name
			_playing_animations[_name] = track
		end
		return track
	end
	function Canim:play_pose(id)
		local pose = self.animations[id]
		if not pose then
			return warn("invalid animation: ", id)
		end
		if is_track(pose) then
			error("attempted to play an animation as a pose")
		end
		pose.started:Fire()
		local _playing_poses = self.playing_poses
		local _name = pose.name
		_playing_poses[_name] = pose
		return pose
	end
	function Canim:stop_animation(name)
		local _playing_animations = self.playing_animations
		local _name = name
		local track = _playing_animations[_name]
		local _playing_poses = self.playing_poses
		local _name_1 = name
		local pose = _playing_poses[_name_1]
		if track then
			track.stopping = true
		end
		if pose then
			self:finish_animation(pose)
		end
	end
	function Canim:update_track(track, weight_sum_rebased, weight_sum)
		local first = nil
		local last = nil
		for _, keyframe in pairs(track.sequence.children) do
			if keyframe.time >= track.time and not last then
				last = keyframe
			elseif keyframe.time <= track.time then
				first = keyframe
			end
		end
		if not first or not last then
			local _debug = self.debug
			local _arg0 = "Invalid KeyframeSequence for track named " .. (track.name .. (", time: " .. tostring(track.time)))
			table.insert(_debug, _arg0)
			return nil
		end
		for _, element in pairs(track.signals) do
			if track.time >= element.time and not element.played then
				element.played = true
				track.keyframe_reached:Fire(element.name)
			end
		end
		track.last_keyframe = first
		local bias = map(track.time, first.time, last.time, 0, 1)
		for _, value in pairs(first.children) do
			local bone = self.identified_bones[value.name]
			if bone and bone.Part1 then
				local a = value
				local b = last.children[value.name]
				local unblended_cframe = a.cframe:Lerp(b.cframe, bias)
				local disable_transitions = track.transition_disable_all or track.transition_disable[value.name]
				local weight = track.bone_weights[value.name] or (track.bone_weights.__CANIM_DEFAULT_BONE_WEIGHT or { { 1, 1, 1 }, { 1, 1, 1 } })
				local blended_cframe = unblended_cframe
				local part1_name = bone.Part1.Name
				if not track.disable_rebasing[part1_name] and (track.rebase_target and (track.rebase_target.keyframe and track.rebase_target.keyframe.children[part1_name])) then
					if track.rebase_basis and (track.rebase_basis.keyframe and track.rebase_basis.keyframe.children[part1_name]) then
						local basis = track.rebase_basis.keyframe.children[part1_name].cframe
						local _blended_cframe = blended_cframe
						local _arg0 = basis:Inverse()
						blended_cframe = _blended_cframe * _arg0
					else
						local _blended_cframe = blended_cframe
						local _arg0 = track.rebase_target.keyframe.children[part1_name].cframe:Inverse()
						blended_cframe = _blended_cframe * _arg0
					end
					local components = { blended_cframe:ToEulerAnglesXYZ() }
					blended_cframe = CFrame.new(blended_cframe.X * weight[1][1] * track.weight, blended_cframe.Y * weight[1][2] * track.weight, blended_cframe.Z * weight[1][3] * track.weight)
					local _blended_cframe = blended_cframe
					local _arg0 = CFrame.Angles(components[1] * weight[2][1] * track.weight, components[2] * weight[2][2] * track.weight, components[3] * weight[2][3] * track.weight)
					blended_cframe = _blended_cframe * _arg0
					if track.init_transitions then
						if not disable_transitions then
							local sum = self.transitions_rebased[bone] or {}
							local _sum = sum
							local _arg0_1 = { track.priority, {
								start = tick(),
								finish = tick() + track.fade_time,
								cframe = blended_cframe,
							} }
							table.insert(_sum, _arg0_1)
							local _transitions_rebased = self.transitions_rebased
							local _sum_1 = sum
							_transitions_rebased[bone] = _sum_1
						end
					else
						local sum = weight_sum_rebased[bone] or {}
						local _sum = sum
						local _arg0_1 = { track.priority, blended_cframe }
						table.insert(_sum, _arg0_1)
						local _weight_sum_rebased = weight_sum_rebased
						local _sum_1 = sum
						_weight_sum_rebased[bone] = _sum_1
					end
				else
					local components = { blended_cframe:ToEulerAnglesXYZ() }
					blended_cframe = CFrame.new(unblended_cframe.X * weight[1][1] * track.weight, unblended_cframe.Y * weight[1][2] * track.weight, unblended_cframe.Z * weight[1][3] * track.weight)
					local _blended_cframe = blended_cframe
					local _arg0 = CFrame.Angles(components[1] * weight[2][1] * track.weight, components[2] * weight[2][2] * track.weight, components[3] * weight[2][3] * track.weight)
					blended_cframe = _blended_cframe * _arg0
					if track.init_transitions and not disable_transitions then
						local sum = self.transitions[bone] or {}
						local _sum = sum
						local _arg0_1 = { track.priority, {
							start = tick(),
							finish = tick() + track.fade_time,
							cframe = blended_cframe,
						} }
						table.insert(_sum, _arg0_1)
						local _transitions = self.transitions
						local _sum_1 = sum
						_transitions[bone] = _sum_1
					else
						local sum = weight_sum[bone] or {}
						local _sum = sum
						local _arg0_1 = { track.priority, blended_cframe }
						table.insert(_sum, _arg0_1)
						local _weight_sum = weight_sum
						local _sum_1 = sum
						_weight_sum[bone] = _sum_1
					end
				end
			end
		end
	end
	function Canim:finish_animation(track)
		track.stopping = false
		track.finished:Fire()
		if is_pose(track) then
			local _playing_poses = self.playing_poses
			local _name = track.name
			_playing_poses[_name] = nil
		else
			local _playing_animations = self.playing_animations
			local _name = track.name
			_playing_animations[_name] = nil
			track.playing = false
		end
	end
	function Canim:update_track_state(track, delta_time)
		if not track.loaded or not track.sequence then
			return nil
		end
		track.time += delta_time * track.speed
		if track.time >= track.length then
			if track.looped then
				for _, element in pairs(track.signals) do
					element.played = false
				end
				track.finished:Fire()
				track.time -= track.length
			else
				track.stopping = true
				track.time = track.length
			end
		end
		local init_transitions = false
		if track.stopping then
			init_transitions = true
			self:finish_animation(track)
			if track.transition_disable_all then
				return nil
			end
		end
		track.init_transitions = init_transitions
		local str = "Track name=" .. (track.name .. (" looped=" .. (tostring(track.looped) .. (" time=" .. (tostring(track.time) .. (" weight=" .. tostring(track.weight)))))))
		if init_transitions then
			str ..= " stopping"
		end
		local _debug = self.debug
		local _str = str
		table.insert(_debug, _str)
		if track.weight == 0 then
			return nil
		end
		return true
	end
	function Canim:update(delta_time)
		local weight_sum = {}
		local weight_sum_rebased = {}
		local bone_totals = {}
		self.debug = {}
		self.queue_to_new_animations = true
		self.new_animations = {}
		local animation_list = {}
		for _, track in pairs(self.playing_animations) do
			local should_push_to_animations = self:update_track_state(track, delta_time)
			if should_push_to_animations then
				table.insert(animation_list, track)
			end
		end
		-- sometimes the finished event queues more animations this frame so they also need to be iterated over
		-- it can be done above but it makes for non deterministic behavior and flickering
		for _, track in pairs(self.new_animations) do
			local should_push_to_animations = self:update_track_state(track, delta_time)
			if should_push_to_animations then
				table.insert(animation_list, track)
			end
			local _playing_animations = self.playing_animations
			local _name = track.name
			_playing_animations[_name] = track
		end
		self.queue_to_new_animations = false
		-- needs to stay consistent or otherwise the animations will be layered incorrectly, causing flickering
		-- animations should generally assign different priorities because of this
		table.sort(animation_list, function(a, b)
			return a.priority > b.priority
		end)
		for _, value in pairs(animation_list) do
			self:update_track(value, weight_sum_rebased, weight_sum)
		end
		for _, track in pairs(self.playing_poses) do
			local _debug = self.debug
			local _arg0 = "Pose " .. (track.name .. (" " .. tostring(track.time)))
			table.insert(_debug, _arg0)
			if not track.loaded or not track.keyframe then
				continue
			end
			local first = track.keyframe
			if not first then
				local _debug_1 = self.debug
				local _arg0_1 = "Invalid KeyframeSequence for pose named " .. (track.name .. (", time: " .. tostring(track.time)))
				table.insert(_debug_1, _arg0_1)
				continue
			end
			for _, value in pairs(first.children) do
				local bone = self.identified_bones[value.name]
				if bone then
					local cframe = value.cframe
					local components = { cframe:ToEulerAnglesXYZ() }
					local weight = track.bone_weights[value.name] or (track.bone_weights.__CANIM_DEFAULT_BONE_WEIGHT or { { 1, 1, 1 }, { 1, 1, 1 } })
					cframe = CFrame.new(cframe.X * weight[1][1] * track.weight, cframe.Y * weight[1][2] * track.weight, cframe.Z * weight[1][3] * track.weight)
					local _cframe = cframe
					local _arg0_1 = CFrame.Angles(components[1] * weight[2][1] * track.weight, components[2] * weight[2][2] * track.weight, components[3] * weight[2][3] * track.weight)
					cframe = _cframe * _arg0_1
					local sum = weight_sum[bone] or {}
					local _sum = sum
					local _arg0_2 = { track.priority, cframe }
					table.insert(_sum, _arg0_2)
					local _sum_1 = sum
					weight_sum[bone] = _sum_1
				end
			end
		end
		-- this is required for transitions to work as otherwise the transitions aren't processed below
		for index, value in pairs(self.identified_bones) do
			local sum = weight_sum[value] or {}
			local _sum = sum
			local _arg0 = { -math.huge, CFrame.new() }
			table.insert(_sum, _arg0)
			local _sum_1 = sum
			weight_sum[value] = _sum_1
			local rebased_sum = weight_sum_rebased[value] or {}
			local _rebased_sum = rebased_sum
			local _arg0_1 = { -math.huge, CFrame.new() }
			table.insert(_rebased_sum, _arg0_1)
			local _rebased_sum_1 = rebased_sum
			weight_sum_rebased[value] = _rebased_sum_1
		end
		-- regular animations display the lowest priority animation without any layering, so you simply sort what's playing and use the first result
		for motor, animation_cframes in weight_sum do
			if not motor.Part1 then
				continue
			end
			table.sort(animation_cframes, function(a, b)
				return a[1] > b[1]
			end)
			local target_cframe = animation_cframes[1][2]
			local transitions = self.transitions[motor]
			if transitions then
				for transition_index, _binding in pairs(transitions) do
					local priority = _binding[1]
					local transition = _binding[2]
					if transition.finish == 0 then
						transition.finish = tick() + math.huge
						transitions[transition_index - 1 + 1] = nil
					end
					if transition.finish >= tick() and #weight_sum[motor] <= 2 then
						local alpha = self.fadeout_easing(map(tick(), transition.start, transition.finish, 1, 0))
						target_cframe = target_cframe:Lerp(transition.cframe, alpha)
					elseif transition.finish <= tick() then
						transitions[transition_index - 1 + 1] = nil
					end
				end
			end
			local _target_cframe = target_cframe
			bone_totals[motor] = _target_cframe
		end
		-- rebased animations can be layered so they have to iterate
		for motor, animation_cframes in weight_sum_rebased do
			if not motor.Part1 then
				continue
			end
			local target_cframe = CFrame.new()
			for _, _binding in pairs(animation_cframes) do
				local id = _binding[1]
				local cframe = _binding[2]
				local iteration_target_cframe = cframe
				local _target_cframe = target_cframe
				local _iteration_target_cframe = iteration_target_cframe
				target_cframe = _target_cframe * _iteration_target_cframe
			end
			local transitions = self.transitions_rebased[motor]
			if transitions then
				local transition_amount = #transitions
				if transition_amount == 0 then
					self.transitions_rebased[motor] = nil
				end
				local _debug = self.debug
				local _arg0 = "Motor Transition " .. (motor.Name .. (" " .. tostring(transition_amount)))
				table.insert(_debug, _arg0)
				for transition_index, _binding in pairs(transitions) do
					local id = _binding[1]
					local transition = _binding[2]
					if transition.finish == 0 then
						transition.finish = tick() + math.huge
						transitions[transition_index - 1 + 1] = nil
					end
					if transition.finish >= tick() then
						local alpha = self.fadeout_easing(map(tick(), transition.start, transition.finish, 1, 0))
						local _target_cframe = target_cframe
						local _arg0_1 = CFrame.new():Lerp(transition.cframe, alpha)
						target_cframe = _target_cframe * _arg0_1
					elseif transition.finish <= tick() then
						transitions[transition_index - 1 + 1] = nil
					end
				end
			end
			local existing_cf = bone_totals[motor]
			if existing_cf then
				local _target_cframe = target_cframe
				local _existing_cf = existing_cf
				bone_totals[motor] = _target_cframe * _existing_cf
			else
				local _target_cframe = target_cframe
				bone_totals[motor] = _target_cframe
			end
		end
		-- sometimes there isn't any actual animation playing except for a transition
		-- untested lol
		for motor, transitions in self.transitions_rebased do
			if not motor.Part1 then
				continue
			end
			local motor_weight_sums = weight_sum_rebased[motor]
			if motor_weight_sums then
				continue
			end
			local target_cframe = CFrame.new()
			local transition_amount = #transitions
			if transition_amount == 0 then
				self.transitions_rebased[motor] = nil
			end
			local _debug = self.debug
			local _arg0 = "Motor Transition " .. (motor.Name .. (" " .. tostring(transition_amount)))
			table.insert(_debug, _arg0)
			for transition_index, _binding in pairs(transitions) do
				local id = _binding[1]
				local transition = _binding[2]
				if transition.finish == 0 then
					transition.finish = tick() + math.huge
					transitions[transition_index - 1 + 1] = nil
				end
				if transition.finish >= tick() then
					local alpha = self.fadeout_easing(map(tick(), transition.start, transition.finish, 1, 0))
					local _target_cframe = target_cframe
					local _arg0_1 = CFrame.new():Lerp(transition.cframe, alpha)
					target_cframe = _target_cframe * _arg0_1
				elseif transition.finish <= tick() then
					transitions[transition_index - 1 + 1] = nil
				end
			end
			local existing_cf = bone_totals[motor]
			if existing_cf then
				local _target_cframe = target_cframe
				local _existing_cf = existing_cf
				bone_totals[motor] = _target_cframe * _existing_cf
			else
				local _target_cframe = target_cframe
				bone_totals[motor] = _target_cframe
			end
		end
		for index, value in bone_totals do
			index.Transform = value
		end
	end
end
local CanimEasing = easing
return {
	cache_get_keyframe_sequence = cache_get_keyframe_sequence,
	CanimPose = CanimPose,
	CanimTrack = CanimTrack,
	Canim = Canim,
	CanimEasing = CanimEasing,
}
