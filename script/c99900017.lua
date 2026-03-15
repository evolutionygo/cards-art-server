-- Mechanic Nikke Maxwell (ID: 99900017)
local s,id=GetID()
local NIKKE_SET_ID = 0xc02
local FIELD_SPELL_ID = 99900016

function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- [Brute Force Xyz Procedure]
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(1165)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.xyzcon)
	e0:SetTarget(s.xyztg)
	e0:SetOperation(s.xyzop)
	e0:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e0)
	
	-- 1. Search Nikke Spell (Unchainable)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	-- 2. Power Overflow System
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.powercon)
	e2:SetValue(s.self_atk_val)
	c:RegisterEffect(e2)
	
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetCondition(s.powercon)
	e3:SetTarget(s.other_atk_filter)
	e3:SetValue(s.other_atk_val)
	c:RegisterEffect(e3)

	-- 3. Active Boost & Protection (Quick Effect)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCost(s.atkcost)
	e4:SetTarget(s.atktg)
	e4:SetOperation(s.atkop)
	c:RegisterEffect(e4,false,REGISTER_FLAG_DETACH_XMAT)
end

-- =======================================================================
-- [MANUAL XYZ LOGIC]
-- =======================================================================

-- [แก้ไขจุดนี้จุดเดียว] เพิ่มเงื่อนไข Race Machine
function s.xyzfilter(c,xyzc)
	return c:IsFaceup() and c:IsRace(RACE_MACHINE) and c:IsLevel(7) and c:IsCanBeXyzMaterial(xyzc)
end

function s.xyzcheck(g,tp,xyzc)
	return g:GetCount()==2
end
function s.xyzcon(e,c,og,min,max)
	if c==nil then return true end
	local tp=c:GetControler()
	local mg=nil
	if og then
		mg=og:Filter(s.xyzfilter,nil,c)
	else
		mg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil,c)
	end
	return mg:CheckSubGroup(s.xyzcheck,2,2,tp,c)
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk,c,og,min,max)
	if og and not min then return true end
	local mg=nil
	if og then
		mg=og:Filter(s.xyzfilter,nil,c)
	else
		mg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil,c)
	end
	local g=mg:SelectSubGroup(tp,s.xyzcheck,false,2,2,tp,c)
	if g and #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.xyzop(e,tp,eg,ep,ev,re,r,rp,c,og,min,max)
	local g=e:GetLabelObject()
	if not g then return end
	c:SetMaterial(g)
	Duel.Overlay(c,g)
	g:DeleteGroup()
end

-- =======================================================================
-- [EFFECT LOGIC] (ส่วนนี้เหมือนเดิม 100%)
-- =======================================================================

-- [Effect 1] Search
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.thfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetChainLimit(aux.FALSE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- [Effect 2] Power Calculation
function s.envfilter(c)
	return c:IsCode(FIELD_SPELL_ID) and c:IsFaceup()
end
function s.powercon(e)
	return Duel.IsExistingMatchingCard(s.envfilter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end
function s.get_material_atk(c)
	local g=c:GetOverlayGroup()
	local mat_atk=0
	for tc in aux.Next(g) do
		if tc:IsType(TYPE_MONSTER) and tc:GetTextAttack()>0 then 
			mat_atk=mat_atk+tc:GetTextAttack() 
		end
	end
	return mat_atk
end
function s.self_atk_val(e,c)
	local base_atk = c:GetTextAttack()
	local mat_atk = s.get_material_atk(c)
	local total = base_atk + mat_atk
	if total > 2500 then return 2500 - base_atk else return mat_atk end
end
function s.other_atk_filter(e,c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_XYZ) and c~=e:GetHandler()
end
function s.other_atk_val(e,c)
	local owner = e:GetHandler()
	local base_atk = owner:GetTextAttack()
	local mat_atk = s.get_material_atk(owner)
	local total = base_atk + mat_atk
	if total > 2500 then return total - 2500 else return 0 end
end

-- [Effect 3] Transfer DEF + Protection
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.atkfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsFaceup()
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.atkfilter(chkc) and chkc~=e:GetHandler() end
	if chk==0 then return Duel.IsExistingTarget(s.atkfilter,tp,LOCATION_MZONE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.atkfilter,tp,LOCATION_MZONE,0,1,1,e:GetHandler())
end

function s.efilter(e,re)
	return e:GetOwnerPlayer()~=re:GetOwnerPlayer()
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local def=c:GetDefense() 
		if def>0 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(def)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(3110)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e2:SetCode(EFFECT_IMMUNE_EFFECT)
		e2:SetValue(s.efilter)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		e2:SetOwnerPlayer(tp)
		tc:RegisterEffect(e2)

		local e3=e2:Clone()
		c:RegisterEffect(e3)
	end
end