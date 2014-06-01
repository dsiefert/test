require_relative 'event/event'
require_relative 'place'
require_relative 'dispatcher'
require_relative 'player'

module Roguelike
	module Game
		module_function

		class << self
			attr_accessor :dungeon_level, :player
		end

		def start
			Game.player = Player.new
			dungeon_level = Roguelike::DungeonLevel.new(Place.new)
			dungeon_level.depth = 1
			Game.dungeon_level = dungeon_level
			Game.player.set_location(dungeon_level, dungeon_level.unmarked_rooms.sample.mark.random_square)
			dungeon_level.draw
			Event::Event.new(:enter, Game.player)
		end

		def take_turn
			::Roguelike::Event::Event.new(:turn, self)
			Game.dungeon_level.draw
			Dispatcher.handle($window.getch)
		end

		def over?
			@over
		end

		def over!(message = nil)
			@over = true

			dungeon_level.draw(false)

			message ||= "Game over. Waah waah waah."

			Dispatcher.queue_message(message, true)
		end

		def player=(player)
			@player = player unless @player
		end

		def end_message
			@end_message
		end
	end
end
