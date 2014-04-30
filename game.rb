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
