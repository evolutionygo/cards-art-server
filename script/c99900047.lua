-- Heretic's Fatal Parry
-- ID: 99900047
local s,id=GetID()
local ID_HERETIC = 0xc20

function s.initial_effect(c)
	-- 1. Battle Phase Logic (Opponent's Turn)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.condition_atk)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_CHAINING)
	e2:SetCondition(s.condition_eff)
	c:RegisterEffect(e2)

	-- [System] เช็คว่าถูกเซ็ทมาจากสุสานหรือไม่ (ทำงานเบื้องหลัง)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_MOVE)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetOperation(s.regop)
	c:RegisterEffect(e3)

	-- 2. Ignition Effect: กดใช้ได้เมื่อการ์ดถูกเซ็ทจากสุสานในเทิร์นนี้
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_IGNITION) -- กดใช้เอง (ความเร็ว 1)
	e4:SetRange(LOCATION_SZONE)
	-- สำคัญมาก! SET_AVAILABLE ทำให้กดใช้ได้ทั้งที่คว่ำอยู่
	e4:SetProperty(EFFECT_FLAG_SET_AVAILABLE) 
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.ign_con)
	e4:SetCost(s.ign_cost) -- Reveal Cost
	e4:SetTarget(s.ign_tg)
	e4:SetOperation(s.ign_op)
	c:RegisterEffect(e4)
end

-- ==================================================================
-- Logic 1: Battle Phase (เหมือนเดิม)
-- ==================================================================
function s.condition_atk(e,tp,eg,ep,ev,re,r,rp)
	return tp~=Duel.GetTurnPlayer()
end

function s.condition_eff(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	local is_bp = ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
	return is_bp and tp~=Duel.GetTurnPlayer() and rp==1-tp
end

function s.filter(c)
	return c:IsFaceup() and c:IsSetCard(ID_HERETIC)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
	local tc=g:GetFirst()
	local dmg=tc:GetBaseAttack()
	if dmg<0 then dmg=0 end
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,tp,dmg)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local c=e:GetHandler()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local dmg=tc:GetBaseAttack()
		if dmg<0 then dmg=0 end
		if Duel.Damage(tp,dmg,REASON_EFFECT)~=0 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)

			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_SET_ATTACK_FINAL)
			e2:SetValue(0)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE)
			tc:RegisterEffect(e2)
			
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_FIELD)
			e3:SetCode(EFFECT_MUST_ATTACK)
			e3:SetTargetRange(0,LOCATION_MZONE)
			e3:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e3,tp)
			
			local e4=Effect.CreateEffect(c)
			e4:SetType(EFFECT_TYPE_FIELD)
			e4:SetCode(EFFECT_REFLECT_BATTLE_DAMAGE)
			e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e4:SetTargetRange(1,0)
			e4:SetValue(1)
			e4:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e4,tp)
		end
	end
end

-- ==================================================================
-- Logic 2: Flag Register (ทำงานเบื้องหลัง)
-- ==================================================================
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- ถ้าการ์ดใบนี้ย้ายมา "คว่ำ" บนสนาม และ "มาจากสุสาน"
	if c:IsLocation(LOCATION_SZONE) and c:IsFacedown() and c:IsPreviousLocation(LOCATION_GRAVE) then
		-- ฝัง Flag ไว้ 1 เทิร์น (Flag ID = id)
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
	end
end

-- ==================================================================
-- Logic 3: Ignition Effect (Manual Activation)
-- ==================================================================
function s.ign_con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- ทำงานได้ต่อเมื่อ: คว่ำอยู่ + มี Flag ที่ฝังไว้
	return c:IsFacedown() and c:GetFlagEffect(id)>0
end

function s.ign_cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- Reveal Cost
	Duel.ConfirmCards(1-tp,e:GetHandler())
end

function s.ign_filter(c)
	return c:IsSetCard(ID_HERETIC) and c:IsType(TYPE_TRAP) and c:IsSSetable()
end

function s.ign_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ign_filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
end

function s.ign_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.ign_filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		local tc=g:GetFirst()
		if Duel.SSet(tp,tc)>0 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
			e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
end