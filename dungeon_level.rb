require 'ncurses'

require_relative 'point'
require_relative 'tile'
require_relative 'monster'
require_relative 'fov'
require_relative 'test_items'

module Roguelike
	class DungeonLevel
		include FOV
		include Event::Capable
		include Roguelike::TestItems

		ROOM_RATIO_HIGH = 0.30
		ROOM_RATIO_LOW  = 0.20
		LOOP_RATIO      = 0.10
		ROOM_ATTEMPTS   = 500
		COLUMNS         = 78
		ROWS            = 23

		attr_reader :columns, :rows, :rooms, :corridors, :offset_y, :offset_x, :map_attempts, :up_square, :place
		attr_writer :depth
		attr_accessor :unmarked_rooms

		def self.design(&block)
			Roguelike::Design.new(block)
		end

		def initialize(place, title = nil, map = nil, options = {})
			Event::Event.new(:initialize, self)

			map = map.draw if map && map.is_a?(Roguelike::Design)

			@place          = place
			@columns        = COLUMNS
			@rows           = ROWS
			@custom_map     = map
			@title          = title
			@rooms          = []
			@unmarked_rooms = []
			@corridors      = []
			@movables       = []
			@map_attempts   = 0

			@tiles = []
			@columns.times do |x|
				@tiles[x] = []
				@rows.times do |y|
					@tiles[x][y] = nil
				end
			end

			@offset_x = ((80 - @columns) / 2).floor
			@offset_y = ((25 - @rows) / 2).floor

			if !@custom_map
				Event::Event.new(:create_start, self)
				create_map
			else
				create_tiles
			end

			unless @custom_map
				listen_for(:enter, Roguelike::Player) do |me|
					me.ignore(:enter)
					Dispatcher.queue_message('These caves seem endless.')
				end
			end

			self
		end

		def draw(display_messages = true)
			calculate_fov

			# clear what's there
			rows.times do |row|
				$window.move(row + offset_x, 0)
				$window.clrtoeol
			end

			# actually draw it onscreen
			# on every point on the map:
			# 	draw tile if visible
			# every item (inc monsters inc PC)
			# 	draw item if item is on a visible point and is visible
			@tiles.each do |col|
				col.each { |tile| tile.draw if tile.visible? || tile.remembered? }
			end

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
			$window.mvaddstr(@offset_y - 1, 3, " #{title.slice(0, 72)} ")
			$window.mvaddstr(@offset_y - 1, @offset_x + @columns - 2 - depth.to_s.length, " #{depth} ")

			#items!
			@movables.each do |movable|
				# TODO: Ensure monsters always draw after items
				if square(movable.x, movable.y).visible? || (movable.is_a?(Items::Item) && square(movable.x, movable.y).remembered?)
					Event::Event.new(:see, Game.player, target: movable) if square(movable.x, movable.y).visible?
					movable.draw unless movable.invisible
				end
			end

			Game.player.draw

			Dispatcher.display_messages if display_messages

			# set the cursor to the player's current position
			$window.move(Game.player.y + offset_y, Game.player.x + offset_x)

			# all done!
			$window.refresh
			Event::Event.new(:draw_complete, self)
		end

		def depth
			@depth ||= 1
		end

		def map
			self
		end

		def title
			@title || @place.title
		end

		def unoccupied?(x, y)
			tile_type(x, y) == false
		end

		def walkable?(x, y = nil)
			return false if x.nil?
			x, y = x unless y

			return false if Game.player && x == Game.player.x && y == Game.player.y

			walkable_except_player?(x, y)
		end

		def empty?(x, y = nil)
			return false if x.nil?
			x, y = x unless y

			walkable?(x, y) && movables(x, y).empty?
		end

		def unfilled?(x, y = nil)
			return false if x.nil?
			x, y = x unless y

			walkable?(x, y) && movables(x, y).reject{ |m| !m.walkable? }.empty?
		end

		def walkable_except_player?(x, y = nil)
			return false if x.nil?
			x, y = x if y.nil?

			@movables.each do |movable|
				next if movable.walkable?
				return false if movable.x == x && movable.y == y
			end

			!square(x, y).transit_time.nil?
		end

		def random_square(*options)
			x = Random.rand(0 .. columns - 1)
			y = Random.rand(0 .. rows - 1)

			options.each do |opt|
				return random_square(*options) unless send(opt, x, y)
			end

			[x, y]
		end

		def movables(x = nil, y = nil)
			return @movables unless x
			x, y = x unless y

			@movables.select{ |m| m.x == x && m.y == y }
		end

		def square(x, y = nil)
			x, y = x unless y

			# return something that resembles a tile if given out-of-bounds values, for FOV calculation
			return FakeTile.instance(x, y) unless (0 .. (columns - 1)).include?(x) && (0 .. (rows - 1)).include?(y)

			@tiles[x][y]
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

		def add_movable(movable)
			@movables << movable
			movable
		end

		def remove_movable(movable)
			@movables -= [movable]
		end

		def reveal
			columns.times do |x|
				rows.times do |y|
					square(x, y).reveal
				end
			end
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

		def create_map
			# wipe the map in case this isn't the first go-round
			@rooms          = []
			@unmarked_rooms = []
			@corridors      = []
			@tiles          = []
			@movables       = []

			@columns.times do |x|
				@tiles[x] = []
				@rows.times do |y|
					@tiles[x][y] = nil
				end
			end

			room_ratio = Random.rand(ROOM_RATIO_LOW .. ROOM_RATIO_HIGH)

			@map_attempts += 1

			# start by adding a room
			add_room

			ROOM_ATTEMPTS.times do
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

				if (room_area / (rows * columns).to_f) > room_ratio
					create_tiles

					break
				end
			end

			# if even after ROOM_ATTEMPTS tries, we still don't have enough room area . . .
			return create_map if (room_area / (rows * columns).to_f) < room_ratio

			populate_map

			# trigger event
			return Event::Event.new(:create_complete, self)
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
			@unmarked_rooms.push(room)

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

				if area_empty?(x1, y1, x2, y2)
					room = Room.new(x1, y1, x2, y2, self)
					@rooms.push(room)
					@unmarked_rooms.push(room)
					return room
				end
			end

			# couldn't make a room! sad!
			false
		end

		def create_tiles
			if !@custom_map
				rows.times do |y|
					columns.times do |x|
						if x == 0 || x == columns - 1 || y == 0 || y == rows - 1
							type = :hard_rock
						else
							type =
								case tile_type(x, y)
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
						@tiles[x][y] = Tile.new(x, y, type)
					end
				end
			else
				rows.times do |y|
					columns.times do |x|
						@tiles[x][y] = Tile.new(x, y, @custom_map[x][y])
					end
				end
			end
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
