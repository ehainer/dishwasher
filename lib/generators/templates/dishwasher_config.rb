Dishwasher.setup do |config|
	# Max number of records to check in a given "tick" of the cron
	# All links within each chunk will be checked
	config.chunk_size = 20
end