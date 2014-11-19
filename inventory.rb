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

			categories = @items.map(&:category).uniq.sort
			categories.delete("Miscellaneous") && categories.push("Miscellaneous") if categories.index("Miscellaneous")

			returnval = []
			categories.each do |c|
				returnval.push(Roguelike::Dispatcher::Option.new("\n" + c))
				@items.select{ |i| i.category == c }.each do |item|
					returnval.push(Roguelike::Dispatcher::Option.new(item.fancy_name, item))
				end
			end

			returnval
		end

		def empty?
			@items.empty?
		end

		def include?(item)
			@items.include?(item)
		end
	end
end
