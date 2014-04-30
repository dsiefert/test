require 'ncursesw'

module Roguelike
	require_relative 'point'
	require_relative 'tile'
	require_relative 'item'

	class DungeonLevel
		# has tiles
		# has items
		# 	including monsters
		# 		including the PC
		#
		# probably has random dungeon map

		ROOM_RATIO = 0.3
		LOOP_RATIO = 0.1

		attr_reader :columns, :rows, :rooms, :corridors, :offset_y, :offset_x, :map_attempts

		def initialize(title = "A mysterious dungeon", columns = 78, rows = 23, has_random_map = true, min_rooms = 6)
			Event.new("initialize", self)

			@columns        = columns
			@rows           = rows
			@has_random_map = has_random_map
			@title          = title.slice(0, 72)
			@rooms          = []
			@corridors      = []
			@tiles          = []
			@map_attempts   = 0

			@offset_x = ((80 - @columns) / 2).floor
			@offset_y = ((25 - @rows) / 2).floor

			create_map(min_rooms) if has_random_map
		end

		def draw
			# actually draw it onscreen
			# on every point on the map:
			# 	draw tile if visible
			# every item (inc monsters inc PC)
			# 	draw item if item is on a visible point and is visible
			@tiles.each{ |tile| tile.draw }

			# draw the frame around the map
			frame_symbol = "+"
			if @offset_y > 0 && @offset_x > 0
				$window.attron(Ncurses::COLOR_PAIR(8))
				$window.mvaddstr(@offset_y - 1, @offset_x - 1, frame_symbol * (@columns + 2))
				@rows.times do |row|
					$window.mvaddstr(row + @offset_y, @offset_x - 1, frame_symbol)
					$window.mvaddstr(row + @offset_y, @offset_x + @columns, frame_symbol)
				end
				$window.mvaddstr(@rows + @offset_y, @offset_x - 1, frame_symbol * (@columns + 2))
			end

			# and the title. note that we trim it to 72 max to allow three columns plus a space on either side
			$window.mvaddstr(@offset_y - 1, 3, " #{@title} ")

			# set the cursor to the player's current position
			Game.player.draw
