-- Heretic Corruption
-- ID: 99900029
local s,id=GetID()
local HERETIC_SET_ID = 0xc20
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- 1. Search Effect (From Hand or Set on Field)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_SZONE)
	e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- 2. Counter Trap Activation
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_CONTROL+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCost(s.actcost)
	e2:SetCondition(s.actcon_chain)
	e2:SetTarget(s.acttg)
	e2:SetOperation(s.actop)
	c:RegisterEffect(e2)
	
	local e3=e2:Clone()
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCondition(s.actcon_sum)
	c:RegisterEffect(e3)
	local e4=e2:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
	local e5=e2:Clone()
	e5:SetCode(EVENT_ATTACK_ANNOUNCE)
	e5:SetCondition(s.actcon_atk)
	c:RegisterEffect(e5)
end

-- ==================================================================
-- Effect 1: Search
-- ==================================================================
function s.heretic_check(c)
	return c:IsSetCard(HERETIC_SET_ID) and c:IsType(TYPE_MONSTER)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsLocation(LOCATION_SZONE) and not c:IsFacedown() then return false end
	local g_hand = Duel.GetMatchingGroup(s.heretic_check,tp,LOCATION_HAND,0,nil)
	local g_field = Duel.GetMatchingGroup(s.heretic_check,tp,LOCATION_MZONE,0,nil)
	return #g_hand==0 and #g_field==0
end

function s.costfilter(c)
	return c:IsSetCard(NIKKE_SET_ID) and not c:IsSetCard(HERETIC_SET_ID) 
		and c:IsType(TYPE_MONSTER) and c:IsAbleToGraveAsCost()
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
	if not c:IsPublic() then Duel.ConfirmCards(1-tp,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.thfilter(c)
	return c:IsSetCard(HERETIC_SET_ID) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ==================================================================
-- Effect 2: Activate & Control (Unique Target per Chain)
-- ==================================================================
function s.condition_filter(c)
	return (c:IsSetCard(NIKKE_SET_ID) or c:IsSetCard(HERETIC_SET_ID)) 
	   and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
end

function s.has_required_card(tp,c)
	return Duel.IsExistingMatchingCard(s.condition_filter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,c)
end

function s.actcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,800) end
	Duel.PayLPCost(tp,800)
end
function s.actcon_chain(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER) and s.has_required_card(tp,e:GetHandler())
end
function s.actcon_sum(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp and s.has_required_card(tp,e:GetHandler())
end
function s.actcon_atk(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetAttacker():IsControler(1-tp) and s.has_required_card(tp,e:GetHandler())
end

-- [แก้ไข] ใช้ GetFlagEffect == 0 แทน HasFlagEffect
function s.ctrl_filter(c)
	return c:IsControlerCanBeChanged() and c:GetFlagEffect(id)==0
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and s.ctrl_filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.ctrl_filter,tp,0,LOCATION_MZONE,1,nil) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp,s.ctrl_filter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
	
	-- Register Flag
	local tc=g:GetFirst()
	if tc then
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_CHAIN,0,1)
	end
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.GetControl(tc,tp) then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
			
			local e3=e1:Clone()
			e3:SetCode(EFFECT_CHANGE_RACE)
			e3:SetValue(RACE_MACHINE)
			tc:RegisterEffect(e3)

			local e4=Effect.CreateEffect(e:GetHandler())
			e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e4:SetCode(EVENT_PHASE+PHASE_END)
			e4:SetCountLimit(1)
			e4:SetCondition(s.auto_ban_con)
			e4:SetOperation(s.auto_ban_op)
			e4:SetLabel(Duel.GetTurnCount())
			e4:SetLabelObject(tc)
			Duel.RegisterEffect(e4,tp)
		end
	end
end

function s.auto_ban_con(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if Duel.GetTurnCount() > e:GetLabel() then
		if tc and tc:IsLocation(LOCATION_MZONE) then
			return true
		else
			e:Reset()
			return false
		end
	end
	return false
end

function s.auto_ban_op(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.Hint(HINT_CARD,0,id)
	Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
	e:Reset()
end