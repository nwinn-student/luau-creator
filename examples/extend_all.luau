local Creator = require("../src")

-- Incorrect, will fix later..
type Record = Creator.Record

local builder = Creator.structBuilder

local builderMethods = builder().__index
local structMethods = builder():toStruct().__index
local recordMethods = builder():toStruct():newRecord().__index

require("./extend_attribute")
require("./extend_variadic")
require("./extend_migrator")
require("./extend_compressor")
require("./extend_replicator")

local structHolder = setmetatable({}, { __mode = "ks" })

function recordMethods:withRecord(name: string)
	local record = {}
	
	local parent = self.StructFinder()
	
	local struct = {
		Parent = parent
	}
	
	structHolder[record] = struct
	
	record.StructFinder = function()
		return structHolder[record]
	end
	
	if not self[2] then
		self[2] = {}
		-- No relation since we cannot specify the id
	end
	
	self[2][name] = setmetatable(record, recordMethods)
	
	return self
end

print(Creator:structBuilder()
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
		:onChange(function(value) print(value) end)
		:withValue(50)
		:record("what")
			:onChange(function(value) print(value) end)
			:withValue(1)
			:withRecord("how")
			:record("how")
				:onChange(function(value) print(value) end)
				:withValue(123))
	
-- locking down Creator
table.freeze(builderMethods)
table.freeze(structMethods)
table.freeze(recordMethods)

return Creator
