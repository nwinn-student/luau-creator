local Creator = require("../src")

-- Most of these are built on assumptions
-- the internals can be modified by other extenders
-- to be more optimal for output size, memory, or speed

type DatabaseBuilder = Creator.DatabaseBuilder

type Database = Creator.Database
type DataRecord = Creator.DataRecord
type SimpleDataRecord = Creator.SimpleDataRecord

type Named<T> = {[string]: T}
type Replicator = (path: string, value: any)->()

type ReplicatorDatabaseBuilder = {
	write __index: ReplicatorDatabaseBuilder,
	write __extend: Named<(true | "clone")?>,
	write Parent: ReplicatorDatabaseBuilder?,
	write Value: any?,
	write Replicator: Replicator?,
	
	templateRecord: (self: ReplicatorDatabaseBuilder, name: string) -> ReplicatorDatabaseBuilder,
	build: (self: ReplicatorDatabaseBuilder) -> ReplicatorDatabaseBuilder,
	
	withValue: (self: ReplicatorDatabaseBuilder, value: any) -> ReplicatorDatabaseBuilder,
	withReplicator: (self: ReplicatorDatabaseBuilder, replicator: Replicator) -> ReplicatorDatabaseBuilder,
	
	toDatabase: (self: ReplicatorDatabaseBuilder) -> Database
}

type ReplicatorCreator = {
	databaseBuilder: () -> ReplicatorDatabaseBuilder
}

local dbBuilder: ReplicatorCreator = Creator.databaseBuilder

local dbBuilderMethods = dbBuilder().__index
local dbMethods = dbBuilder():toDatabase().__index
local drMethods = dbBuilder():toDatabase():newRecord().__index

-- Replicator -- Pass changes around
-- Could be wrong, it is rather complex and there is no implementation 
-- of Creator available to verify correctness.
--
-- DatabaseBuilder
--     Add withReplicator((path: string, value: any)->())
-- Database
--     newRecord now passes an object referencing the data
--         instead of the data itself
-- DataRecord
--     Updated to use __newindex function ^
dbBuilderMethods.__extend.Replicator = true
dbBuilderMethods.__extend[1] = true -- [1] is Value, we have replaced Value!
local function replicator(self, key: string, value: any)
	local repl = self.Replicator
	if repl then
		repl(key, value)
	end
	if key == "Value" then
		rawset(self, 1, value)
		return 
	end
	rawset(self, key, value)
end

drMethods.__newindex = replicator
setmetatable(drMethods, {__index = function(self, key: string)
	if key == "Value" then
		-- sadly self is drMethods and not dataRecord?
		return rawget(self, 1)
	end
	return rawget(self, key)
end})

function dbBuilderMethods:withValue(value: any)
	self[1] = value
	return self
end
function dbBuilderMethods:withReplicator(fn: Replicator)
	self.Replicator = fn
	return self
end

local Replicator: ReplicatorCreator = Creator

-- NOT WORKING YET
local a = Replicator.databaseBuilder()
	:withReplicator(function(path: string, value) 
		print(1, path, value)
	end)
	:templateRecord("Foo")
		:withReplicator(function(path: string, value) 
			print(2, path, value)
		end)
		:withValue(1)
		:templateRecord("Baz")
			:withValue(2)
		:build()
	:build()
	:toDatabase()
	:newRecord()

-- so we need to probably modify newRecord to be.. better
-- the below code does NOT call the replicator
a.Value = 5
a.Foo.Value = 6
-- now the issue is that if it exists, we need to do some extra work
-- so we could instead store it in [1]?

print(a.Value)
print(getmetatable(a), a)
