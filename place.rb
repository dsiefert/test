require_relative 'dungeon_level'
require_relative 'dungeon_components'

module Roguelike
	class Place
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

		attr_reader :title

		def initialize(options = {})
			@title         = options.delete(:title) || TITLES.sample
			@initial_level = options.delete(:initial_level)
		end

		def initial_level
			@initial_level ||= Roguelike::DungeonLevel.new(self)
		end
	end
end
