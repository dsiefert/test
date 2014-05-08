require_relative 'event'
require_relative 'event_capable'
require_relative 'dungeon'
require_relative 'dispatcher'
require_relative 'player'

module Roguelike
	TITLES = [
		"A dark and gloomy snide field",
		"A mysterious dungeon",
		"Some caves or something",
		"A dark place",
		"A maze of twisty little passages, all alike",
		"Wait, what?",
		"Somewhere deep below the ground",
		"The lair of some foul creature",
		"An abandoned dwarven settlement",
		"Somewhere that smells bad",
		"A vast network of claustrophobic tunnels",
		"The tomb of something you'd rather not imagine",
		"An undisclosed location"
	]

	module Game
		module_function

		class << self
			attr_accessor :dungeon_level, :player
		end

		def start
			Game.player = Player.new
			dungeon_level = Roguelike::DungeonLevel.new(::Roguelike::TITLES.sample)
			dungeon_level.depth = 1
			Game.dungeon_level = dungeon_level
			Game.player.set_location(dungeon_level, dungeon_level.random_square(:empty?))
			dungeon_level.draw
		end

		def take_turn
			Event.new(:turn, self)
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
