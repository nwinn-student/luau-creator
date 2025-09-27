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
-- Could be wrong, it is rather complex and there is no implementation 
-- of Creator available to verify correctness.
--
-- StructBuilder
--     Add withReplicator((path: string, value: any)->())
--     withValue now refers to the Value
-- Record
--     withValue and value now refer to the Value

builderMethods.__extend.Replicator = true

function recordMethods:withValue(value: any)
	local repl = self.Replicator
	if repl then
		repl("Value", value)
	end
	rawset(self, "Value", value)
	return self
end
-- .Value could be used BUT there is no guarantee that
-- another extension will not modify it to be more optimally stored
function recordMethods:value()
	return self.Value
end

function builderMethods:withValue(value: any)
	self.Value = value
	return self
end
function builderMethods:withReplicator(fn: Replicator)
	self.Replicator = fn
	return self
end

local Replicator: ReplicatorCreator = Creator

local a = Replicator.structBuilder()
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
	:toStruct()
	:newRecord()

a:withValue(5)
a.Foo:withValue(6)

print(a)
