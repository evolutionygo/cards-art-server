-- Burst: Asceticism
-- ID: 99900040
local s,id=GetID()
local ID_PIONEER = 99900039 -- Pioneer Nikke Nayuta
local ID_WU_WEI = 99900041  -- Nikke Nayuta: Wu Wei

function s.initial_effect(c)
	-- Activate Condition
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.actcon)
	c:RegisterEffect(e1)

	-- 1. Global Protection for Pioneer Nikke Nayuta
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.pioneer_filter)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	
	local e3=e2:Clone()
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e3)
	
	local e4=e2:Clone()
	e4:SetCode(EFFECT_CANNOT_ATTACK)
	c:RegisterEffect(e4)
	
	local e5=e2:Clone()
	e5:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	c:RegisterEffect(e5)
	local e6=e2:Clone()
	e6:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	c:RegisterEffect(e6)
	local e7=e2:Clone()
	e7:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e7)
	local e8=e2:Clone()
	e8:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	c:RegisterEffect(e8)

	local e9=e2:Clone()
	e9:SetCode(EFFECT_UNRELEASABLE_SUMMON)
	e9:SetValue(1)
	c:RegisterEffect(e9)
	local e10=e2:Clone()
	e10:SetCode(EFFECT_UNRELEASABLE_NONSUMMON)
	e10:SetValue(1)
	c:RegisterEffect(e10)

	-- 2. Awakening at Dawn (Quick-like Effect during Standby Phase)
	-- TRIGGER_O (เลือกกดได้)
	local e11=Effect.CreateEffect(c)
	e11:SetDescription(aux.Stringid(id,1))
	e11:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e11:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O) 
	e11:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e11:SetRange(LOCATION_SZONE)
	e11:SetCondition(s.spcon)
	e11:SetCost(s.spcost)
	e11:SetTarget(s.sptg)
	e11:SetOperation(s.spop)
	c:RegisterEffect(e11)

	-- 3. Self-Immunity to Negation
	local e12=Effect.CreateEffect(c)
	e12:SetType(EFFECT_TYPE_SINGLE)
	e12:SetCode(EFFECT_IMMUNE_EFFECT)
	e12:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e12:SetRange(LOCATION_SZONE)
	e12:SetValue(s.negate_immune_filter)
	c:RegisterEffect(e12)
end

-- ==================================================================
-- [Logic] Activation & Protection
-- ==================================================================
-- [FIX] สร้างฟังก์ชันเช็ค Face-up เอง แทนการใช้ aux.FaceupFilter
function s.pioneer_check(c)
	return c:IsFaceup() and c:IsCode(ID_PIONEER)
end

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	-- เรียกใช้ฟังก์ชันด้านบน
	return Duel.IsExistingMatchingCard(s.pioneer_check,tp,LOCATION_MZONE,0,1,nil)
end

function s.pioneer_filter(e,c)
	return c:IsCode(ID_PIONEER)
end

function s.negate_immune_filter(e,te)
	if (te:GetType() & EFFECT_TYPE_ACTIONS) ~= 0 then
		local cat = te:GetCategory()
		return (cat & CATEGORY_DISABLE)~=0 or (cat & CATEGORY_NEGATE)~=0
	end
	local ec = te:GetCode()
	return ec==EFFECT_DISABLE or ec==EFFECT_DISABLE_EFFECT or ec==EFFECT_DISABLE_CHAIN
end

-- ==================================================================
-- [Logic] Awakening at Dawn (Standby Phase)
-- ==================================================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- Standby Phase ของฝ่ายใดก็ได้
	return true 
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return c:IsAbleToGraveAsCost() 
		and Duel.IsExistingMatchingCard(s.pioneer_cost_filter,tp,LOCATION_MZONE,0,1,nil)
	end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.pioneer_cost_filter,tp,LOCATION_MZONE,0,1,1,nil)
	
	local g_cost = Group.FromCards(c)
	g_cost:Merge(g)
	
	Duel.SendtoGrave(g_cost,REASON_COST)
end

function s.pioneer_cost_filter(c)
	return c:IsCode(ID_PIONEER) and c:IsFaceup() and c:IsAbleToGraveAsCost()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetChainLimit(aux.FALSE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Clean Field (Shuffle Others)
	local g_others = Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
	if #g_others > 0 then
		Duel.SendtoDeck(g_others,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		Duel.BreakEffect() 
	end
	
	-- 2. Summon Wu Wei
	if Duel.GetLocationCountFromEx(tp)<=0 then return end
	
	-- Over Deck Logic
	local tc = Duel.GetFirstMatchingCard(function(c) return c:IsCode(ID_WU_WEI) and c:IsCanBeSpecialSummoned(e,0,tp,true,false) end, tp, LOCATION_EXTRA, 0, nil)
	
	if not tc then
		tc = Duel.CreateToken(tp, ID_WU_WEI)
	end
	
	if tc then
		Duel.SpecialSummon(tc, 0, tp, tp, true, false, POS_FACEUP)
		tc:CompleteProcedure()
	end
end