local Creator = require("./Creator")

--[[
	How it would look w/o functions:
	
	You can actually pass the below in and it will act the same, 
		it is merely preference.
	
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

local Database = Creator.fromProperties(
	Creator.propertyBuilder("Foo")
		:templateElement("Baz")
			:withValue(0)
			-- Allows for Baz to have attached Elements
			:templateProperty()
			:build()
		:build()
		:templateElement("Bar")
			:withValue("Hello World!")
			:templateProperty()
				:templateElement("Foo")
					:withValue(vector.create(1, 2, 3))
				:build()
			:build()
		:build()
		:toProperty(),
	Creator.propertyBuilder("Sample")
		:templateElement("Greeting")
			:withValue("Welcome")
			-- Acquaintances, Casual, Close, Intimate
			:withAttributes({ Connection = "Acquaintances" })
		:build()
		:toProperty()
	)