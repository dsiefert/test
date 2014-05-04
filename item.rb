module Roguelike
	class Item < Point
		include EventCapable

		attr_reader :name
		attr_accessor :color

		def initialize(map, x, y, name, character, color) #will later add type or something
			super(map, x, y)

			@name, @character, @color = name, character, color

			map.add_movable(self)

			set_tread { Dispatcher.queue_message("You step on a #{@name}") }
		end

		def set_tread(&block)
			@tread = block
			Event.listen("move", self, :tread, Game.player) { Game.player.location == location }
		end

		def tread(target)
			# TODO: some of that good ol' Ruby metaprogramming magic would make defining events easier
			@tread.call(target)
		end

		def walkable?
			true
		end
	end
end