#			Dispatcher.display_messages
			$window.move(Game.player.y + offset_y, Game.player.x + offset_x)

			# all done!
			$window.refresh
			Event.new("draw-complete", self)
		end

		def upstairs
			# return DungeonLevel above this one, if any
		end

		def downstairs
			# return DungeonLevel below this one, if any
		end

		def unoccupied?(x, y)
			return tile_type(x, y) == false
		end

		def area_empty?(x1, y1, x2, y2, options = {})
			exceptions = options.key?(:except) ? options.delete(:except) : []

			if x2 < x1
				x_range = (x2 .. x1)
			else
				x_range = (x1 .. x2)
			end

			if y2 < y1
				y_range = (y2 .. y1)
			else
				y_range = (y1 .. y2)
			end

			x_range.each do |x|
				y_range.each do |y|
					next if exceptions.include?([x, y])
					return false if tile_type(x, y)
				end
			end

			true
		end

		def room_area
			val = 0
			rooms.each do |room|
				val += room.area
			end

			val
		end

	private

		def random_row(range = nil)
			return Random.rand(rows / 2) * 2 + 1 unless range

			odd_from_range(range)
		end

		def random_column(range = nil)
			return Random.rand(columns / 2) * 2 + 1 unless range

			odd_from_range(range)
		end

		def odd_from_range(range)
			range.to_a.select{ |x| x.odd? }.sample
		end

		def random_width
			Random.rand(((Room::MAX_WIDTH - Room::MIN_WIDTH) / 2) + 1) * 2 + Room::MIN_WIDTH
		end

		def random_height
			Random.rand(((Room::MAX_HEIGHT - Room::MIN_HEIGHT) / 2) + 1) * 2 + Room::MIN_HEIGHT
		end

		def max_row
			(rows - 2).odd? ? rows - 2 : rows - 3
		end

		def max_column
			(columns - 2).odd? ? columns - 2 : columns - 3
		end

		def create_map(min_rooms)
			# wipe the map in case this isn't the first go-round
			@rooms = []
			@corridors = []
			@tiles = []

			@map_attempts += 1

			# start by adding a room
			add_room

			# this will need revising -- we don't necessarily want to stop at minrooms
			i = 0
			until (room_area / (rows * columns).to_f) > ROOM_RATIO do
				i += 1
				return create_map(min_rooms) if i > 500

				# pick a room at random, try a new one if that one's joins are all used up
				room = nil
				until room
					room = @rooms.sample.with_joins
				end

				# try drawing a corridor -- rinse and repeat if it's looped
				join = room.add_join
				start_x, start_y, direction = join.x, join.y, join.direction
					
				new_corridor = Corridor.new(start_x, start_y, direction, self) rescue nil

				if new_corridor && new_corridor.looped && (Random.rand < LOOP_RATIO) && !room.loopy
					room.loopy = true
					@corridors.push(new_corridor)
				end
				new_corridor = nil if new_corridor && new_corridor.looped

				# 50% of the time draw another corridor at the end of that -- toss this one if its looped
				# we now have a guaranteed corridor with an endpoint, possibly with some looped ones as well

				# try add_room_from_edge
				# if false, kill the new corridor
				new_corridor = nil if new_corridor && !add_room_from_edge(new_corridor.end_x, new_corridor.end_y, new_corridor.direction)

				# did it work? then let's go!
				if new_corridor
					@corridors.push(new_corridor)
				else
					room.pop_join
				end
			end

			# next, add a join and draw a corridor in the appropriate direction.
			# 	if that fails, kill the corridor and join, go back to the room, and try again.
			# 	the end of the corridor should be either a room or another corridor in another direction.
			# stop (but retain the corridor) if it intersects with another corridor or room.
			# 	in that case, go back to the last room and make a new join and corridor.
			# 	this sets the @looped property on the corridor -- if we have a looped corridor,
			# 	choose a random existing room and try again.
			# if not, eventually you'll end up making another room.
			# continue this way at least until you hit min_rooms.
			# but keep drawing rooms.
			# keep a fail counter, and if you at creating a new room, say, 10 times in a row, then stop.
			# if this happens before min_rooms threshold, scrap the whole fucking thing and start over.

			# make some tiles -- iterate over rows, then each value within each row
			rows.times do |y|
				columns.times do |x|
					if x == 0 || x == columns - 1 || y == 0 || y == rows - 1
						type = :hard_rock
					else
						type = case tile_type(x, y)
							when true
								:dirt
							when 1
								:obsidian
							when 2
								:moss
							when false
								:soft_rock
						end
					end
					@tiles.push(Tile.new(self, x, y, type))
				end
			end

			# populate the map with critters, toys, and staircases

			# trigger event
			Event.new("create-complete", self)
		end

		def add_room(coordinates = {})
			# specify four coordinates to mark the upper-left and lower-right corners of the room.
			# or we'll just choose our own damn selves!

			if coordinates.key?(:x1) && coordinates.key?(:y1) && coordinates.key?(:x2) && coordinates.key?(:y2)
				x1, y1, x2, y2 = coordinates.keys(:x1, :y1, :x2, :y2)

				return false if overlaps_room?(x1, y1, x2, y2)
			else
				x1 = random_column
				y1 = random_row

				x2 = x1 + random_width - 1
				y2 = y1 + random_height - 1

				if x2 > max_column
					x1 -= (x2 - max_column)
					x2 = max_column
				end

				if y2 > max_row
					y1 -= (y2 - max_row)
					y2 = max_row
				end

				return add_room if !area_empty?(x1, y1, x2, y2)
			end

			room = Room.new(x1, y1, x2, y2, self)
			@rooms.push(room)

			room
		end

		def add_room_from_edge(x, y, direction)
			# TODO: This needs to avoid making rooms adjacent to non-rock spaces excluding the edge passed to it

			# if this returns false, you most likely need to pick a new starting point,
			# not just try running it again.
			# this is not always true, but it's true often enough that it'll be faster to
			# scrap it and try something else

			return false if x <= 1 || y <= 1 || x > max_column || y > max_row

			# check to ensure enough room is available, according to the direction
			# note that it's a bit dumb about verifying sufficient clear area -- i.e.
			# it errs on the side of giving up. this should be fine, but it may be worth
			# revising at some point
			if direction == 0
				return false if x > max_column - Room::MIN_WIDTH
				return false unless area_empty?(x + 1, y - 2, x + 4, y + 2)
				max_width = max_column - x
			elsif direction == 1
				return false if y < Room::MIN_HEIGHT + 1
				return false unless area_empty?(x - 2, y - 4, x + 2, y - 1)
				max_height = y - 1
			elsif direction == 2
				return false if x < Room::MIN_WIDTH + 1
				return false unless area_empty?(x - 4, y - 2, x - 1, y + 2)
				max_width = x - 1
			elsif direction == 3
				return false if y > max_row - Room::MIN_HEIGHT
				return false unless area_empty?(x - 2, y + 4, x + 2, y + 1)
				max_height = max_row - y
			end

			# try several times to make a room before giving up
			5.times do |iteration|
				if direction.odd? # up-and-down style room
					width = random_width
					height = odd_from_range(Room::MIN_HEIGHT .. [max_height, Room::MAX_HEIGHT].min)

					x1_min = [x - width + 1, 1].max
					x1 = odd_from_range(x1_min .. x)
					x2 = x1 + width - 1

					# try moving it if it's too far to the right
					if x2 > max_column
						x2 = max_column
						x1 = x2 - width + 1
					end

					if direction == 1
						y2 = y - 1
						y1 = y2 - height + 1
					else
						y1 = y + 1
						y2 = y1 + height - 1
					end
				else # left-and-right style room
					width = odd_from_range(Room::MIN_WIDTH .. [max_width, Room::MAX_WIDTH].min)
					height = random_height

					y1_min = [y - height + 1, 1].max
					y1 = odd_from_range(y1_min .. y)
					y2 = y1 + height - 1

					# try moving it if it's too far down
					if y2 > max_row
						y2 = max_row
						y1 = y2 - height + 1
					end

					if direction == 0
						x1 = x + 1
						x2 = x1 + width - 1
					else
						x2 = x - 1
						x1 = x2 - width + 1
					end
				end

				if area_empty?(x1 - 1, y1 - 1, x2 + 1, y2 + 1, except: [[x, y]])
					room = Room.new(x1, y1, x2, y2, self)
					@rooms.push(room)
					return room
				end
			end

			# couldn't make a room! sad!
			false
		end

		def tile_type(x, y)
			# decided to check corridors first, to make it more obvious if they erroneously overlap things
			corridors.each { |corridor| return true if corridor.contains?(x, y) }

			# look through @rooms, ensure square is not in any of them
			rooms.each{ |room| return room.contains?(x, y) if room.contains?(x, y) }

			false
		end
	end
end
