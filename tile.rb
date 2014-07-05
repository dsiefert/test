module Roguelike
	class Tile < Point
		attr_reader :type, :color, :character, :transit_time

		# will need some sort of list of tile types, e.g.
		# 	dirt (character: ., color: 'grey', transit-time: 1)
		#   grass (character: ", color: 'green', transit-time: 1)
		# 	rock (character: #, color: 'grey', transit-time: nil -- impassible)
		#   rubble (character: *, color: 'grey', transit-time: 3)

		@@tile_types = {
			soft_rock: {character: '#', color: 9, transit_time: nil, opaque: true},
			hard_rock: {character: '#', color: 9, transit_time: nil, opaque: true},
			dirt:      {character: '.', color: 8, transit_time: 1, opaque: false},
			grass:     {character: '"', color: 3, transit_time: 1, opaque: false},
			moss:      {character: '.', color: 3, transit_time: 1, opaque: false},
			tree:      {character: 'T', color: 11, transit_time: 1.25, opaque: false},
			obsidian:  {character: '.', color: 9, transit_time: 1, opaque: false},
			rubble:    {character: '*', color: 9, transit_time: 5, opaque: false}
		}
		@@tile_types.freeze

		def initialize(x, y, type)
			super(x, y)

			raise Error, "Unknown tile type: #{type}" if !type.is_a?(Integer) && @@tile_types[type].nil?

			type = @@tile_types.to_a[type][0] if type.is_a?(Integer)

			@type         = type
			@color        = @@tile_types[type][:color]
			@character    = @@tile_types[type][:character]
			@transit_time = @@tile_types[type][:transit_time]
			@opaque       = @@tile_types[type][:opaque]
			@visible      = false
			@remembered   = false
		end

		def opaque?
			@opaque
		end

		def remembered?
			@remembered
		end

		def visible?
			@visible
		end

		def light
			@visible    = true
			@remembered = true
		end

		def reveal
			return light if transit_time

			(-1 .. 1).each do |x|
				(-1 .. 1).each do |y|
					return light if Game.level.square(@x + x, @y + y).transit_time
				end
			end
		end

		def forget
			@remembered = false
		end

		def reinitialize_fov
			@visible = false
		end
	end

	class FakeTile < Point
		@@fake_tile = nil
		attr_writer :x, :y

		def self.instance(x, y)
			@@fake_tile = new(x, y) unless @@fake_tile
			@@fake_tile.x, @@fake_tile.y = [x, y]

			@@fake_tile
		end

		def light; end
		def reveal; end
		def draw; end
		def reinitialize_fov; end

		def visible?
			false
		end

		def remembered?
			false
		end

		def opaque?
			true
		end

		def transit_time
			nil
		end
	end
end
