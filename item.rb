module Roguelike
	class Item < Point
		include EventCapable

		attr_reader :name
		attr_accessor :color

		def initialize(map, x, y, name, character, color) #will later add type or something
			super(map, x, y)

			@name, @character, @color = name, character, color

			map.add_movable(self)

			listen_for(:tread, Game.player) { Dispatcher.queue_message("You step on a #{name}!") }

			self
		end

		def walkable?
			true
		end

		def remove
			@map.remove_movable(self)
		end
	end
end
