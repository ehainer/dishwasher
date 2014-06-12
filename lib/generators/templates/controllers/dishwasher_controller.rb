class DishwasherController < ApplicationController
	def index
		@dishes = Dishwasher::Dish.where.not(status: 200)
	end
end