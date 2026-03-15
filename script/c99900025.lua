-- Fixer Nikke Frima
-- ID: 99900025
local s,id=GetID()
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- Synchro Summon
	c:EnableReviveLimit()
	aux.AddSynchroProcedure(c,nil,aux.NonTuner(s.matfilter),1,99)

	-- 1. Flip Face-down
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_POSITION)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.postg)
	e1:SetOperation(s.posop)
	c:RegisterEffect(e1)

	-- 2. Negate Defense Position monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetTarget(s.distg)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_DISABLE_EFFECT)
	c:RegisterEffect(e3)

	-- 3. Attack Limit (Global Check)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_ATTACK_ANNOUNCE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(0,LOCATION_MZONE)
	e4:SetCondition(s.lazy_con)
	c:RegisterEffect(e4)

	-- 4. Monster Effect Activation Limit (Global Check)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e5:SetCode(EFFECT_CANNOT_ACTIVATE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(0,1)
	e5:SetCondition(s.lazy_con)
	e5:SetValue(s.aclimit)
	c:RegisterEffect(e5)
	
	if not s.global_check then
		s.global_check=true
		s.lazy_count={}
		s.lazy_count[0]=0
		s.lazy_count[1]=0
		
		local ge1=Effect.GlobalEffect()
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_TURN_START)
		ge1:SetOperation(s.reset_count)
		Duel.RegisterEffect(ge1,0)
		
		local ge2=Effect.GlobalEffect()
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_ATTACK_ANNOUNCE)
		ge2:SetOperation(s.check_attack)
		Duel.RegisterEffect(ge2,0)
		
		local ge3=Effect.GlobalEffect()
		ge3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge3:SetCode(EVENT_CHAINING)
		ge3:SetOperation(s.check_effect)
		Duel.RegisterEffect(ge3,0)
	end
end

function s.matfilter(c)
	return c:IsSetCard(NIKKE_SET_ID)
end

function s.nikkefilter(c)
	return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID)
end
function s.postg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local ct=Duel.GetMatchingGroupCount(s.nikkefilter,tp,LOCATION_MZONE,0,nil)
		return ct>0 and Duel.IsExistingMatchingCard(Card.IsCanTurnSet,tp,0,LOCATION_MZONE,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_POSITION,nil,1,1-tp,LOCATION_MZONE)
end
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.nikkefilter,tp,LOCATION_MZONE,0,nil)
	if ct==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
	local g=Duel.SelectMatchingCard(tp,Card.IsCanTurnSet,tp,0,LOCATION_MZONE,1,ct,nil)
	if #g>0 then
		Duel.HintSelection(g)
		if Duel.ChangePosition(g,POS_FACEDOWN_DEFENSE)>0 then
			local og=Duel.GetOperatedGroup()
			for tc in aux.Next(og) do
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
			end
		end
	end
end

function s.distg(e,c)
	return c:IsPosition(POS_DEFENSE)
end

function s.reset_count(e,tp,eg,ep,ev,re,r,rp)
	s.lazy_count[0]=0
	s.lazy_count[1]=0
end

function s.check_attack(e,tp,eg,ep,ev,re,r,rp)
	local attacker = Duel.GetAttacker()
	if attacker then
		local p = attacker:GetControler()
		s.lazy_count[p] = s.lazy_count[p] + 1
	end
end

function s.check_effect(e,tp,eg,ep,ev,re,r,rp)
	if re:IsActiveType(TYPE_MONSTER) then
		s.lazy_count[rp] = s.lazy_count[rp] + 1
	end
end

function s.lazy_con(e)
	local tp = e:GetHandlerPlayer()
	-- Limit increased to 3 times
	return s.lazy_count[1-tp] >= 3
end

function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER)
end