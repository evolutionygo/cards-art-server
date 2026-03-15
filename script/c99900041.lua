-- Nikke Nayuta: Wu Wei
-- ID: 99900041
local s,id=GetID()
local ID_BURST = 99900040 -- Burst: Asceticism
local ID_NIKKE = 0xc02	-- Set code for Nikke

function s.initial_effect(c)
	-- Link / Pendulum Setup
	c:EnableReviveLimit()
	aux.EnablePendulumAttribute(c,false)

	-- ==================================================================
	-- [PENDULUM EFFECTS]
	-- ==================================================================
	-- 1. No Battle Damage (Continuous)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e1:SetRange(LOCATION_PZONE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- 2. Attack Declaration -> Opponent Draw (Continuous)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetRange(LOCATION_PZONE)
	e2:SetOperation(s.pen_attack_draw_op)
	c:RegisterEffect(e2)
	
	-- 3. Direct Attack Hit -> Take 900 Damage (Continuous)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_DAMAGE_STEP_END)
	e3:SetRange(LOCATION_PZONE)
	e3:SetCondition(s.pen_damage_con)
	e3:SetOperation(s.pen_damage_op)
	c:RegisterEffect(e3)

	-- 4. Effect Resolves -> Opponent Draw 1 (Continuous)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_CHAIN_SOLVED)
	e4:SetRange(LOCATION_PZONE)
	e4:SetCondition(s.pen_resol_con)
	e4:SetOperation(s.pen_resol_op)
	c:RegisterEffect(e4)

	-- 5. Return to M-Zone (End Phase Trigger) 
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetRange(LOCATION_PZONE)
	e5:SetCountLimit(1)
	e5:SetTarget(s.return_tg)
	e5:SetOperation(s.return_op)
	c:RegisterEffect(e5)

	-- 6. Immunity to Negation (P-Zone Only)
	-- กันโดนเนเกจเอฟเฟคขณะอยู่ในโซน Pendulum (Absolute Immunity)
	local e_immune=Effect.CreateEffect(c)
	e_immune:SetType(EFFECT_TYPE_SINGLE)
	e_immune:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e_immune:SetRange(LOCATION_PZONE)
	e_immune:SetCode(EFFECT_IMMUNE_EFFECT)
	e_immune:SetValue(s.negate_immune_filter)
	c:RegisterEffect(e_immune)

	-- 7. Summon Limit (Continuous)
	local e_plimit1 = Effect.CreateEffect(c)
	e_plimit1:SetType(EFFECT_TYPE_FIELD)
	e_plimit1:SetRange(LOCATION_PZONE)
	e_plimit1:SetCode(EFFECT_CANNOT_SUMMON)
	e_plimit1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e_plimit1:SetTargetRange(1,0)
	e_plimit1:SetTarget(s.sumlimit)
	c:RegisterEffect(e_plimit1)
	local e_plimit2 = e_plimit1:Clone()
	e_plimit2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	c:RegisterEffect(e_plimit2)
	local e_plimit3 = e_plimit1:Clone()
	e_plimit3:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	c:RegisterEffect(e_plimit3)
	local e_plimit4 = e_plimit1:Clone()
	e_plimit4:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e_plimit4)

	-- 8. Pendulum Redirect (Continuous)
	local e_predirect = Effect.CreateEffect(c)
	e_predirect:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e_predirect:SetCode(EVENT_LEAVE_FIELD_P)
	e_predirect:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e_predirect:SetOperation(s.ed_return_op)
	c:RegisterEffect(e_predirect)

	-- ==================================================================
	-- [MONSTER EFFECTS]
	-- ==================================================================
	-- 1. Summon Condition
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e6:SetCode(EFFECT_SPSUMMON_CONDITION)
	e6:SetValue(s.splimit)
	c:RegisterEffect(e6)

	-- 2. Immunities & Floodgate
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetCode(EFFECT_IMMUNE_EFFECT)
	e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e7:SetRange(LOCATION_MZONE)
	e7:SetValue(s.efilter)
	c:RegisterEffect(e7)
	
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE)
	e8:SetCode(EFFECT_CANNOT_ATTACK)
	c:RegisterEffect(e8)
	
	local e9=Effect.CreateEffect(c)
	e9:SetType(EFFECT_TYPE_FIELD)
	e9:SetCode(EFFECT_CANNOT_TO_DECK)
	e9:SetRange(LOCATION_MZONE)
	e9:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e9:SetTargetRange(0,1)
	c:RegisterEffect(e9)

	-- 3. Summon Limit (Monster Zone)
	local e_limit1 = Effect.CreateEffect(c)
	e_limit1:SetType(EFFECT_TYPE_FIELD)
	e_limit1:SetRange(LOCATION_MZONE)
	e_limit1:SetCode(EFFECT_CANNOT_SUMMON)
	e_limit1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e_limit1:SetTargetRange(1,0)
	e_limit1:SetTarget(s.sumlimit)
	c:RegisterEffect(e_limit1)
	local e_limit2 = e_limit1:Clone()
	e_limit2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	c:RegisterEffect(e_limit2)
	local e_limit3 = e_limit1:Clone()
	e_limit3:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	c:RegisterEffect(e_limit3)
	local e_limit4 = e_limit1:Clone()
	e_limit4:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e_limit4)

	-- 4. Reality Override (Continuous)
	local e10=Effect.CreateEffect(c)
	e10:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e10:SetCode(EVENT_CHAINING)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCondition(s.override_con)
	e10:SetOperation(s.override_op)
	c:RegisterEffect(e10)

	-- 5. Enter Battle Phase -> Move to PZone
	local e11=Effect.CreateEffect(c)
	e11:SetDescription(aux.Stringid(id,3))
	e11:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e11:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e11:SetRange(LOCATION_MZONE)
	e11:SetOperation(s.to_pzone_op)
	c:RegisterEffect(e11)

	-- 6. Rebirth Logic (Monster Zone Redirect)
	local e12=Effect.CreateEffect(c)
	e12:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e12:SetCode(EVENT_LEAVE_FIELD_P)
	e12:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e12:SetOperation(s.ed_return_op)
	c:RegisterEffect(e12)
	
	-- 7. Standby Respawn
	local e13=Effect.CreateEffect(c)
	e13:SetDescription(aux.Stringid(id,1))
	e13:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DECKDES)
	e13:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e13:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e13:SetRange(LOCATION_EXTRA)
	e13:SetCondition(s.respawn_con)
	e13:SetCost(s.respawn_cost)
	e13:SetTarget(s.respawn_tg)
	e13:SetOperation(s.respawn_op)
	c:RegisterEffect(e13)
