#############################################################################
# Copyright (C) 2021 CrowdWare
#
# This file is part of CancerWars.
#
#  CancerWars is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  CancerWars is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with CancerWars.  If not, see <http://www.gnu.org/licenses/>.
#
#############################################################################

extends Node

func draw_dashed_line(obj, from, to, color, width, dash_length = 5, cap_end = false, antialiased = false):
	var length = (to - from).length()
	var normal = (to - from).normalized()
	var dash_step = normal * dash_length
	
	if length < dash_length: #not long enough to dash
		obj.draw_line(from, to, color, width, antialiased)
		return

	else:
		var draw_flag = true
		var segment_start = from
		var steps = length/dash_length
		for _start_length in range(0, steps + 1):
			var segment_end = segment_start + dash_step
			if draw_flag:
				obj.draw_line(segment_start, segment_end, color, width, antialiased)

			segment_start = segment_end
			draw_flag = !draw_flag
		
		if cap_end:
			obj.draw_line(segment_start, to, color, width, antialiased)

