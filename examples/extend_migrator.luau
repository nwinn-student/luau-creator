local Creator = require("../src")

type DatabaseBuilder = Creator.DatabaseBuilder

type Database = Creator.Database
type DataRecord = Creator.DataRecord
type SimpleDataRecord = Creator.SimpleDataRecord

type Named<T> = {[string]: T}
type Migrator = (data: DataRecord) -> DataRecord

type MigratorDatabase = {
	write __index: MigratorDatabase,
	write Template: SimpleDataRecord,
	
	newRecord: (self: MigratorDatabase) -> DataRecord,
	frozenTemplate: (self: MigratorDatabase) -> SimpleDataRecord,

	loadRecord: (self: MigratorDatabase, data: buffer) -> DataRecord,
	version: (self: MigratorDatabase) -> number,
	encodeRecord: (self: MigratorDatabase, record: DataRecord) -> buffer
}

type MigratorDatabaseBuilder = {
	write __index: MigratorDatabaseBuilder,
	write __extend: Named<(true | "clone")?>,
	write Parent: MigratorDatabaseBuilder?,
	write Value: any?,
	write Version: number?,
	write Migrator: Migrator?,
	
	templateRecord: (self: MigratorDatabaseBuilder, name: string) -> MigratorDatabaseBuilder,
	build: (self: MigratorDatabaseBuilder) -> MigratorDatabaseBuilder,
	
	withValue: (self: MigratorDatabaseBuilder, value: any) -> MigratorDatabaseBuilder,
	withVersion: (self: MigratorDatabaseBuilder, version: number) -> MigratorDatabaseBuilder,
	withMigrator: (self: MigratorDatabaseBuilder, fn: Migrator) -> MigratorDatabaseBuilder,
	
	toDatabase: (self: MigratorDatabaseBuilder) -> MigratorDatabase
}

type MigratorCreator = {
	databaseBuilder: () -> MigratorDatabaseBuilder
}

local dbBuilder: MigratorCreator = Creator.databaseBuilder

local dbBuilderMethods = dbBuilder().__index
local dbMethods = dbBuilder():toDatabase().__index

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
	:newRecord())

return Migrator
