module Roguelike
	class Item < Point
		def initialize(map, x, y, name, character, color) #will later add type or something
			super(map, x, y)

			@name, @character, @color = name, character, color
		end

		def set_tread(&block)
			@tread = block
			Event.listen("move", self)
		end

		def move(caller)
			@tread.call(caller) if @tread && x == Game.player.x && y == Game.player.y
		end
	end
end
