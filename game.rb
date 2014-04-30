require_relative 'dungeon'
require_relative 'event'
require_relative 'dispatcher'
require_relative 'player'

module Roguelike
	module Game
		module_function

		class << self
			attr_accessor :dungeon_level, :player
		end

		def start
			titles = [
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
				"A vast network of claustrophobic tunnels"
			]

			dungeon_level = Roguelike::DungeonLevel.new(titles.sample)
			Game.dungeon_level = dungeon_level
			coord_x, coord_y = dungeon_level.random_walkable_square
			Game.player = Player.new(dungeon_level, coord_x, coord_y)
			dungeon_level.draw

			take_turn
		end

		def take_turn
			Dispatcher.handle($window.getch) unless Game.over?
		end

		def over?
			@over
		end

		def over
			@over = true
		end

		def player=(player)
			@player = player unless @player
		end
	end
end
