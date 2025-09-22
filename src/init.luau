--!strict
--!optimize 2

type Attributes<T> = {[string]: T}

-- Flawed in that it is a duplicate of DatabaseBuilder
--- 
export type RecordBuilder = {
	write __index: RecordBuilder,
	write Value: any?,
	write Attributes: Attributes<any>?,
	
	--- Create the blueprint for a record
	---
	--- @param name the name associated with the record
	---
	--- @return a RecordBuilder for the created record
	templateRecord: (self: RecordBuilder, name: string) -> RecordBuilder,
	
	--- Imprint the value into the record
	withValue: (self: RecordBuilder, value: any) -> RecordBuilder,
	--- Imprint the attributes into the record
	withAttributes: (self: RecordBuilder, attr: Attributes<any>) -> RecordBuilder,
	
	--- Create and return a record
	toRecord: (self: RecordBuilder) -> DataRecord
}

type SimpleDataRecord = {
	-- TODO: Allow for records to be supported by the type system
	[string]: DataRecord,
	read Value: any,
	
	-- TODO: If possible, allow for the type system to also support attributes
	read Attributes: Attributes<any>?,
}

export type DataRecord = {
	write __index: DataRecord,
	
	-- TODO: Allow for records to be supported by the type system
	[string]: DataRecord,
	Value: any,
	
	-- TODO: If possible, allow for the type system to also support attributes
	write Attributes: Attributes<any>?,
	
	--- Returns the attached attributes
	attributes: (self: DataRecord) -> Attributes<any>?,
	--- Returns a table referencing the attached records.    
	--- Modifications to the table directly has no impact 
	--- on the underlying record.
	records: (self: DataRecord) -> Attributes<DataRecord>?,
	
	builder: (self: DataRecord) -> RecordBuilder
}

export type Database = {
	write __index: Database,
	write Template: SimpleDataRecord,
	
	--- Create a new record based on the database
	newRecord: (self: Database) -> DataRecord,
	--- Returns the internal template of the record used to construct
	--- the database
	frozenTemplate: (self: Database) -> SimpleDataRecord
}

export type DatabaseBuilder = {
	write __index: DatabaseBuilder,
	write Parent: DatabaseBuilder?,
	write Value: any?,
	write Attributes: Attributes<any>?,
	
	--- Create the blueprint for a record
	---
	--- @param name the name associated with the record
	---
	--- @return a DatabaseBuilder for the created record
	templateRecord: (self: DatabaseBuilder, name: string) -> DatabaseBuilder,
	--- Build the blueprint for the record
	---
	--- @return the holding record's DatabaseBuilder
	build: (self: DatabaseBuilder) -> DatabaseBuilder,
	
	--- Imprint the value into the record
	withValue: (self: DatabaseBuilder, value: any) -> DatabaseBuilder,
	--- Imprint the attributes into the record
	withAttributes: (self: DatabaseBuilder, attr: Attributes<any>) -> DatabaseBuilder,
	
	--- Create and return a Database
	toDatabase: (self: DatabaseBuilder) -> Database
}

local Creator = {}

local DatabaseBuilder = {}
DatabaseBuilder.__index = DatabaseBuilder

local Database = {}
Database.__index = Database

local DataRecord = {}
DataRecord.__index = DataRecord

local RecordBuilder = {}
RecordBuilder.__index = RecordBuilder

function DatabaseBuilder:templateRecord(name: string)
	local init = { Parent = self }
	self[name] = init
	return setmetatable(init, DatabaseBuilder)
end

function DatabaseBuilder:build()
	return self.Parent or self
end

function DatabaseBuilder:withValue(value: any)
	self.Value = value
	return self
end

function DatabaseBuilder:withAttributes(attr: Attributes<any>)
	self.Attributes = attr
	return self
end

function DatabaseBuilder:toDatabase()
	-- Optional: Remove all Parents
	-- Some extenders may want Parent for internal use
	local function removeParent(data: {[any]: any})
		for name, record in data do
			if name == "Value" or name == "Attributes" then
				continue
			end
			record.Parent = nil
			table.freeze(record :: DatabaseBuilder)
			removeParent(record)
		end 
	end
	
	removeParent(self)
	
	table.freeze(self :: DatabaseBuilder)
	
	return setmetatable({Template = self}, Database)
end

@native
local function deepCopy(data: {[any]: any})
	local copy = {
		Value = data.Value
	}
	for key, value in data do
		if key == "Value" then
			continue
		end
		if key == "Attributes" then
			copy[key] = table.clone(value)
			continue
		end
		
		copy[key] = deepCopy(value)
	end
	return setmetatable(copy, DataRecord)
end

function Database:newRecord()
	-- TODO: Just return empty table and populate it lazily?
	-- or recreate it entirely??
	
	-- I think recreating will be easier to support
	-- extenders
	return deepCopy(self.Template)
end

function Database:frozenTemplate()
	return self.Template
end

function DataRecord:attributes()
	return self.Attributes
end

function DataRecord:records()
	local copy = table.clone(self)
	copy.Value = nil
	copy.Attributes = nil
	return copy
end

function DataRecord:builder()
	-- What if we remove builder and instead have a way
	-- to create a record via name
	-- like: addRecord(name: string) or buildRecord
	-- or.. we keep it w/ this BUT allow Parent to be 
	-- used to navigate
	-- issue is that it breaks the "Must be serializable"
	-- clause
	-- so.. ??
	-- withRecord
	-- withValue
	-- just keep same lol
	-- we can remove build from the design to limit what users can do
	-- but still allow for them do to ALOT
	-- doing that, avoids issues where Parent is not deleted 
	-- and causes external modules to fail when serializing
	return setmetatable(self, RecordBuilder)
end

function RecordBuilder:templateRecord(name: string)
	local init = {}
	self[name] = init
	return setmetatable(init, RecordBuilder)
end

RecordBuilder.withValue = DatabaseBuilder.withValue
RecordBuilder.withAttributes = DatabaseBuilder.withAttributes

function RecordBuilder:toRecord()
	return setmetatable(self, DataRecord)
end

function Creator.databaseBuilder()
	return setmetatable({}, DatabaseBuilder) :: DatabaseBuilder
end

return Creator
