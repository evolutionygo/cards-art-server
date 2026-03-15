-- Nikke ENCOUNTER!
-- ID: 99900003
local s,id=GetID()
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- 1. [Start Battle Phase] Force Opponent to Bounce Face-up S/T
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS) 
	e1:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCondition(s.bounce_con)
	e1:SetOperation(s.bounce_op)
	c:RegisterEffect(e1)

	-- 2. [Battle Phase] Immunity & Debuff (-400)
	-- 2.1 Immunity
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetCondition(s.battle_con)
	e2:SetTarget(s.prot_tg)
	e2:SetValue(s.immune_val)
	c:RegisterEffect(e2)

	-- 2.2 Debuff (-400)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetCondition(s.battle_con)
	e3:SetValue(-400)
	c:RegisterEffect(e3)

	-- 3. Send to GY -> Buff ATK (+400)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCost(s.atkcost)
	e4:SetOperation(s.atkop)
	c:RegisterEffect(e4)

	-- 4. GY Banish -> Retrieve Nikke
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_TOHAND)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_GRAVE)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetCost(aux.bfgcost)
	e5:SetTarget(s.thtg)
	e5:SetOperation(s.thop)
	c:RegisterEffect(e5)
end

-- ==================================================================
-- Logic Functions
-- ==================================================================

-- 1. Force Bounce Logic (ทะลุเกราะอมตะ)
function s.nikke_check(c) return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID) end

function s.bounce_con(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.nikke_check, tp, LOCATION_MZONE, 0, 1, nil)
end

function s.bounce_op(e,tp,eg,ep,ev,re,r,rp)
	-- หาการ์ดหงายหน้าในโซน S/T และ Field Zone ของอีกฝ่าย
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_SZONE+LOCATION_FZONE,nil)
	if #g>0 then
		Duel.Hint(HINT_CARD,0,id)
		-- สั่งว่า "นี่คือกฎเกม ไม่ใช่เอฟเฟคการ์ด" ทำให้เด้งทะลุกันขึ้นมือได้ด้วย
		Duel.SendtoHand(g,nil,REASON_RULE)
	end
end

-- 2. Battle Phase Logic
function s.battle_con(e)
	local tp=e:GetHandlerPlayer()
	local ph=Duel.GetCurrentPhase()
	if not (ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE) then return false end
	return Duel.IsExistingMatchingCard(s.nikke_check, tp, LOCATION_MZONE, 0, 1, nil)
end

-- Immunity Filter
function s.prot_tg(e,c) return c:IsSetCard(NIKKE_SET_ID) end
function s.immune_val(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer() 
		and te:IsActiveType(TYPE_SPELL+TYPE_TRAP)
		and not te:GetHandler():IsSetCard(NIKKE_SET_ID)
end

-- 3. & 4. Buff & Retrieve
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToGraveAsCost() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST)
end
function s.buff_filter(c) return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID) end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.buff_filter,tp,LOCATION_MZONE,0,nil)
	if #g>0 then
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(400)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
	end
end

function s.thfilter(c) return c:IsSetCard(NIKKE_SET_ID) and c:IsAbleToHand() end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end