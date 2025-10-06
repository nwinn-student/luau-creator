local Creator = require("../src")

local builder = Creator.structBuilder

local builderMethods = builder().__index
local structMethods = builder():toStruct().__index
local recordMethods = builder():toStruct():newRecord().__index

require("./extend_attribute")
require("./extend_variadic")
require("./extend_migrator")
require("./extend_compressor")
require("./extend_replicator")

type Struct<T = any> = Creator.Struct<T>
type Record<T = any> = Creator.Record<T>
type Named<T> = {[string]: T}

type Mode = "Attribute" | "Record"
type Replicator = (name: string, value: any, mode: Mode?)->()
type Migrator = (data: Record<AllRecord>) -> Record<AllRecord>

type AllSimple = {
	read Attributes: Named<any>?
}
type AllRecord = {
	attribute: (
		self: Record<AllRecord>,
		name: string
	) -> any,
	withAttribute: (
		self: Record<AllRecord>,
		name: string,
		value: any
	) -> Record<AllRecord>,
	
	withRecord: (
		self: Record<AllRecord>,
		name: string
	) -> Record<AllRecord>,
	
	withReplicator: (
		self: Record<AllRecord>,
		fn: Replicator
	) -> Record<AllRecord>
}
type AllStruct = {
	loadRecord: (
		self: Struct<AllStruct>,
		data: {[any]: any}
	) -> Record<AllRecord>,
	version: (self: Struct<AllStruct>) -> number,
}
type ABuilder<T> = Creator.StructBuilder<T, AllStruct, AllRecord, AllSimple>
type AllBuilder = {
	withAttributes: (
		self: ABuilder<AllBuilder>, 
		attrs: Named<any>
	) -> ABuilder<AllBuilder>,
	
	withVersion: (
		self: ABuilder<AllBuilder>,
		version: number
	) -> ABuilder<AllBuilder>,
	withMigrator: (
		self: ABuilder<AllBuilder>,
		fn: Migrator
	) -> ABuilder<AllBuilder>,
	
	withId: (
		self: ABuilder<AllBuilder>,
		id: number
	) -> ABuilder<AllBuilder>
}

type AllCreator = Creator.Creator<AllBuilder, AllStruct, AllRecord, AllSimple>

local structHolder = setmetatable({}, { __mode = "ks" })

function recordMethods:withRecord(name: string)
	local structFinder = function(self)
		return structHolder[self]
	end
	
	local record = setmetatable({
		StructFinder = structFinder
	}, recordMethods)
	
	structHolder[record] = {
		Parent = self:StructFinder()
	}
	
	if not self[2] then
		self[2] = {}
		-- No relation since we cannot specify the id
	end
	
	local repl = self.Replicator
	if repl then
		repl(name, record, "Record")
	end
	
	self[2][name] = record
	
	return self
end

function recordMethods:withAttribute(name: string, value: any)
	assert(self[3], "Unable to set attribute") -- ???
	
	local repl = self.Replicator
	if repl then
		repl(name, value, "Attribute")
	end
	
	self[3][name] = value
	return self
end

function recordMethods:attribute(name: string)
	if not self[3] then
		return nil
	end
	return self[3][name]
end

local function convertAttribute(data: Creator.Record)
	for name, value in data do
		if name ~= "Attributes" then
			if type(value) == "table" then
				convertAttribute(value)
			end
			continue
		end
		data[3] = value
		data.Attributes = nil
		continue
	end
end

local newRecord = structMethods.newRecord
function structMethods:newRecord()
	local record = newRecord(self)
	convertAttribute(record)
	return record
end

local AllCreator: AllCreator = Creator

local format = AllCreator:structBuilder()
	:withMigrator(function(data)
		print(data)
	end)
	:withVersion("v1.0.0")
	:templateRecord("hey")
		:withValue(5)
		:withId(8)
		:withAttributes({hey=1})
	:build()
	:toStruct()

print(format:loadRecord({1,2,3}))
print(format:newRecord())
print(format:newRecord()
		:withRecord("what")
		:withReplicator(function(name, value, mode) 
			print(value)
		end)
		:withValue(50)
		:record("what")
			:withReplicator(function(name, value, mode)
				print(value)
			end)
			:withValue(1)
			:withRecord("how")
			:record("how")
				:withReplicator(function(name, value, mode)
					print(value)
				end)
				:withValue(123))
	
-- locking down Creator
table.freeze(builderMethods)
table.freeze(structMethods)
table.freeze(recordMethods)

return Creator
