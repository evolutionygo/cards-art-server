-- Tactical Nikke Emma
-- ID: 99900012
local s,id=GetID()
local TACTICAL_FLAG_ID = 99900009 
local COUNTER_TACTICAL = 0x1099

function s.initial_effect(c)
	c:EnableReviveLimit()
	c:EnableCounterPermit(COUNTER_TACTICAL)

	-- 1. On Summon: Place Counters & Heal
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetTarget(s.cttg_sum)
	e1:SetOperation(s.ctop_sum)
	c:RegisterEffect(e1)

	-- 2. Opponent Activates: Place Counter & Heal
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.ctcon_opp)
	e2:SetOperation(s.ctop_opp)
	c:RegisterEffect(e2)

	-- 3. Ignition Effects
	-- [A] Add to Hand (Cost 2)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCost(s.cost_add)
	e3:SetTarget(s.target_add)
	e3:SetOperation(s.op_add)
	c:RegisterEffect(e3)

	-- [B] Special Summon (Cost 3)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCost(s.cost_ss)
	e4:SetTarget(s.target_ss)
	e4:SetOperation(s.op_ss)
	c:RegisterEffect(e4)

	-- 4. Quick Effect: Negate S/T (Cost 2) - Field Only
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_NEGATE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.negcon)
	e5:SetCost(s.negcost)
	e5:SetTarget(s.negtg)
	e5:SetOperation(s.negop)
	c:RegisterEffect(e5)
end

-- ==================================================================
-- On Summon Logic
-- ==================================================================
function s.cttg_sum(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,nil,1,0,COUNTER_TACTICAL)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,300)
end
function s.ctop_sum(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local count = 2
		if Duel.GetFlagEffect(tp,TACTICAL_FLAG_ID) > 0 then
			count = 3
		end
		c:AddCounter(COUNTER_TACTICAL,count)
		Duel.Recover(tp,count*300,REASON_EFFECT)
	end
end

-- ==================================================================
-- Opponent Activates Logic
-- ==================================================================
function s.ctcon_opp(e,tp,eg,ep,ev,re,r,rp)
	local loc = re:GetActivateLocation()
	if rp==tp then return false end
	-- นับเฉพาะบนสนาม (S/T Zone, Field Zone, Monster Zone, Pendulum Zone)
	if (loc==LOCATION_SZONE or loc==LOCATION_MZONE or loc==LOCATION_FZONE or loc==LOCATION_PZONE) then
		return true
	end
	-- นับการ์ดเวท/กับดักที่ใช้จากมือ
	if loc==LOCATION_HAND and re:IsActiveType(TYPE_SPELL+TYPE_TRAP) then
		return true
	end
	return false
end
function s.ctop_opp(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsCanAddCounter(COUNTER_TACTICAL,1) then
		c:AddCounter(COUNTER_TACTICAL,1)
		Duel.Hint(HINT_CARD,0,id)
		Duel.Recover(tp,300,REASON_EFFECT)
	end
end

-- ==================================================================
-- Ignition Effects
-- ==================================================================
function s.nikke_filter_monster(c)
	return c:IsSetCard(0xc02) and c:IsType(TYPE_MONSTER)
end

-- [A] Add to Hand (Cost 2)
function s.cost_add(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,COUNTER_TACTICAL,2,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,COUNTER_TACTICAL,2,REASON_COST)
end
function s.filter_add(c)
	return c:IsSetCard(0xc02) and c:IsAbleToHand()
end
function s.target_add(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.filter_add(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter_add,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.filter_add,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.op_add(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end

-- [B] Special Summon (Cost 3)
function s.cost_ss(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,COUNTER_TACTICAL,3,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,COUNTER_TACTICAL,3,REASON_COST)
end
function s.filter_ss(c,e,tp)
	return s.nikke_filter_monster(c) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target_ss(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.filter_ss(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and Duel.IsExistingTarget(s.filter_ss,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.filter_ss,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.op_ss(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ==================================================================
-- Quick Effect: Negate S/T
-- ==================================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not re:IsActiveType(TYPE_SPELL+TYPE_TRAP) or not Duel.IsChainNegatable(ev) then return false end
	
	local loc = re:GetActivateLocation()
	-- เช็คตำแหน่ง: ต้องเป็นการ์ดที่ "อยู่บนสนาม" (S/T Zone, Field Zone) หรือใช้จากมือ
	return loc==LOCATION_SZONE or loc==LOCATION_FZONE or loc==LOCATION_PZONE or loc==LOCATION_HAND
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,COUNTER_TACTICAL,2,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,COUNTER_TACTICAL,2,REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateActivation(ev)
end