module Roguelike
	module Items
		class Staircase < Item
			attr_reader :direction, :destination

			def initialize(map, x, y, direction, options = {})
				char = direction == :up ? '<' : '>'
				super(map, x, y, "staircase", char, 8, options.merge(direction: direction))

				listen_for(:tread, Game.player) do
					Dispatcher.queue_message(direction == :up ? "A staircase bringing you tantalizingly closer to the light." : "A staircase leading even deeper into the bowels of the earth.")
				end

				listen_for(:descend, Game.player) { climb } if direction == :down
				listen_for(:ascend, Game.player) { climb } if direction == :up
			end

			def climb
				Dispatcher.queue_message("You climb the stairs . . .", true)
				Game.level.draw

				if !@destination
					map = Roguelike::DungeonLevel.new(Game.level.place)
					map.depth = Game.level.depth + 1 if direction == :down
					@destination = Roguelike::Items::Staircase.new(map, *map.unmarked_rooms.sample.mark.random_square, (direction == :down ? :up : :down), destination: self)
				end

				Game.level = @destination.map
				Game.player.set_location(@destination.map, @destination.x, @destination.y)

				Event::Event.new(:enter, Game.player)
			end
		end
	end
end
