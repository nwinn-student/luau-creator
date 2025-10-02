local Creator = require("../src")

-- Incorrect, will fix later..
type Record = Creator.Record

local builder = Creator.structBuilder

local builderMethods = builder().__index
local structMethods = builder():toStruct().__index
local recordMethods = builder():toStruct():newRecord().__index

require("./extend_attribute")
require("./extend_variadic")
require("./extend_replicator")
require("./extend_migrator")

-- Introducing this breaks record(name)
-- when working w/ withRecord(name)
-- also breaks withRecord
local withValue = recordMethods.withValue
local withRecord = recordMethods.withRecord

require("./extend_compressor")

function recordMethods:withValue(value: any)
	withValue(self, value) -- sets .Value
	self.Value = nil
	self[1] = value
	return self
end
function recordMethods:withRecord(name: string)
	withRecord(self, name)
	
	local record = self[name]
	
	self[name] = nil
	self[2][name] = record
	
	-- could be stored outside, but adds complexity
	record.StructFinder = function()
		return record
	end
	
	return self
end

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
		:withId(8)
		:withAttributes({hey=1})
	:build()
	:toStruct()
	:newRecord()
	:withRecord("what")
	:withValue(50))
