module Roguelike
	class Player < Point
		def move(x_direction, y_direction)
			new_x = @x + x_direction
			new_y = @y + y_direction

			if new_x < 0 || new_y < 0 || new_x > @map.columns - 1 || new_y > @map.rows - 1
				Dispatcher.queue_message("Ouch, you bumped into the edge of the universe!")
				return false
			end

			@x = new_x
			@y = new_y
		end

		def initialize(*args)
			super(*args)

			@character = "@"
			@color = 16
		end
	end
end
