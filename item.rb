module Roguelike
	class Item < Point
		attr_reader :name
		attr_accessor :color

		def initialize(map, x, y, name, character, color) #will later add type or something
			super(map, x, y)

			@name, @character, @color = name, character, color

			set_tread { Dispatcher.queue_message("You stepped on a #{@name}") }
		end

		def set_tread(&block)
			@tread = block
			Event.listen("move", self, :tread, Game.player) { Game.player.location == location }
		end

		def tread(target)
			@tread.call(target)
		end
	end
end
