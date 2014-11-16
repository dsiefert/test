module Roguelike
	class Inventory
		attr_reader :items

		def initialize(owner)
			@owner = owner
			@items = []
		end

		def add(item)
			@items.push(item)
		end

		def options
			return nil if empty?

			@items.map do |item|
				Roguelike::Dispatcher::Option.new(item.fancy_name, item)
			end
		end

		def empty?
			@items.empty?
		end

		def include?(item)
			@items.include?(item)
		end
	end
end
