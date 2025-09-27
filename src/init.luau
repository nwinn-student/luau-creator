--!strict
--!optimize 2

type Named<T> = {[string]: T}

export type SimpleDataRecord = {
	-- TODO: Allow for records to be supported by the type system
	[string]: DataRecord,
	read Value: any,
}

export type DataRecord = {
	write __index: DataRecord,
	
	-- TODO: Allow for records to be supported by the type system
	[string]: DataRecord,
	Value: any,
}

export type Database = {
	write __index: Database,
	write Template: SimpleDataRecord,
	
	--- Create a new record based on the database
	read newRecord: (self: Database) -> DataRecord,
	--- Returns the internal template of the record used to construct
	--- the database
	read frozenTemplate: (self: Database) -> SimpleDataRecord
}

export type DatabaseBuilder = {
	write __index: DatabaseBuilder,
	-- Allows for extenders to have more control over the specifics
	write __extend: Named<(true | "clone")?>,
	write Parent: DatabaseBuilder?,
	write Value: any?,
	
	--- Create the blueprint for a record
	---
	--- @param name the name associated with the record
	---
	--- @return a DatabaseBuilder for the created record
	read templateRecord: (self: DatabaseBuilder, name: string) -> DatabaseBuilder,
	--- Build the blueprint for the record
	---
	--- @return the holding record's DatabaseBuilder
	read build: (self: DatabaseBuilder) -> DatabaseBuilder,
	
	read withValue: (self: DatabaseBuilder, value: any) -> DatabaseBuilder,
	
	read toDatabase: (self: DatabaseBuilder) -> Database
}

local Creator = {}
local Extendor = {}

local DatabaseBuilder = {}
DatabaseBuilder.__index = DatabaseBuilder
DatabaseBuilder.__extend = Extendor

local Database = {}
Database.__index = Database

local DataRecord = {}
DataRecord.__index = DataRecord

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

function DatabaseBuilder:toDatabase()
	local function removeParent(data: {[any]: any})
		for name, record in data do
			if name == "Value" or Extendor[name] then
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
		
		if Extendor[key] then
			copy[key] = if Extendor[key] == "clone" then
					table.clone(value)
				else
					value
			continue
		end
		
		copy[key] = deepCopy(value)
	end
	return setmetatable(copy, DataRecord)
end

-- subject to alot of change when extending
function Database:newRecord()
	return deepCopy(self.Template)
end

-- used for comparison
function Database:frozenTemplate()
	return self.Template
end

function Creator.databaseBuilder()
	return setmetatable({}, DatabaseBuilder) :: DatabaseBuilder
end

return Creator
