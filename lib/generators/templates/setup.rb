generate(:migration, "dishwasher_loads klass:string offset:integer")
rake("db:migrate")