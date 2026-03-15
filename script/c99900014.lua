-- Tactical Nikke Vesti
-- ID: 99900014
local s,id=GetID()
local ID_NIKKE = 0xc02

function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- 1. Search + Draw
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- 2. Auto Battle Buff (Damage Calculation Only)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.atktarget) -- แก้เป็นฟังก์ชันที่เราเขียนเอง
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)

	-- 3. Reactive Boost (Continuous)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.boostcon)
	e4:SetOperation(s.boostop)
	c:RegisterEffect(e4)
end

-- ==================================================================
-- 1. Search + Draw Logic
-- ==================================================================
function s.thfilter(c)
	return c:IsSetCard(ID_NIKKE) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	if Duel.GetFlagEffect(tp,99900009)>0 then
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
	end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)~=0 then
			Duel.ConfirmCards(1-tp,g)
			if Duel.GetFlagEffect(tp,99900009)>0 and Duel.IsPlayerCanDraw(tp,1) then
				Duel.BreakEffect()
				Duel.Draw(tp,1,REASON_EFFECT)
			end
		end
	end
end

-- ==================================================================
-- 2. Battle Buff Logic
-- ==================================================================
-- [FIX] เขียนฟังก์ชันเช็คเป้าหมายเอง แทน aux.TargetBoolFunction
function s.atktarget(e,c)
	return c:IsSetCard(ID_NIKKE)
end

function s.atkval(e,c)
	if Duel.GetCurrentPhase()~=PHASE_DAMAGE_CAL then return 0 end
	local attacker = Duel.GetAttacker()
	local bc = c:GetBattleTarget()
	if bc and attacker and attacker:IsControler(1-e:GetHandlerPlayer()) then
		local val = attacker:GetAttack()/2
		if val<0 then return 0 end
		return val
	end
	return 0
end

-- ==================================================================
-- 3. Reactive Boost Logic (Continuous)
-- ==================================================================
function s.boostcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return rp==1-tp and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
end

-- [FIX] สร้างฟังก์ชันกรองการ์ดแบบ Manual
function s.boostfilter(c)
	return c:IsFaceup() and c:IsSetCard(ID_NIKKE)
end

function s.boostop(e,tp,eg,ep,ev,re,r,rp)
	-- ใช้ s.boostfilter แทน aux.FaceupFilter
	local g=Duel.GetMatchingGroup(s.boostfilter,tp,LOCATION_MZONE,0,nil)
	if #g>0 then
		Duel.Hint(HINT_CARD,0,id) 
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(200)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
			
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UPDATE_DEFENSE)
			tc:RegisterEffect(e2)
		end
	end
end