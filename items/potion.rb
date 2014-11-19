module Roguelike
	module Items
		class Potion < Liftable
			def initialize(x, y)
				super(x, y)

				@category  = "Potions"
				@character = "!"

				listen_for(:use, Roguelike::Player) do
					Dispatcher.queue_message("Perhaps you might try drinking the potion?")
				end
			end
		end

		class PotionOfInvulnerability < Potion
			def initialize(x, y)
				super(x, y)

				@name       = "yellow potion"
				@fancy_name = "Potion of Invulnerability"
				@color      = 12

				listen_for(:drink, Roguelike::Player) do |me|
					Dispatcher.queue_message("The potion is evervescent and restorative!")
					die
				end
			end
		end

		class PotionOfCourage < Potion
			def initialize(x, y)
				super(x, y)

				@name       = "pink potion"
				@fancy_name = "Potion of Courage"
				@color      = 10

				listen_for(:drink, Roguelike::Player) do |me|
					Dispatcher.queue_message("The potion is bubbly and delicious!")
					die
				end
			end
		end

		class PotionOfPrattle < Potion
			def initialize(x, y)
				super(x, y)

				@name       = "silver potion"
				@fancy_name = "Potion of Prattle"
				@color      = 16

				listen_for(:drink, Roguelike::Player) do |me|
					Dispatcher.queue_message("The potion is sparkly and makes you want to talk!")
					die
				end
			end
		end
	end
end
