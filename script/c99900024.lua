-- Fixer Nikke Milk
-- ID: 99900024
local s,id=GetID()
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- Synchro Summon Procedure
	c:EnableReviveLimit()
	aux.AddSynchroProcedure(c,nil,aux.NonTuner(s.matfilter),1,99)

	-- 1. Cannot be destroyed by battle (Immortal)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- 2. Battle Removal (Player Action Banish)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F) 
	e2:SetCode(EVENT_BATTLED) 
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetCondition(s.batcon)
	e2:SetTarget(s.battg)
	e2:SetOperation(s.batop)
	c:RegisterEffect(e2)

	-- 3. Direct Attack -> Deck Banish
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_BATTLED)
	e3:SetCondition(s.dircon)
	e3:SetTarget(s.dirtg)
	e3:SetOperation(s.dirop)
	c:RegisterEffect(e3)
end

function s.matfilter(c)
	return c:IsSetCard(NIKKE_SET_ID)
end

-- =======================================================================
-- [Effect 2] Vs Monster: Player Action Banish Face-down -> Hand/Extra Disrupt
-- =======================================================================
function s.batcon(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetHandler():GetBattleTarget()
	return bc and bc:IsControler(1-tp)
end

function s.battg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local bc=e:GetHandler():GetBattleTarget()
	if bc then
		-- แจ้งเตือนระบบว่าจะมีการรีมูฟ
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,bc,1,0,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,1-tp,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,0,1-tp,LOCATION_EXTRA)
end

function s.batop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	
	if bc and bc:IsRelateToBattle() then
		-- [แก้ไข]บังคับให้เป็นการกระทำของผู้เล่น (ทะลุการกันรีมูฟและกันเอฟเฟค)
		if Duel.Remove(bc,POS_FACEDOWN,REASON_RULE)>0 then
			local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
			if #hg>0 then
				Duel.BreakEffect()
				local sg=hg:RandomSelect(tp,1)
				Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
			else
				local eg_ex=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
				if #eg_ex>0 then
					Duel.BreakEffect()
					local sg=eg_ex:RandomSelect(tp,1)
					Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)
				end
			end
		end
	end
end

-- =======================================================================
-- [Effect 3] Direct Attack: Deck Banish Face-down
-- =======================================================================
function s.dircon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetAttackTarget()==nil and e:GetHandler()==Duel.GetAttacker()
end

function s.dirtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_DECK)
end

function s.dirop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_DECK)
	if #g>0 then
		local sg=g:RandomSelect(tp,1)
		Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)
	end
end