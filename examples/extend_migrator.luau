local Creator = require("../src")

type DatabaseBuilder = Creator.DatabaseBuilder
type RecordBuilder = Creator.RecordBuilder

type Database = Creator.Database
type DataRecord = Creator.DataRecord
type SimpleDataRecord = Creator.SimpleDataRecord

type Migrator = (data: DataRecord) -> DataRecord
type Attributes<T> = {[string]: T}

type MigratorDatabase = {
	write __index: MigratorDatabase,
	write Template: SimpleDataRecord,
	
	--- Create a new record based on the database
	newRecord: (self: MigratorDatabase) -> DataRecord,
	--- Returns the internal template of the record used to construct
	--- the database
	frozenTemplate: (self: MigratorDatabase) -> SimpleDataRecord,

	loadRecord: (self: MigratorDatabase, data: buffer) -> DataRecord,
	version: (self: MigratorDatabase) -> number,
	encodeRecord: (self: MigratorDatabase, record: DataRecord) -> buffer
}

type MigratorDatabaseBuilder = {
	write __index: MigratorDatabaseBuilder,
	write __extend: {[string]: true?},
	write Parent: MigratorDatabaseBuilder?,
	write Value: any?,
	write Attributes: Attributes<any>?,
	write Version: number?,
	write Migrator: Migrator?,
	
	--- Create the blueprint for a record
	---
	--- @param name the name associated with the record
	---
	--- @return a DatabaseBuilder for the created record
	templateRecord: (self: MigratorDatabaseBuilder, name: string) -> MigratorDatabaseBuilder,
	--- Build the blueprint for the record
	---
	--- @return the holding record's DatabaseBuilder
	build: (self: MigratorDatabaseBuilder) -> MigratorDatabaseBuilder,
	
	--- Imprint the value into the record
	withValue: (self: MigratorDatabaseBuilder, value: any) -> MigratorDatabaseBuilder,
	--- Imprint the attributes into the record
	withAttributes: (self: MigratorDatabaseBuilder, attr: Attributes<any>) -> MigratorDatabaseBuilder,
	withVersion: (self: MigratorDatabaseBuilder, version: number) -> MigratorDatabaseBuilder,
	withMigrator: (self: MigratorDatabaseBuilder, fn: Migrator) -> MigratorDatabaseBuilder,
	
	--- Create and return a Database
	toDatabase: (self: MigratorDatabaseBuilder) -> MigratorDatabase
}

type MigratorCreator = {
	databaseBuilder: () -> MigratorDatabaseBuilder
}

local dbBuilder = Creator.databaseBuilder

local dbBuilderMethods = getmetatable(dbBuilder()).__index
local dbMethods = getmetatable(dbBuilder():toDatabase()).__index

-- Migrator -- Version control
-- DatabaseBuilder
--     Add Version / Migrator / Id to __extend
--     Add withVersion(number) and withMigrator((data: DataRecord) -> DataRecord)
-- Database
--     Add loadRecord(buffer): DataRecord and version()
--     Add encodeRecord(DataRecord): buffer

dbBuilderMethods.__extend.Version = true
dbBuilderMethods.__extend.Migrator = true

function dbBuilderMethods:withVersion(version: number)
	if self.Parent then
		error("Incapable of internal version control")
	end
	self.Version = version
	return self
end

function dbBuilderMethods:withMigrator(fn: Migrator)
	self.Migrator = fn
	return self
end

function dbMethods:loadRecord(data: buffer)
	-- decode complexity depends on how dense you want the 
	-- buffer to be (how much preprocessing you did)
	if not self.Migrator then
		return self:newRecord()
	end
	return self.Migrator(decode(data))
end

function dbMethods:version()
	return self.Version
end

function dbMethods:encodeRecord(record: DataRecord): buffer
	-- encode complexity depends on how dense you want the 
	-- buffer to be (how much preprocessing to do)
	-- smaller output sizes may be a priority
	-- legibility may be priority [JSON]
	return encode(record)
end

local Migrator: MigratorCreator = Creator

print(Migrator.databaseBuilder()
	:withVersion(5)
	:templateRecord("Foo")
		:withValue(1)
		:templateRecord("Baz")
			:withValue(2)
		:build()
	:build()
	:toDatabase()
	:newRecord()
		:builder()
			:withValue(4)
		:toRecord())

return Migrator
