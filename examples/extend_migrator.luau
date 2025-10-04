local Creator = require("../src")

type Creator<T = unknown, U = unknown> = Creator.Creator<T,U>
type Builder<T = unknown, U = unknown> = Creator.StructBuilder<T,U>
type Struct<T = unknown> = Creator.Struct<T>
type Record = Creator.Record

type Migrator = (data: Record) -> Record
type MigratorStruct = {
	loadRecord: (self: Struct<MigratorStruct>, data: {[any]: any}) -> Record,
	version: (self: Struct<MigratorStruct>) -> number,
}
type MigratorBuilder = {
	withVersion: (
		self: Builder<MigratorBuilder, MigratorStruct>,
		version: number
	) -> Builder<MigratorBuilder, MigratorStruct>,
	withMigrator: (
		self: Builder<MigratorBuilder, MigratorStruct>,
		fn: Migrator
	) -> Builder<MigratorBuilder, MigratorStruct>,
}
type MigratorCreator = Creator<MigratorBuilder, MigratorStruct>

local builder = Creator.structBuilder

local builderMethods = builder().__index
local structMethods = builder():toStruct().__index
local recordMethods = builder():toStruct():newRecord().__index

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

-- TODO: Fails to easily conform to extensions
-- Causes errors when using :StructFinder, meaning
-- we have to rewrite much more code to account for
-- this?
local function wrap(data: {[any]: any})
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
