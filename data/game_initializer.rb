module Roguelike
	class GameInitializer
		class << self
			def level
				place = Place.new(title: "A shadowy glen")
				design = Roguelike::DungeonLevel.design do |l|
					l.background(:grass)
					l.random(:tree, 0.1)
					l.random(:earth, 0.1)
				end

				place.initial_level = Roguelike::DungeonLevel.new(place, "A shadowy glen", design)

				place.initial_level.add_movable(Items::Staircase.new(25, 11, :down, destination: Roguelike::Place.new))
				place.initial_level.add_movable(Items::Staircase.new(52, 11, :down, destination: Roguelike::Place.new))

				place.initial_level.add_movable(Items::Item.new(*place.initial_level.random_square(:empty?), "diamond", "^", 5, takeable: true, fancy_name: "A sparkling blue diamond", category: "Jewels"))
					.listen_for(:tread, Roguelike::Player) do
						Dispatcher.queue_message("You see a sparkling diamond.")
					end
					.listen_for(:use, Roguelike::Player) do
						Dispatcher.queue_message("You kiss the diamond, and it whispers something. \"#{::Roguelike::FORTUNES.sample}\"")
					end

				place.initial_level.add_movable(Items::Item.new(*place.initial_level.random_square(:empty?), "chattering stone", "*", 2, takeable: true, fancy_name: "The strange chattering pebble"))
					.listen_for(:tread, Roguelike::Player) do
						Dispatcher.queue_message("You see a strange, vibrating stone emitting a soft chattering noise.")
					end
					.listen_for(:use, Roguelike::Player) do
						Dispatcher.queue_message("You hold the chattering stone to your ear to listen. \"There are wondiferous, splendissimous, magiculous things to see in these caves. I shall tell you in my voice so mellifluous of all the ridiculously charming and disarming and occasionally alarming delights that await you below. First there are the elves, reluctant to descend. They may seem like they're gentle, but only to their friends. They certainly are lovely, with skin and hair so fair. They quickly can turn deadly, when their arrows fill the air.\"")
					end

				place.initial_level.add_movable(Items::Item.new(*place.initial_level.random_square(:empty?), "blue potion", "!", 5, takeable: true, fancy_name: "The blue potion", category: "Potions"))
				place.initial_level.add_movable(Items::Item.new(*place.initial_level.random_square(:empty?), "yellow potion", "!", 12, takeable: true, fancy_name: "The yellow potion", category: "Potions"))

				place.initial_level
			end

			def starting_coordinates
				[38, 11]
			end
		end
	end
end
