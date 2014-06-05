Dishwasher.setup do |config|
	# Max number of links to check per hour
	# The number of links checked in a given "chunk" depends
	# on how often the whenever task is scheduled to run
	config.chunk_size = 20
end