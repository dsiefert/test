module Roguelike
	module FOV
	private
		def traverse_line(x, y)
			points = line(Game.player.x, Game.player.y, x, y)
			points.each do |point|
				s = square(point)

				x_sq = (s.x - Game.player.x)**2
				y_sq = (s.y - Game.player.y)**2
				return if x_sq + y_sq > @rad_sq

				s.light

				return if s.opaque? && [s.x, s.y] != [Game.player.x, Game.player.y]
			end
		end

		def line(x0, y0, x1, y1)
			steep = ((y1 - y0).abs) > ((x1 - x0).abs)
			x0, y0, x1, y1 = y0, x0, y1, x1 if steep

			if x0 > x1
				x0, x1, y0, y1 = x1, x0, y1, y0
				reversed = true
			else
				reversed = false
			end

			delta_x = x1 - x0
			delta_y = (y1 - y0).abs
			error = delta_x / 2
			y_step = ((y0 < y1) ? 1 : -1)

			y = y0
			points = []
			(x0 .. x1).each do |x|
				points << (steep ? [y, x] : [x, y])

				error -= delta_y
				if error < 0
					y += y_step
					error += delta_x
				end
			end

			reversed ? points.reverse : points
		end

		def calculate_fov
			@rad_sq = Game.player.sight_radius**2

			# maybe make this more efficient by only storing the visibles somewhere in Tile?
			columns.times do |x|
				rows.times do |y|
					square(x, y).reinitialize_fov
				end
			end

			x_min = Game.player.x - Game.player.sight_radius
			x_max = Game.player.x + Game.player.sight_radius
			y_min = Game.player.y - Game.player.sight_radius
			y_max = Game.player.y + Game.player.sight_radius

			# scan top and bottom edges
			[y_min, y_max].each do |y|
				(x_min .. x_max).each do |x|
					traverse_line(x, y)
				end
			end

			# scan left and right edges
			[x_min, x_max].each do |x|
				(y_min .. y_max).each do |y|
					traverse_line(x, y)
				end
			end
		end
	end
end
