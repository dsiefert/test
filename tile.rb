module Roguelike
	class Tile < Point
		attr_reader :type, :color, :character, :transit_time

		# will need some sort of list of tile types, e.g.
		# 	dirt (character: ., color: 'grey', transit-time: 1)
		#   grass (character: ", color: 'green', transit-time: 1)
		# 	rock (character: #, color: 'grey', transit-time: nil -- impassible)
		#   rubble (character: *, color: 'grey', transit-time: 3)

		@@tile_types = {
			soft_rock: {character: '#', color: 9, transit_time: nil},
			hard_rock: {character: '#', color: 9, transit_time: nil},
			dirt:      {character: '.', color: 8, transit_time: 1},
			grass:     {character: '"', color: 3, transit_time: 1},
			moss:      {character: '.', color: 3, transit_time: 1},
			obsidian:  {character: '.', color: 9, transit_time: 1}
		}
		@@tile_types.freeze

		def initialize(map, x, y, type)
			super(map, x, y)

			raise Error, "Unknown tile type: #{type}" if @@tile_types[type].nil?

			@type         = type
			@color        = @@tile_types[type][:color]
			@character    = @@tile_types[type][:character]
			@transit_time = @@tile_types[type][:transit_time]
		end
	end
end
