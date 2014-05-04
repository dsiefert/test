module Roguelike
	class Player < Point
		include EventCapable
		
		def sight_radius
			6
		end

		def initialize(*args)
			super(*args)

			@character = "@"
			@color = 16
		end

		# we got the moves
		# TODO: move this into a separate module because there's gonna be a lot of them

		def move(x_direction, y_direction)
			return true if x_direction == 0 && y_direction == 0

			Event.new("leave", self)

			new_x = @x + x_direction
			new_y = @y + y_direction

			if new_x < 0 || new_y < 0 || new_x > @map.columns - 1 || new_y > @map.rows - 1
				Dispatcher.queue_message("Ouch, you bumped into the edge of the universe!")
				return false
			end

			if !Game.dungeon_level.walkable?(new_x, new_y)
				Dispatcher.queue_message("Ouch, you bumped into something!")
				return false
			end

			@x = new_x
			@y = new_y

			Event.new("move", self)
		end

		def teleport(x = nil, y = nil)
			if x.nil?
				x, y = Game.dungeon_level.random_walkable_square
			elsif y.nil?
				x, y = x
			end

			return teleport unless Game.dungeon_level.walkable_except_player?(x, y)

			@x, @y = x, y
			Dispatcher.queue_message("You teleport!")

			Event.new("move", self)
			Event.new("teleport", self)
		end

		def controlled_teleport
			x, y = Dispatcher.select_square
			unless Game.dungeon_level.walkable_except_player?(x, y)
				Dispatcher.queue_message("Controlled teleportation fail!")
				x, y = Game.dungeon_level.random_walkable_square
			end

			teleport(x, y)
		end
	end
end
