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
	local relation = self:StructFinder().Relation
	local id = relation and relation[name]
	local structFinder = if id then
			self.StructFinder
		else
			function(self)
				return structHolder[self]
			end
	
	local record = setmetatable({
		StructFinder = structFinder 
	}, recordMethods)
	
	if id then
		structHolder[record] = {
			Parent = self:StructFinder()
		}
	end
	
	if not self[2] then
		self[2] = {}
	end
	
	local repl = self.Replicator
	if repl then
		repl(name, record, "Record")
	end
	
	self[2][relation[name]] = record
	return self
end

-- records would be a very useful method to have
-- it would need to return a new table of the name to values
-- within the existing table.
-- We would need to add it to Compressor

function recordMethods:withAttribute(name: string, value: any)
	if type(self[3]) ~= "table" then
		self[3] = {}
	end
	
	local repl = self.Replicator
	if repl then
		repl(name, value, "Attribute")
	end
	
	self[3][name] = value
	return self
end

function recordMethods:attribute(name: string)
	if type(self[3]) ~= "table" then
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

local function wrap(data: {[any]: any}, par)
	local function addFinder(data, par)
		if par.StructFinder then
			data.StructFinder = par.StructFinder
		else
			local structFinder = function(self)
				return structHolder[self]
			end
			
			data.StructFinder = structFinder
			structHolder[data] = par
		end
	end
	if type(data[2]) ~= "table" then
		addFinder(data, par)
		return setmetatable(data, recordMethods)
	end
	for key, value in data[2] do
		if type(value) ~= "table" then
			continue
		end
		
		local internalParent = par[key] or {
			Parent = par
		}
		
		wrap(value, internalParent)
	end
	addFinder(data, par)
	return setmetatable(data, recordMethods)
end

function structMethods:loadRecord(data: {[any]: any})
	local template = self.Template
	if not template.Migrator then
		return self:newRecord()
	end
	return template.Migrator(wrap(data, template))
end

local AllCreator: AllCreator = Creator
local format = AllCreator:structBuilder()
	:withMigrator(function(data)
		--print(data)
		--print(data:value())
		--print(data:record("a"))
		return data
	end)
	:withVersion("v1.0.0")
	:templateRecord("hey")
		:withValue(5)
		:withId(8)
		:withAttributes({hey=1})
	:build()
	:toStruct()

print(format:loadRecord({}):withRecord("hey"):record("hey"):withValue(1))

local loaded = format:loadRecord({1,[2] = {
	a = {1,
	[2] = {1, b = {}}
	,[3] = 3}
},[3] = 3})
print(loaded)
--print(format:newRecord())
--print(format:newRecord()
--		:withRecord("what")
--		:withReplicator(function(name, value, mode) 
--			print(value)
--		end)
--		:withValue(50)
--		:record("what")
--			:withReplicator(function(name, value, mode)
--				print(value)
--			end)
--			:withValue(1)
--			:withRecord("how")
--			:record("how")
--				:withReplicator(function(name, value, mode)
--					print(value)
--				end)
--				:withValue(123))
	
-- locking down Creator
--table.freeze(builderMethods)
--table.freeze(structMethods)
--table.freeze(recordMethods)

return Creator
