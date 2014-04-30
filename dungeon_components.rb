module Roguelike
	class Room
		MIN_WIDTH = 5
		MAX_WIDTH = 9

		MIN_HEIGHT = 3
		MAX_HEIGHT = 7

		attr_reader :joins, :x1, :x2, :y1, :y2
		attr_accessor :loopy

		def initialize(x1, y1, x2, y2, map)
			if x1 < 1 || y1 < 1 || x2 < 1 || y2 < 1
				raise Error, "Room coordinate out of bounds1: (#{x1}, #{y1}) - (#{x2}, #{y2})"
			end

			if x1 >= (map.columns - 1) || x2 >= (map.columns - 1) || y1 >= (map.rows - 1) || y2 >= (map.rows - 1)
				raise Error, "Room coordinate out of bounds2: (#{x1}, #{y1}) - (#{x2}, #{y2})"
			end

			if x2 <= x1 || y2 <= y1
				raise Error, "Room coordinate out of bounds3: (#{x1}, #{y1}) - (#{x2}, #{y2})"
			end

			raise Error, "Room overlaps something" unless map.area_empty?(x1 - 1, y1 - 1, x2 + 1, y2 + 1)

			@x1, @y1, @x2, @y2 = x1, y1, x2, y2
			@map = map

			# track places where the room spawns corridors
			@joins = []

			# calculate potential joins
			@potential_joins = []
			[y1 - 1, y2 + 1].each_with_index do |row, idx|
				if row > 1 && row < map.rows - 2
					ary = (x1 .. x2).to_a.select{ |x| x.odd? }
				else
					ary = []
				end
				ary.each do |col|
					@potential_joins.push([col, row, (idx * 2 + 1)])
				end
			end
			[x1 - 1, x2 + 1].each_with_index do |col, idx|
				if col > 1 && col < map.columns - 2
					ary = (y1 .. y2).to_a.select{ |x| x.odd? }
				else
					ary = []
				end
				ary.each do |row|
					@potential_joins.push([col, row, (2 - idx * 2)])
				end
			end
		end

		def width
			x2 - x1 + 1
		end

		def height
			y2 - y1 + 1
		end

		def area
			width * height
		end

		def contains?(x, y)
			# return 2 if loopy && (@x1..@x2) === x && (@y1..@y2) === y
			return true if (x1..x2) === x && (y1..y2) === y

			false
		end

		def overlaps?(x1, y1, x2, y2)
			# those "- 1"s are there to ensure that there's always at least a gap of one wall
			return true if ((x1 - 1) < (@x2 + 1) && (@x1 - 1) <= (x2 + 1)) && ((y1 - 1) < (@y2 + 1) && (@y1 -1 ) < (y2 + 1))

			false
		end

		def add_join
			# no infinite recursion. Just pick one from the list!
			return false if @potential_joins.empty?

			pj = @potential_joins.sample
			@potential_joins -= [pj]
			join = Join.new(pj[0], pj[1], pj[2], self)
			@joins.push(join)

			join
		end

		def pop_join
			join = @joins.pop
			@potential_joins.push([join.x, join.y, join.direction])
		end

		def with_joins
			return nil if @potential_joins.empty?

			self
		end
	end

	class Join
		attr_reader :x, :y, :direction, :room

		def initialize(x, y, direction, room)
			@x, @y     = x, y
			@direction = direction
			@room      = room
		end
	end

	class Corridor
		MIN_LENGTH = 3
		MAX_LENGTH = 13

		attr_reader :x1, :y1, :x2, :y2, :start_x, :start_y, :end_x, :end_y, :direction, :length, :map, :looped

		def initialize(start_x, start_y, direction, map, length = nil)
			# TODO: This needs to ensure that it also rejects corridors adjacent to non-rock places

			@start_x, @start_y = start_x, start_y
			@direction         = direction
			@map               = map
			@looped            = false

			raise ArgumentError, "Invalid direction" if !(0..3).include?(direction)

			if length.nil?
				length = random_length
			end

			# figure out starting and ending points
			if direction == 0
				end_x = start_x + length - 1
				end_x = map.columns - 1 if end_x >= map.columns - 1
				length = (end_x - start_x).abs + 1
				end_y = start_y
			elsif direction == 1
				end_y = start_y - length + 1
				length = (end_y - start_y).abs + 1
				end_x = start_x
			elsif direction == 2
				end_x = start_x - length + 1
				length = (end_x - start_x).abs + 1
				end_y = start_y
			elsif direction == 3
				end_y = start_y + length - 1
				length = (end_y - start_y).abs + 1
				end_x = start_x
			end

			@end_x = end_x
			@end_y = end_y

			# note that we don't just use dungeon_level.area_empty? here.
			# this is because we actually want to make the corridor if it can go a ways and then
			# join up with a corridor or room.

			# determine if the corridor has a free starting point and whether it's looped
			safe_x, safe_y = find_safe_length(end_x, end_y)
			# if even the starting point is bad, throw up your hands
			raise Error, "Corridor starting point overlaps something" if [safe_x, safe_y] == [nil, nil]

			# set endpoint as the last free space in the corridor if it's looped
			if @looped
				@end_x = safe_x
				@end_y = safe_y

				if direction.even?
					length = (@end_x - @start_x).abs + 1
				else
					length = (@end_y - @start_y).abs + 1
				end
			end

			@length = length

			@x1 = [@start_x, @end_x].min
			@x2 = [@start_x, @end_x].max
			@y1 = [@start_y, @end_y].min
			@y2 = [@start_y, @end_y].max

			raise Error, "Corridor coordinates out of bounds" if length < 2 || x1 <= 0 || x2 >= (map.columns - 1) || y1 <= 0 || y2 >= (map.rows - 1)
		end

		def random_length
			Random.rand(((MAX_LENGTH - MIN_LENGTH) / 2) + 1) * 2 + MIN_LENGTH
		end

		def find_safe_length(end_x, end_y)
			safe_x = safe_y = nil

			x_ary = [start_x, end_x]
			x_vals = (x_ary.min .. x_ary.max).to_a
			x_vals.reverse! if end_x < start_x

			y_ary = [start_y, end_y]
			y_vals = (y_ary.min .. y_ary.max).to_a
			y_vals.reverse! if end_y < start_y

			x_vals.each do |x|
				y_vals.each do |y|
					if map.unoccupied?(x, y)
						safe_x, safe_y = x, y
					else
						@looped = true
						return [safe_x, safe_y]
					end
				end
			end
			@looped = false
		end

		def contains?(x, y)
			(x1 .. x2).include?(x) && (y1 .. y2).include?(y)
		end
	end
end
