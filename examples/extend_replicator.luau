local Creator = require("../src")

type Creator<R = unknown> = Creator.Creator<unknown, unknown, R>
type Record<T = unknown> = Creator.Record<T>

type Replicator = (name: string, value: any)->()

type ReplicatorRecord = {
	withReplicator: (
		self: Record<ReplicatorRecord>,
		fn: Replicator
	) -> Record<ReplicatorRecord>
}
type ReplicatorCreator = Creator<ReplicatorRecord>

local builder = Creator.structBuilder

local recordMethods = builder():toStruct():newRecord().__index

-- Replicator -- Pass changes around
-- 
-- Record
--     withValue now calls replicator function
--     Add withReplicator((name: string, value: any)->())

local withValue = recordMethods.withValue

function recordMethods:withValue(value: any)
	local repl = self.Replicator
	if repl then
		repl("Value", value)
	end
	return withValue(self, value)
end
function recordMethods:withReplicator(fn: Replicator)
	self.Replicator = fn
	return self
end

return Creator :: ReplicatorCreator
