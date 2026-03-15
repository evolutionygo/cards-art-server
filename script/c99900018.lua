-- Villain Nikke Drake (ID: 99900018)
local s,id=GetID()
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
	
	-- 1. Villain's Roar (AOE Def 0)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_POSITION+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.poscon)
	e1:SetTarget(s.postg)
	e1:SetOperation(s.posop)
	c:RegisterEffect(e1)
	
	-- 2. Power Absorb
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.atkcon)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	
	-- 3. Quick Negate + Change POS + Halve DEF
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DISABLE+CATEGORY_POSITION+CATEGORY_DEFCHANGE) -- เพิ่ม Category
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
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

-- [Effect 1] AOE Position Change & DEF 0
function s.poscon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.posfilter(c)
	return c:IsFaceup() and (c:IsAttackPos() or c:GetDefense()>0)
end
function s.postg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.posfilter,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(s.posfilter,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_POSITION,g,#g,0,0)
end
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.posfilter,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.ChangePosition(g,POS_FACEUP_DEFENSE)
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_DEFENSE_FINAL)
			e1:SetValue(0)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
end

-- [Effect 2] ATK Gain
function s.envfilter(c)
	return c:IsCode(FIELD_SPELL_ID) and c:IsFaceup()
end
function s.atkcon(e)
	return Duel.IsExistingMatchingCard(s.envfilter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end
function s.atkval(e,c)
	local g=c:GetOverlayGroup()
	local atk=0
	for tc in aux.Next(g) do
		if tc:IsType(TYPE_MONSTER) and tc:GetTextAttack()>0 then 
			atk=atk+tc:GetTextAttack() 
		end
	end
	return atk
end

-- [Effect 3] Quick Negate + Change POS + Halve DEF
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled() and (c:IsType(TYPE_MONSTER) or c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and s.negfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.negfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,0,0)
	-- เพิ่ม Info ว่าจะเปลี่ยน Position
	Duel.SetOperationInfo(0,CATEGORY_POSITION,nil,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	
	if ((tc:IsFaceup() and not tc:IsDisabled()) or tc:IsType(TYPE_TRAPMONSTER)) and tc:IsRelateToEffect(e) then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		
		-- 1. Negate Effect
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
		
		if tc:IsType(TYPE_TRAPMONSTER) then
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e3)
		end

		-- 2. If Monster: Change Position & Halve DEF
		if tc:IsType(TYPE_MONSTER) and tc:IsRelateToEffect(e) then
			-- ถ้าโจมตีอยู่ จับนั่ง
			if tc:IsAttackPos() then
				Duel.ChangePosition(tc,POS_FACEUP_DEFENSE)
			end
			
			-- ลด DEF ครึ่งนึง (ถ้ามี DEF)
			local def=tc:GetDefense()
			if def>0 then
				local e4=Effect.CreateEffect(c)
				e4:SetType(EFFECT_TYPE_SINGLE)
				e4:SetCode(EFFECT_SET_DEFENSE_FINAL)
				e4:SetValue(math.ceil(def/2))
				e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e4)
			end
		end
	end
end