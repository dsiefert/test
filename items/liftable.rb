module Roguelike
	module Items
		class Liftable < Item
			def initialize(x, y)
				super(x, y)

				@takeable = true
				@walkable = true
			end
		end
	end
end
