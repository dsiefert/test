module Roguelike
	module TestItems
		def populate_map
			add_movable(Items::Staircase.new(*@unmarked_rooms.sample.mark.random_square, :down))

			room = @unmarked_rooms.sample.mark
			(room.x1 .. room.x2).each do |x|
				(room.y1 .. room.y2).each do |y|
					add_movable(Items::Item.new(x, y, "land mine", "^", 10, invisible: true))
						.listen_for(:tread) do |me|
							me.invisible = false
							Dispatcher.queue_message("You hear a thundering explosion!")
							Event::Event.new(:explode, me, local: [me.x, me.y])
							me.listen_for(:tread, Roguelike::Player) { Dispatcher.queue_message("You step on an exploded land mine.") }
						end
				end
			end

			add_movable(Items::Item.new(*random_square(:empty?), "ampersand", "&", 12))
				.listen_for(:tread, Roguelike::Player) do |me|
					Dispatcher.queue_message("You step on an ampersand, squishing it flat!")
					me.remove
				end
				.listen_for(:see, Roguelike::Player) do |me|
					me.ignore(:see)
					Dispatcher.queue_message("You spy the rarest and most wondrous item: an ampersand, gleaming on the cave floor!", true)
				end

			add_movable(Items::Item.new(*random_square(:empty?), "big red dildo", "/", 2))
				.listen_for(:tread, Roguelike::Player) do |me|
					Dispatcher.queue_message("The big red dildo squeaks hopefully.")
					me.listen_for(:sneeze, Roguelike::Player) { Dispatcher.queue_message("The big red dildo shouts, \"Bless you!\"") }
					me.listen_for(:tread, Roguelike::Player) do
						Dispatcher.queue_message("The big red dildo squeals sadly.")
						me.ignore(:tread)
						me.ignore(:sneeze)
					end
				end
				.listen_for(:hug, Roguelike::Player) do |me|
					Dispatcher.queue_message("You hug the big red dildo, and it purrs happily.")
					me.ignore(:tread)
					me.listen_for(:sneeze, Roguelike::Player) do |me|
						if me.visible?
							Dispatcher.queue_message("The big red dildo shouts, \"I LOVE YOU!\"")
						else
							Dispatcher.queue_message("You hear a distant shout. Was that the big red dildo?")
						end
					end
				end
				.listen_for(:descend, Roguelike::Player) do
					Dispatcher.queue_message("'Descend'? Making a cheap little 'going-down' joke, are we?")
				end

			add_movable(Items::Item.new(*random_square(:empty?), "rug", "O", 8))
			.listen_for(:tread, Roguelike::Player) do
				Dispatcher.queue_message("The rug shouts, \"Don't step on me, motherfucker!\"")
			end
			.listen_for(:tread, Roguelike::Player) do
				Dispatcher.queue_message("The rug mutters threateningly.")
			end

			add_movable(Items::Item.new(*random_square(:empty?), "angry tile", "*", 4))
				.listen_for(:tread, Roguelike::Player) do |me|
					Dispatcher.queue_message("You step on an extremely angry floor tile.")
					Dispatcher.queue_message("\"You a dead motherfucker now!\" it screams.", true)
					me.color = 2
					me.listen_for(:sneeze, Roguelike::Player) do
						Dispatcher.queue_message("\"I'm gonna find you and kill you, motherfucker!\" shouts the angry tile.")
					end
					me.listen_for(:tread, Roguelike::Player) do
						Dispatcher.queue_message("You step on the angry floor tile again.")
						Dispatcher.queue_message("\"I told you you was dead, motherfucker!\"")
						Dispatcher.queue_message("The tile crumbles and tentacles shoot out, wrapping around you.")
						Game.over!
					end
				end

			add_movable(Monster.new(*random_square(:empty?), "Canadian", "@", 6))
				.listen_for(:explode) do |me|
					if me.visible?
						Dispatcher.queue_message("\"Oh, dear, things are exploding again!\" mutters the Canadian fretfully.", true)
					else
						Dispatcher.queue_message("\"Oh, dear, things are exploding again!\" murmurs someone with a Canadian accent.", true)
					end
				end
				.listen_for(:turn) do |me|
					me.move
				end
				.listen_for(:bump, Roguelike::Player) do
					Dispatcher.queue_message("You bump into a Canadian. The Canadian looks up in surprise. \"Oh, I'm dreadfully sorry!\" he says.")
				end
				.listen_for(:see, Roguelike::Player) do |me|
					me.ignore(:see)
					Dispatcher.queue_message("You see a Canadian muttering to himself and pacing.", true)
				end
				.listen_for(:hug, Roguelike::Player) do
					Dispatcher.queue_message("You hug the Canadian. He nuzzles your neck a little.")
				end
		end
	end
end
