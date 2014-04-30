module Roguelike
	class Item < Point
		def initialize(map, x, y) #will later add type or something
			super(map, x, y)
		end
	end
end
