module Roguelike
	class Player < Point
		include ::Roguelike::Event::Capable

		def sight_radius
			6
		end

		def initialize
			@character = "@"
			@color = 16
		end

		def set_location(x, y = nil)
			x, y = x unless y

			@x, @y = x, y
			Event::Event.new(:tread, self, local: [x, y])
		end

		# we got the moves
		# TODO: move this into a separate module because there's gonna be a lot of them

		def move(x_direction, y_direction)
			return true if x_direction == 0 && y_direction == 0

			Event::Event.new("leave", self)

			new_x = @x + x_direction
			new_y = @y + y_direction

			if new_x < 0 || new_y < 0 || new_x > Game.level.columns - 1 || new_y > Game.level.rows - 1
				Dispatcher.queue_message("Ouch, you bumped into the edge of the universe!")
				return false
			end

			if !Game.level.walkable?(new_x, new_y)
				Dispatcher.queue_message("Ouch, you bumped into a wall!") if Game.level.square(new_x, new_y).transit_time.nil?
				Event::Event.new(:bump, self, local: [new_x, new_y])
				return false
			end

			@x = new_x
			@y = new_y

			Event::Event.new(:tread, self, local: [x, y])
			Event::Event.new(:move, self)
		end

		def teleport(x = nil, y = nil)
			if x.nil?
				x, y = Game.level.random_square(:walkable?)
			elsif y.nil?
				x, y = x
			end

			return teleport unless Game.level.walkable_except_player?(x, y)

			@x, @y = x, y
			Dispatcher.queue_message("You teleport!")

			Event::Event.new(:tread, self, local: [x, y])
			Event::Event.new(:teleport, self)
		end

		def controlled_teleport
			x, y = Dispatcher.select_square
			unless Game.level.walkable_except_player?(x, y)
				Dispatcher.queue_message("Controlled teleportation fail!")
				x, y = Game.level.random_square(:walkable?)
			end

			teleport(x, y)
		end

		def sneeze
			Dispatcher.queue_message("You sneeze.")
			Event::Event.new(:sneeze, self)
		end

		def hug(direction)
			delta_x, delta_y = direction
			if Event::Event.new(:hug, self, local: [x + delta_x, y + delta_y]).unheard?
				if direction == [0, 0]
					Dispatcher.queue_message("You pathetically attempt to hug yourself.")
				elsif Game.level.movables(x + delta_x, y + delta_y).empty?
					Dispatcher.queue_message("There is nothing there to hug!")
				end
			end
		end

		def descend
			if Event::Event.new(:descend, self, local: [x, y]).unheard?
				Dispatcher.queue_message("You attempt to descend but there is nothing to descend.")
			else
				Event::Event.new(:leave, self)
			end
		end

		def ascend
			if Event::Event.new(:ascend, self, local: [x, y]).unheard?
				Dispatcher.queue_message("What do you expect to climb, exactly?")
			else
				Event::Event.new(:leave, self)
			end
		end
	end
end
