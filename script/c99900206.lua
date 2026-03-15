-- Rapture Carnage Protocol
-- ID: 99900206
local s,id=GetID()
local ID_RAPTURE = 0xc22
local COUNTER_PROTOCOL = 0x1c22

function s.initial_effect(c)
	c:EnableCounterPermit(COUNTER_PROTOCOL)

	-- 1. Activation: Search "Rapture" card & Place Counters
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 2. Activate from Hand (Condition: Opponent Monster Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)

	-- 3. Continuous: Gain Counter when card(s) on field are destroyed
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.ctcon)
	e3:SetOperation(s.ctop)
	c:RegisterEffect(e3)

	-- 4. Non-Chain (Draw Phase): Remove 1 -> Draw 1 (Mandatory, >= 4)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_PHASE+PHASE_DRAW)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.drcon)
	e4:SetOperation(s.drop)
	c:RegisterEffect(e4)

	-- 5. Non-Chain (Anti-Sp.Summon): Remove 3 -> Negate & Material Restriction (This Turn)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetRange(LOCATION_SZONE)
	e5:SetCondition(s.spnegcon)
	e5:SetOperation(s.spnegop)
	c:RegisterEffect(e5)

	-- 6. Non-Chain (After Resolve): Remove 3 -> Destroy or Buff ATK
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_CHAIN_SOLVED)
	e6:SetRange(LOCATION_SZONE)
	e6:SetCondition(s.chsolcon)
	e6:SetOperation(s.chsolop)
	c:RegisterEffect(e6)
end

function s.handcon(e)
	local ch=Duel.GetCurrentChain()
	if ch==0 then return false end
	local re,rp=Duel.GetChainInfo(ch,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
	return rp==1-e:GetHandlerPlayer() and re:IsActiveType(TYPE_MONSTER)
end

function s.thfilter(c)
	return c:IsSetCard(ID_RAPTURE) and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,nil,1,0,COUNTER_PROTOCOL)
end

function s.rapture_filter(c)
	return c:IsFaceup() and c:IsSetCard(ID_RAPTURE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		local ct=Duel.GetMatchingGroupCount(s.rapture_filter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
		if ct>0 then
			Duel.BreakEffect()
			c:AddCounter(COUNTER_PROTOCOL,ct)
		end
	end
end

function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsPreviousLocation,1,nil,LOCATION_ONFIELD)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=eg:FilterCount(Card.IsPreviousLocation,nil,LOCATION_ONFIELD)
	if ct>0 then
		c:AddCounter(COUNTER_PROTOCOL,ct)
	end
end

-- ==================================================================
-- Logic 4: (Draw Phase)
-- ==================================================================
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and e:GetHandler():GetCounter(COUNTER_PROTOCOL)>=4
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:GetCounter(COUNTER_PROTOCOL)>=4 then
		Duel.Hint(HINT_CARD,0,id)
		c:RemoveCounter(tp,COUNTER_PROTOCOL,1,REASON_EFFECT)
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end

-- ==================================================================
-- Logic 5: (Anti-Sp.Summon) - ปรับจบแค่ End Phase ของเทิร์นนี้
-- ==================================================================
function s.spneg_filter(c,tp)
	return c:IsControler(1-tp) and c:IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.spnegcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.spneg_filter,1,nil,tp) and e:GetHandler():GetCounter(COUNTER_PROTOCOL)>=3
end

function s.spnegop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=eg:Filter(s.spneg_filter,nil,tp)
	if #g>0 and c:GetCounter(COUNTER_PROTOCOL)>=3 then
		if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then 
			Duel.Hint(HINT_CARD,0,id)
			c:RemoveCounter(tp,COUNTER_PROTOCOL,3,REASON_EFFECT)
			for tc in aux.Next(g) do
				-- [แก้ไข] ลบ ,2 ออกทั้งหมด เพื่อให้ Reset แค่จบเทิร์นนี้
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e1)
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_DISABLE_EFFECT)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e2)
				
				local e3=Effect.CreateEffect(c)
				e3:SetType(EFFECT_TYPE_SINGLE)
				e3:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
				e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
				e3:SetValue(1)
				e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e3)
				local e4=e3:Clone() e4:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL) tc:RegisterEffect(e4)
				local e5=e3:Clone() e5:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL) tc:RegisterEffect(e5)
				local e6=e3:Clone() e6:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL) tc:RegisterEffect(e6)
				
				local e7=Effect.CreateEffect(c)
				e7:SetType(EFFECT_TYPE_SINGLE)
				e7:SetCode(EFFECT_UNRELEASABLE_SUM)
				e7:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
				e7:SetValue(1)
				e7:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e7)
				local e8=e7:Clone() e8:SetCode(EFFECT_UNRELEASABLE_NONSUM) tc:RegisterEffect(e8)
			end
		end
	end
end

-- ==================================================================
-- Logic 6: (After Resolve - Field Monster Only)
-- ==================================================================
function s.chsolcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	local loc = Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER) 
	   and loc==LOCATION_MZONE 
	   and rc:IsSummonType(SUMMON_TYPE_SPECIAL) 
	   and e:GetHandler():GetCounter(COUNTER_PROTOCOL)>=3
end

function s.chsolop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:GetCounter(COUNTER_PROTOCOL)>=3 then
		if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			Duel.Hint(HINT_CARD,0,id)
			c:RemoveCounter(tp,COUNTER_PROTOCOL,3,REASON_EFFECT)
			local rc=re:GetHandler()
			
			if Duel.Destroy(rc,REASON_EFFECT)==0 then
				local rg=Duel.GetMatchingGroup(s.rapture_filter,tp,LOCATION_MZONE,0,nil)
				for tc in aux.Next(rg) do
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_UPDATE_ATTACK)
					e1:SetValue(300)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e1)
				end
			end
		end
	end
end