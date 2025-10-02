local Creator = require("../src")

-- NOT DONE
-- the plan is to add them all but I am incrementally
-- adding each to ensure there is no easy-to-spot error
require("./extend_attribute")
require("./extend_variadic")
require("./extend_replicator")
require("./extend_migrator")

-- Incorrect, will fix later..
type Record = Creator.Record

local builder = Creator.structBuilder

local builderMethods = builder().__index
local structMethods = builder():toStruct().__index
local recordMethods = builder():toStruct():newRecord().__index

print(builderMethods)
print(structMethods)
print(recordMethods)

print(Creator:structBuilder()
	:withReplicator(function(path: string, value: any)
		print(path, value)
	end)
	:withMigrator(function(data: Record)
		print(data)
	end)
	:templateRecord("hey")
		:withValue(5)
		:withAttributes({hey=1})
	:build()
	:toStruct()
	:newRecord()
	:withRecord("what")
	:withValue(50))
