class DishwasherController < ApplicationController
	def index
		@dishes = Dishwasher::Dish.all
	end
end