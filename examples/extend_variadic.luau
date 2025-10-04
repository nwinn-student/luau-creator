local Creator = require("../src")

type Creator<R = unknown> = Creator.Creator<unknown, unknown, R>
type Record<T = unknown> = Creator.Record<T>

type VariadicRecord = {
	withRecord: (
		self: Record<VariadicRecord>,
		name: string
	) -> Record<VariadicRecord>
}
type VariadicCreator = Creator<VariadicRecord>

local builder = Creator.structBuilder

local recordMethods = builder():toStruct():newRecord().__index


-- Variadic
-- Record
--     withRecord(name: string)

local baseStruct = Creator.structBuilder():toStruct()

function recordMethods:withRecord(name: string)
	self[name] = baseStruct:newRecord()
	return self
end

return Creator :: VariadicCreator
