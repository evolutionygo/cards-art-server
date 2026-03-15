-- Heretic Nikke Indivilia
-- ID: 99900044
local s,id=GetID()
local ID_NIKKE = 0xc02
local ID_HERETIC = 0xc20

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- 1. Ritual Summon Procedure
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop)
	c:RegisterEffect(e1)

	-- 2. Stats (ATK/DEF)
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

	-- 3. Piercing Damage
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e4)

	-- 4. Negate & Banish (Negate -> Random Banish Hand/GY)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id)
	e5:SetCondition(s.negcon)
	e5:SetTarget(s.negtg)
	e5:SetOperation(s.negop)
	c:RegisterEffect(e5)

	-- 5. Anti-Response (Punishment: Non-Heretic Only)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,2))
	e6:SetCategory(CATEGORY_REMOVE)
	e6:SetType(EFFECT_TYPE_QUICK_F)
	e6:SetCode(EVENT_CHAINING)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1,id+EFFECT_COUNT_CODE_CHAIN)
	e6:SetCondition(s.bancon)
	e6:SetTarget(s.bantg)
	e6:SetOperation(s.banop)
	c:RegisterEffect(e6)
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
-- Logic 2: Stats
-- ==================================================================
function s.atkval(e,c)
	local count = Duel.GetMatchingGroupCount(Card.IsFacedown,0,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	return math.min(count * 300, 3000)
end
function s.defval(e,c)
	local count = Duel.GetMatchingGroupCount(Card.IsFacedown,0,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	return -math.min(count * 300, 3000)
end

-- ==================================================================
-- Logic 4: Negate & Random Banish Hand/GY (Updated)
-- ==================================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Negate Activation first
	if Duel.NegateActivation(ev) then
		-- 2. Random Banish from Hand/GY
		local g_hand = Duel.GetFieldGroup(tp,0,LOCATION_HAND)
		local g_gy = Duel.GetFieldGroup(tp,0,LOCATION_GRAVE)
		g_hand:Merge(g_gy) -- Combine Hand and GY
		
		if #g_hand > 0 then
			-- Random Select 1
			local sg = g_hand:RandomSelect(tp,1)
			-- Banish Face-down
			Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)
		end
	end
end

-- ==================================================================
-- Logic 5: Anti-Response
-- ==================================================================
function s.bancon(e,tp,eg,ep,ev,re,r,rp)
	if ev<2 then return false end
	local pe=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_EFFECT)
	if not pe or pe:GetHandler()~=e:GetHandler() then return false end
	
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