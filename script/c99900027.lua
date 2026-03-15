-- Burst: Trouble Shooter
-- ID: 99900027
local s,id=GetID()
local SUGAR_ID = 99900023
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_DECKDES+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.filter(c)
	return c:IsFaceup() and c:IsCode(SUGAR_ID)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
	if chk==0 then return #g>0 end
	
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
	
	-- ห้ามเชน (Unrespondable)
	if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
		Duel.SetChainLimit(s.chainlm)
	end
end

function s.chainlm(e,rp,tp)
	return tp==rp
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. Eradicate Logic: บังคับสับการ์ดทั้งหมดเข้าเด็ค (REASON_RULE)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
	local count = 0
	if #g>0 then
		count = Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_RULE)
	end

	-- 2. Compensation Draw: จั่วคืนใน Draw Phase ถัดไป
	if count > 0 then
		local e_draw=Effect.CreateEffect(c)
		e_draw:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e_draw:SetCode(EVENT_PHASE+PHASE_DRAW)
		e_draw:SetCountLimit(1)
		e_draw:SetLabel(count)
		e_draw:SetCondition(s.drawcon)
		e_draw:SetOperation(s.drawop)
		e_draw:SetReset(RESET_PHASE+PHASE_DRAW+RESET_OPPO_TURN)
		Duel.RegisterEffect(e_draw,tp)
	end

	-- 3. Lock GY & Banished
	local e_lock=Effect.CreateEffect(c)
	e_lock:SetType(EFFECT_TYPE_FIELD)
	e_lock:SetCode(EFFECT_CANNOT_ACTIVATE)
	e_lock:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e_lock:SetTargetRange(0,1)
	e_lock:SetValue(s.aclimit)
	e_lock:SetReset(RESET_PHASE+PHASE_END, 2)
	Duel.RegisterEffect(e_lock,tp)
	
	-- 4. No Battle Damage (เปลี่ยนเป็น 0 เลย)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_DAMAGE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,1) -- มีผลทั้งสองฝ่าย (ไม่มีใครเจ็บ)
	e1:SetValue(s.damval)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	-- 5. Nikke Buffs (Double Attack Only)
	-- เอา Indestructible ออก เหลือแค่ตี 2 ครั้ง
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetTargetRange(LOCATION_MZONE,0) 
	e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,NIKKE_SET_ID))
	e2:SetValue(1) -- เพิ่มจำนวนการโจมตีอีก 1 ครั้ง (รวมเป็น 2)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
	
	-- 6. Deck Mill on Attack
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_ATTACK_ANNOUNCE)
	e4:SetOperation(s.deckmill)
	e4:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e4,tp)
end

-- ฟังก์ชันเช็คว่าถึงเทิร์นฝ่ายตรงข้ามหรือยัง
function s.drawcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==1-tp
end

-- ฟังก์ชันสั่งจั่ว
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	local count=e:GetLabel()
	Duel.Hint(HINT_CARD,0,id)
	Duel.Draw(1-tp,count,REASON_EFFECT)
end

function s.aclimit(e,re,tp)
	local loc=re:GetActivateLocation()
	return loc==LOCATION_GRAVE or loc==LOCATION_REMOVED
end

-- แก้ไขให้ดาเมจเป็น 0
function s.damval(e,re,val,r,rp,rc)
	if (r&REASON_BATTLE)~=0 then return 0 else return val end
end

function s.deckmill(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetAttacker()
	if tc and tc:IsControler(tp) and tc:IsSetCard(NIKKE_SET_ID) then
		Duel.Hint(HINT_CARD,0,id)
		Duel.DiscardDeck(1-tp,2,REASON_EFFECT)
	end
end