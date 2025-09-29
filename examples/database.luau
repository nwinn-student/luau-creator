local Creator = require("../src")

--[[	
	{
		Name = "Foo", 
		Property = {
			{
				Name = "Baz",
				Value = 0,
				-- Allows for Baz to have attached Elements
				Property = {}
			},
			{
				Name = "Bar",
				Value = "Hello World!",
				Property = {
					{
						Name = "Foo",
						Value = vector.create(1, 2, 3)
					}
				}
			}
		}
	},
	{
		Name = "Sample",
		Property = {
			{
				Name = "Greeting",
				Value = "Welcome",
				Attributes = {
					-- Acquaintances, Casual, Close, Intimate
					Connection = "Acquaintances"
				}
			}
		}
	}
]]

local Struct = Creator.structBuilder()
	:templateRecord("Foo")
		:templateRecord("Baz")
			:withValue(0)
			-- Implied that Baz could have attached elements
			-- up to the serializer to decide whether or not to save.
			-- Extenders could require templateRecord() to save.
		:build()
		:templateRecord("Bar")
			:withValue("Hello World!")
			:templateRecord("Foo")
				:withValue(vector.create(1, 2, 3))
			:build()
		:build()
	:build()
	:templateRecord("Sample")
		:templateRecord("Greeting")
			:withValue("Welcome")
			-- To support attributes we must extend OR
			-- assume that attributes are like records
			-- which is what I will do in this case.
			:templateRecord("Attributes")
				:templateRecord("Connection")
					-- Acquaintances, Casual, Close, Intimate
					:withValue("Acquaintances")
				:build()
			:build()
		:build()
	:build()
	:toStruct()

print(Struct)
