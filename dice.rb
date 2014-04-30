module Roguelike
	class Dice
		def self.roll(dice_string, threshold = nil)
			# return either the numerical value of roll calculated according to the dice_string,
			# or a true or false if a threshold is specified
			#
			# always assume higher is better, so that the influence of luck can be pervasive in
			# the game (i.e. it always gives you higher rolls)
		end

		def self.new
			raise Error, "This class cannot be instantiated"
		end
	end
end
