-- Heretic Nikke Modernia
-- ID: 99900030
local s,id=GetID()
local ID_MARIAN = 99900008
local NIKKE_SET_ID = 0xc02
local HERETIC_SET_ID = 0xc20

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- 1. Ritual Summon Procedure
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
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

	-- 3. Immunity (Spell/Trap)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetValue(s.indval)
	c:RegisterEffect(e4)

	-- 4. Recycle Counter Trap
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetTarget(s.settg)
	e5:SetOperation(s.setop)
	c:RegisterEffect(e5)

	-- 5. Anti-Chain (Punishment) - Fixed Loop
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_REMOVE)
	e6:SetType(EFFECT_TYPE_QUICK_F) -- บังคับทำงาน (Mandatory) ตาม Text "If... : Banish it"
	e6:SetCode(EVENT_CHAINING)
	e6:SetRange(LOCATION_MZONE)
	-- Once per Chain logic
	e6:SetCountLimit(1,id+EFFECT_COUNT_CODE_CHAIN)
	e6:SetCondition(s.bancon)
	e6:SetTarget(s.bantg)
	e6:SetOperation(s.banop)
	c:RegisterEffect(e6)
end

-- ==================================================================
-- Ritual Summon Logic
-- ==================================================================
function s.mat_filter(c)
	if not c:IsSetCard(NIKKE_SET_ID) then return false end
	if c:IsLocation(LOCATION_GRAVE) then
		return c:IsAbleToRemoveAsCost(POS_FACEDOWN)
	elseif c:IsLocation(LOCATION_REMOVED) then
		return c:IsFaceup()
	end
	return false
end

function s.check_materials(sg)
	if #sg~=2 then return false end
	return sg:IsExists(Card.IsCode,1,nil,ID_MARIAN)
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
		local g_gy = sg:Filter(Card.IsLocation, nil, LOCATION_GRAVE)
		local g_rem = sg:Filter(Card.IsLocation, nil, LOCATION_REMOVED)
		
		if #g_gy > 0 then
			Duel.Remove(g_gy, POS_FACEDOWN, REASON_COST+REASON_MATERIAL+REASON_RITUAL)
		end
		if #g_rem > 0 then
			Duel.SendtoGrave(g_rem, REASON_RULE+REASON_RETURN)
			Duel.Remove(g_rem, POS_FACEDOWN, REASON_COST+REASON_MATERIAL+REASON_RITUAL)
		end
		
		Duel.BreakEffect() 
		Duel.SpecialSummon(c,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
		c:CompleteProcedure()
	end
end

-- ==================================================================
-- Other Logics
-- ==================================================================
function s.atkval(e,c)
	local count = Duel.GetMatchingGroupCount(Card.IsFacedown,0,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	local bonus = count * 300
	if bonus > 3300 then bonus = 3300 end
	return bonus
end

function s.defval(e,c)
	local count = Duel.GetMatchingGroupCount(Card.IsFacedown,0,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	local bonus = count * 300
	if bonus > 3300 then bonus = 3300 end
	return -bonus
end

function s.indval(e,re,rp)
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end

function s.setfilter(c)
	return (c:IsSetCard(NIKKE_SET_ID) or c:IsSetCard(HERETIC_SET_ID)) 
		and c:IsType(TYPE_TRAP) and c:IsType(TYPE_COUNTER) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.SSet(tp,tc)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

-- [FIXED] Anti-Chain Logic: Prevent Heretic Loop
function s.bancon(e,tp,eg,ep,ev,re,r,rp)
	-- 1. เช็คว่าเป็น Chain Link ถัดไปจากการ์ดใบนี้หรือไม่ (Response check)
	if ev<2 then return false end
	local pe=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_EFFECT)
	if not pe or pe:GetHandler()~=e:GetHandler() then return false end

	-- 2. [NEW] การ์ดที่เชนมา ต้อง "ไม่ใช่" Heretic (non-Heretic)
	local rc=re:GetHandler()
	if rc:IsSetCard(HERETIC_SET_ID) then return false end

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