module Roguelike
	class Monster < Point
		include EventCapable
		
		attr_reader :name
		attr_accessor :color

		def initialize(map, x, y, name, character, color) #will later add type or something
			super(map, x, y)

			@name, @character, @color = name, character, color

			map.add_movable(self)
		end

		def set_turn(&block)
			@turn = block
			Event.listen("turn", self)
		end

		def turn(target)
			# TODO: some of that good ol' Ruby metaprogramming magic would make defining events easier
			@turn.call(target)
		end

		def walkable?
			false
		end

		def move(x = nil, y = nil)
			# TODO: monsters and players both need a way to select a random walkable direction
			# if one exists

			if x.nil?
				x = [-1, 1].sample
				y = [-1, 1].sample
			end
			x, y = x if y.nil?

			if @map.walkable?(@x + x, @y + y)
				@x += x
				@y += y
			end
		end
	end
end