end

-- ==================================================================
-- [Shared Logic]
-- ==================================================================
function s.sumlimit(e,c,sump,sumtype,sumpos,targetp)
	return c ~= e:GetHandler()
end

function s.ed_return_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- ถ้าตายจากการต่อสู้ (ปกติไม่ควรเกิดเพราะกันดาเมจ/หนีไป P-Zone) ก็ปล่อยไป
	if c:GetReasonPlayer()~=tp and (r&REASON_BATTLE)~=0 then return end
	
	-- ถ้าโดน Remove / Bounce / ส่งลงสุสาน -> บังคับเด้งเข้า Extra Deck (Face-up)
	if c:IsLocation(LOCATION_REMOVED) or c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_GRAVE) then
		Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_EFFECT)
	end
end

-- ==================================================================
-- [Pendulum Logic]
-- ==================================================================
function s.pen_attack_draw_op(e,tp,eg,ep,ev,re,r,rp)
	local attacker = Duel.GetAttacker()
	if attacker then
		local atk = attacker:GetAttack()
		if atk < 0 then atk = 0 end
		local draw_count = math.floor(atk / 900)
		
		if draw_count > 0 then
			Duel.Draw(1-tp, draw_count, REASON_EFFECT)
		end
	end
end

function s.pen_damage_con(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetAttackTarget() == nil and Duel.GetAttacker():IsControler(1-tp)
end

function s.pen_damage_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Damage(tp, 900, REASON_EFFECT)
end

function s.pen_resol_con(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

function s.pen_resol_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(1-tp,1,REASON_EFFECT)
end

function s.return_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.return_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ==================================================================
-- [Monster Logic]
-- ==================================================================
function s.to_pzone_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1) then
		Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end

function s.splimit(e,se,sp,st)
	return se:GetHandler():IsCode(ID_BURST) or se:GetHandler():IsCode(id)
end
function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end
function s.override_con(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end
function s.override_op(e,tp,eg,ep,ev,re,r,rp)
	local g=Group.FromCards(e:GetHandler())
	Duel.ChangeChainOperation(ev, s.repop)
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end

-- ==================================================================
-- [Respawn Logic]
-- ==================================================================
function s.respawn_con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsFaceup() and c:IsLocation(LOCATION_EXTRA)
end

function s.respawn_cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetFieldGroup(tp,LOCATION_DECK,0)
	local count = math.ceil(#g/2)
	if chk==0 then return #g>0 and g:IsExists(Card.IsAbleToRemoveAsCost,count,nil,POS_FACEUP) end
	local g_rem=g:RandomSelect(tp,count)
	Duel.Remove(g_rem,POS_FACEUP,REASON_COST)
end

function s.respawn_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCountFromEx(tp,tp,c)>0 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.respawn_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.GetLocationCountFromEx(tp,tp,c)>0 then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ==================================================================
-- [Immunity Filter (Absolute Immunity)]
-- ==================================================================
function s.negate_immune_filter(e,te)
	-- [LOCKED] ลบบรรทัดที่เช็ค ID_NIKKE ออก เพื่อให้กันทุกอย่างจริงๆ
	-- if te:GetOwner():IsSetCard(ID_NIKKE) then return false end
	
	if (te:GetType() & EFFECT_TYPE_ACTIONS) ~= 0 then
		local cat = te:GetCategory()
		return (cat & CATEGORY_DISABLE)~=0 or (cat & CATEGORY_NEGATE)~=0
	end
	local ec = te:GetCode()
	return ec==EFFECT_DISABLE or ec==EFFECT_DISABLE_EFFECT or ec==EFFECT_DISABLE_CHAIN
end