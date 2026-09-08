Doubles item interface v1

Keep exports.doubles.version == 1. Additive capabilities are snapshot.itemApiVersion == 1 and snapshot.limitations.bag == true.

snapshot.items lists usable item families currently in inventory:
{id, name, count, available, target = "party" or "active-player", moveRequired = boolean}
count is actual inventory; available subtracts items reserved by already selected partner commands. The UI must not mutate either count or save.inventory.

snapshot.party retains existing identities and adds moves:
{index, id, name, pp, maxPP}. Party index is the actual save party index, not the displayed cell index. Active and benched party members are valid medicine/PP targets; battle stat items require an active player Pokemon. Eggs and invalid/no-effect targets are rejected by native effect checks.

Submit via exports.doubles.submit:
{battleId=snapshot.battleId, ticket=snapshot.ticket, turn=snapshot.turn,
 slot=snapshot.commandSlot, battlerId=snapshot.battlerId, kind="item",
 item="POTION", partyIndex=2}
For Ether/Max Ether/Mysteryberry also include moveIndex (one-based move slot).

A successful submit reserves an action, not an immediate effect. The partner still chooses its own action. Each item consumes one actor's action, resolves before switches/moves, and decrements stock only on successful use. Two items may be selected if enough inventory remains. Existing kind="cancel" cancels the prior command and releases its reservation. Stale requests, invalid targets and unavailable stock return false, reason. Execution rechecks stock and target and retains an item that no longer has an effect. PP is not spent by item actions.

Trainer capture balls, escape items, field/key items, TMs, evolution items and permanent stat/PP boosters are excluded. This build's doubles encounters are trainer battles. Trainer AI item selection is unchanged.

The included DoublesUI.lua patch wires Bag -> item -> Pokemon -> optional PP move without calling native BagMenu or starting a second singles turn. If you have UI work newer than 2.4.0-doubles-test.3, merge the provided UI patch rather than replacing that work with the companion test ZIP.
