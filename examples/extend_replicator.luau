local Creator = require("../src")

-- Most of these are built on assumptions
-- the internals can be modified by other extenders
-- to be more optimal for output size, memory, or speed

type StructBuilder = Creator.StructBuilder

type Struct = Creator.Struct
type Record = Creator.Record
type SimpleRecord = Creator.SimpleRecord

type Named<T> = {[string]: T}
type Replicator = (path: string, value: any)->()

type ReplicatorStructBuilder = {
	write __index: ReplicatorStructBuilder,
	write __extend: Named<(true | "clone")?>,
	write Parent: ReplicatorStructBuilder?,
	write Value: any?,
	write Replicator: Replicator?,
	
	templateRecord: (self: ReplicatorStructBuilder, name: string) -> ReplicatorStructBuilder,
	build: (self: ReplicatorStructBuilder) -> ReplicatorStructBuilder,
	
	withValue: (self: ReplicatorStructBuilder, value: any) -> ReplicatorStructBuilder,
	withReplicator: (self: ReplicatorStructBuilder, replicator: Replicator) -> ReplicatorStructBuilder,
	
	toStruct: (self: ReplicatorStructBuilder) -> Struct
}

type ReplicatorCreator = {
	structBuilder: () -> ReplicatorStructBuilder
}

local builder: ReplicatorCreator = Creator.structBuilder

local builderMethods = builder().__index
local recordMethods = builder():toStruct():newRecord().__index

-- Replicator -- Pass changes around
-- Much like the migrator example, a single Replicator should be able 
-- to get ALL changes within the record.  Whether we are 
-- adding/removing records, changing values, whatever.
--
-- StructBuilder
--     Add withReplicator((path: string, value: any)->())
--     withValue now refers to the Value
-- Record
--     withValue and value now refer to the Value

builderMethods.__extend.Replicator = true
builderMethods.__extend.FullName = "HideFromRecord"
builderMethods.__extend.StructFinder = true

local withValue = recordMethods.withValue

function recordMethods:withValue(value: any)
	local function getReplicator(data: Struct)
		-- Replicator can only be at the topmost level
		-- data.Parent cannot ever point to data
		-- [except when using an extension]
		while data.Parent do
			data = data.Parent
		end
		return data.Replicator
	end
	
	local struct = self.StructFinder()
	local repl = getReplicator(struct)
	if repl then
		repl(struct.FullName..".Value", value)
	end
	return withValue(self, value)
end

local templateRecord = builderMethods.templateRecord

function builderMethods:templateRecord(name: string)
	-- Performance is not taken into account
	-- reversing would be faster for deeper records
	local function getFullName(data: StructBuilder)
		local parTable = { data.Name }
		local parent = data.Parent
		
		while parent do
			table.insert(parTable, 1, parent.Name)
			parent = parent.Parent
		end
		
		return table.concat(parTable, ".")
	end
	
	local record = templateRecord(self, name)
	
	if not self.FullName then
		self.FullName = "<root>"
		self.Name = "<root>"
	end
	
	record.FullName = getFullName(record)
	
	-- Very useful to know about!
	-- also rather expensive since it can create MANY functions
	record.StructFinder = function()
		return record
	end
	if not self.StructFinder then
		self.StructFinder = function()
			return self
		end
	end
	
	return record
end

function builderMethods:withValue(value: any)
	self.Value = value
	return self
end
function builderMethods:withReplicator(fn: Replicator)
	if self.Parent then
		error("Incapable of internal replicator")
	end
	self.Replicator = fn
	return self
end

local Replicator: ReplicatorCreator = Creator

local a = Replicator.structBuilder()
	:withReplicator(function(path: string, value) 
		print(1, path, value)
	end)
	:templateRecord("Foo")
		:withValue(1)
		:templateRecord("Baz")
			:withValue(2)
		:build()
	:build()
	:toStruct()
	:newRecord()

a:withValue(5)
a.Foo:withValue(6)

print(a)
