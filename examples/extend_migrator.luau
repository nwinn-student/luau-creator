local Creator = require("../src")

type StructBuilder = Creator.StructBuilder

type Struct = Creator.Struct
type Record = Creator.Record
type SimpleRecord = Creator.SimpleRecord

type Named<T> = {[string]: T}
type Migrator = (data: Record) -> Record

type MigratorStruct = {
	write __index: MigratorStruct,
	write Template: SimpleRecord,
	
	newRecord: (self: MigratorStruct) -> Record,
	frozenTemplate: (self: MigratorStruct) -> SimpleRecord,

	loadRecord: (self: MigratorStruct, data: {[any]: any}) -> Record,
	version: (self: MigratorStruct) -> number,
}

type MigratorStructBuilder = {
	write __index: MigratorStructBuilder,
	write __extend: Named<(true | "clone")?>,
	write Parent: MigratorStructBuilder?,
	write Value: any?,
	write Version: number?,
	write Migrator: Migrator?,
	
	templateRecord: (self: MigratorStructBuilder, name: string) -> MigratorStructBuilder,
	build: (self: MigratorStructBuilder) -> MigratorStructBuilder,
	
	withValue: (self: MigratorStructBuilder, value: any) -> MigratorStructBuilder,
	withVersion: (self: MigratorStructBuilder, version: number) -> MigratorStructBuilder,
	withMigrator: (self: MigratorStructBuilder, fn: Migrator) -> MigratorStructBuilder,
	
	toStruct: (self: MigratorStructBuilder) -> MigratorStruct
}

type MigratorCreator = {
	structBuilder: () -> MigratorStructBuilder
}

local builder = Creator.structBuilder

local builderMethods = builder().__index
local structMethods = builder():toStruct().__index

-- Migrator -- Version control
-- StructBuilder
--     Add Version / Migrator to __extend
--     Add withVersion(number) and withMigrator((data: DataRecord) -> DataRecord)
-- Struct
--     Add loadRecord({[any]: any}): DataRecord and version()
builderMethods.__extend.Version = "HideFromRecord"
builderMethods.__extend.Migrator = "HideFromRecord"

function builderMethods:withVersion(version: number)
	if self.Parent then
		error("Incapable of internal version control")
	end
	self.Version = version
	return self
end

function builderMethods:withMigrator(fn: Migrator)
	if self.Parent then
		error("Incapable of internal migration")
	end
	self.Migrator = fn
	return self
end


local function wrap(data: {[any]: any})
	-- errors if failure to wrap, meaning that the inserted table
	-- was not up to code
	for key, value in data do
		if key == "Value" then
			continue
		end
		if builderMethods.__extend[key] then
			continue
		end
		if type(value) ~= "table" then
			continue
		end
		wrap(value)
	end
	return setmetatable(data, recordMethods)
end

function structMethods:loadRecord(data: {[any]: any})
	if not self.Template.Migrator then
		return self:newRecord()
	end
	return self.Template.Migrator(wrap(data))
end

function structMethods:version()
	return self.Version
end

return Creator :: MigratorCreator
