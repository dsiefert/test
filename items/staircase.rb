module Roguelike
	module Items
		class Staircase < Item
			attr_reader :direction, :destination

			def initialize(x, y, direction, options = {})
				char = direction == :up ? '<' : '>'
				super(x, y, "staircase", char, 8, options.merge(direction: direction))

				listen_for(:tread, Game.player) do
					Dispatcher.queue_message(direction == :up ? "A staircase leading up." : "A staircase leading down.")
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
					@destination_map = map
					@destination = Roguelike::Items::Staircase.new(*map.unmarked_rooms.sample.mark.random_square, (direction == :down ? :up : :down), destination: self, destination_map: Game.level)
					@destination_map.add_movable(@destination)
				end

				if @destination.is_a?(Roguelike::Place)
					map = Roguelike::DungeonLevel.new(@destination)
					@destination_map = map
					@destination = Roguelike::Items::Staircase.new(*map.unmarked_rooms.sample.mark.random_square, (direction == :down ? :up : :down), destination: self, destination_map: Game.level)
					@destination_map.add_movable(@destination)
				end

				Game.level = @destination_map
				Game.player.set_location(@destination.x, @destination.y)

				Event::Event.new(:enter, Game.player)
			end
		end
	end
end
