-- Heretic Nikke Liberalio
-- ID: 99900045
local s,id=GetID()
local ID_NIKKE = 0xc02
local ID_HERETIC = 0xc20

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- 1. Ritual Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop)
	c:RegisterEffect(e1)

	-- 2. Stats
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	e3:SetValue(s.defval)
	c:RegisterEffect(e3)

	-- 3. Floodgate
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_ACTIVATE)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(0,1)
	e4:SetValue(s.aclimit)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_CANNOT_ACTIVATE) 
	c:RegisterEffect(e5)

	-- 4. Control: Variable Cost -> Rule Send -> Place as Spell
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,1))
	e9:SetCategory(CATEGORY_TOGRAVE)
	e9:SetType(EFFECT_TYPE_QUICK_O)
	e9:SetCode(EVENT_SPSUMMON_SUCCESS)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCountLimit(1,id)
	e9:SetCost(s.placecost)
	e9:SetTarget(s.placetg)
	e9:SetOperation(s.placeop)
	c:RegisterEffect(e9)

	-- 5. Anti-Response (Punishment) [FIXED: Non-Heretic Only]
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,3))
	e10:SetCategory(CATEGORY_REMOVE)
	e10:SetType(EFFECT_TYPE_QUICK_F)
	e10:SetCode(EVENT_CHAINING)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCountLimit(1,id+EFFECT_COUNT_CODE_CHAIN) -- Once per Chain
	e10:SetCondition(s.bancon)
	e10:SetTarget(s.bantg)
	e10:SetOperation(s.banop)
	c:RegisterEffect(e10)
end

-- ==================================================================
-- Logic 1: Ritual Summon
-- ==================================================================
function s.mat_filter(c)
	return (c:IsRace(RACE_MACHINE) or c:IsSetCard(ID_NIKKE)) and
		   ((c:IsLocation(LOCATION_GRAVE) and c:IsAbleToRemoveAsCost(POS_FACEDOWN)) or
			(c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end
function s.check_materials(sg)
	if #sg~=2 then return false end
	return sg:IsExists(Card.IsRace,1,nil,RACE_MACHINE) and sg:IsExists(Card.IsSetCard,1,nil,ID_NIKKE)
end
function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.mat_filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		return c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and mg:CheckSubGroup(s.check_materials,2,2)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=Duel.GetMatchingGroup(s.mat_filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local sg=mg:SelectSubGroup(tp,s.check_materials,false,2,2)
	if sg then
		c:SetMaterial(sg)
		local g_rem = sg:Filter(Card.IsLocation, nil, LOCATION_REMOVED)
		if #g_rem > 0 then Duel.SendtoGrave(g_rem, REASON_RULE+REASON_RETURN) end
		Duel.Remove(sg, POS_FACEDOWN, REASON_COST+REASON_MATERIAL+REASON_RITUAL)
		Duel.BreakEffect() 
		Duel.SpecialSummon(c,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
		c:CompleteProcedure()
	end
end

-- ==================================================================
-- Logic 2, 3 (Stats, Floodgate)
-- ==================================================================
function s.atkval(e,c)
	local count = Duel.GetMatchingGroupCount(Card.IsFacedown,0,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	return math.min(count * 300, 3300)
end
function s.defval(e,c)
	local count = Duel.GetMatchingGroupCount(Card.IsFacedown,0,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	return -math.min(count * 300, 3300)
end

function s.aclimit(e,re,tp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and not re:GetHandler():IsLocation(LOCATION_SZONE)
end
function s.aclimit2(e,re,tp)
	local c=re:GetHandler()
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and c:GetTurnID()==Duel.GetTurnCount() and not c:IsType(TYPE_MONSTER)
end

-- ==================================================================
-- Logic 4: Variable Cost (Fixed to Main S/T Zones only)
-- ==================================================================

-- Filter: เลือกเฉพาะการ์ดที่รีมูฟคว่ำได้ AND อยู่ในโซนหลัก (0-4)
function s.cost_rem_filter(c)
	return c:IsAbleToRemoveAsCost(POS_FACEDOWN) and c:GetSequence()<5
end

function s.placecost(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft = Duel.GetLocationCount(1-tp, LOCATION_SZONE)
	
	local b1 = ft > 0 and Duel.IsExistingMatchingCard(Card.IsAbleToGraveAsCost,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
	local b2 = ft <= 0 and Duel.IsExistingMatchingCard(s.cost_rem_filter,tp,0,LOCATION_SZONE,1,nil)

	if chk==0 then return b1 or b2 end

	if ft > 0 then
		-- Case Available: Cost = Dump Deck
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToGraveAsCost,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
		Duel.SendtoGrave(g,REASON_COST)
	else
		-- Case Full: Cost = Banish Opponent's Main S/T
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,s.cost_rem_filter,tp,0,LOCATION_SZONE,1,1,nil)
		Duel.Remove(g,POS_FACEDOWN,REASON_COST)
	end
end

function s.placefilter(c,tp)
	return c:IsControler(1-tp) and c:IsLocation(LOCATION_MZONE)
end

function s.placetg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=eg:Filter(s.placefilter,nil,tp)
	if chk==0 then return #g>0 end
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,0,0)
end

function s.placeop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	local sg=g:Filter(Card.IsRelateToEffect,nil,e)
	
	local ft=Duel.GetLocationCount(1-tp,LOCATION_SZONE)
	if #sg==0 or ft<=0 then return end
	
	if #sg > ft then
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2)) -- String: Select monster
		sg=sg:Select(tp,ft,ft,nil)
	end
	
	for tc in aux.Next(sg) do
		if Duel.SendtoGrave(tc, REASON_RULE) > 0 and tc:IsLocation(LOCATION_GRAVE) then
			if Duel.MoveToField(tc,tp,1-tp,LOCATION_SZONE,POS_FACEUP,true) then
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetCode(EFFECT_CHANGE_TYPE)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
				e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
				tc:RegisterEffect(e1)
			end
		end
	end
	Duel.Readjust()
end

-- ==================================================================
-- Logic 5: Anti-Response (Prevent Heretic Loop)
-- ==================================================================
function s.bancon(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Response check
	if ev<2 then return false end
	local pe=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_EFFECT)
	if not pe or pe:GetHandler()~=e:GetHandler() then return false end

	-- 2. Non-Heretic check
	local rc=re:GetHandler()
	if rc:IsSetCard(ID_HERETIC) then return false end

	return true
end

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local rc=re:GetHandler()
	Duel.SetTargetCard(rc)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,rc,1,0,0)
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
	end
end