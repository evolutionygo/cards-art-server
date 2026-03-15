-- Brave Blade - Astral Seal
-- ID: 188800010
local s,id=GetID()
local ID_ARCHETYPE = 0xbb8  
local ID_PISCES_MIST = 188800009

function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	c:RegisterEffect(e0)

	-- [HAND EFFECT]
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON+CATEGORY_TODECK+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.hand_con) 
	e1:SetTarget(s.pen_tg)
	e1:SetOperation(s.pen_op)
	c:RegisterEffect(e1)

	-- [CARD EFFECT: Astral Seal]
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_DECK)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.neg_con)
	e2:SetTarget(s.card_tg)
	e2:SetOperation(s.neg_op)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCondition(s.atk_con)
	e3:SetOperation(s.atk_op)
	c:RegisterEffect(e3)

	-- ==================================================
	-- [GLOBAL SYSTEM] ระบบส่วนกลางสำหรับกวาดล้างเชน
	-- ==================================================
	if not s.global_check then
		s.global_check=true
		
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.global_chain_mark)
		Duel.RegisterEffect(ge1,0)

		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_CHAIN_SOLVING)
		ge2:SetOperation(s.global_chain_solving)
		Duel.RegisterEffect(ge2,0)
		
		local ge3=Effect.CreateEffect(c)
		ge3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge3:SetCode(EVENT_CHAIN_END)
		ge3:SetOperation(s.global_chain_end)
		Duel.RegisterEffect(ge3,0)
	end
end

-- ==================================================================
-- [Shared Logic]
-- ==================================================================
function s.has_free_pzone(tp)
	return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)
end

function s.controls_only_bb(tp)
	local g=Duel.GetFieldGroup(tp,LOCATION_ONFIELD,0)
	if #g==0 then return false end
	local has_bb_monster = false
	for tc in aux.Next(g) do
		if tc:IsFaceup() and not tc:IsSetCard(ID_ARCHETYPE) then return false end
		if tc:IsFaceup() and tc:IsSetCard(ID_ARCHETYPE) and tc:IsType(TYPE_MONSTER) then has_bb_monster = true end
	end
	return has_bb_monster
end

function s.is_empty_or_only_bb_st(tp, c)
	local g=Duel.GetFieldGroup(tp,LOCATION_ONFIELD,0)
	if c and g:IsContains(c) then g:RemoveCard(c) end
	if g:IsExists(Card.IsType, 1, nil, TYPE_MONSTER) then return false end
	if g:IsExists(function(tc) return tc:IsFaceup() and not tc:IsSetCard(ID_ARCHETYPE) end, 1, nil) then return false end
	return true
end

function s.setup_banish_hook(e,tp)
	local c=e:GetHandler()
	local e_banish=Effect.CreateEffect(c)
	e_banish:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e_banish:SetCode(EVENT_CHAIN_END)
	e_banish:SetLabelObject(c)
	e_banish:SetOperation(s.banish_end_op)
	e_banish:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e_banish,tp)
end

function s.banish_end_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	if c then Duel.Remove(c,POS_FACEUP,REASON_EFFECT) end
	e:Reset() 
end

-- ==================================================================
-- [Hand Effect Logic]
-- ==================================================================
function s.hand_con(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()==tp and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
end
function s.pen_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		if not s.has_free_pzone(tp) then return false end
		local c = e:GetHandler()
		local is_eff1 = s.is_empty_or_only_bb_st(tp, c)
		if is_eff1 then
			return Duel.IsExistingMatchingCard(function(tc) return tc:IsSetCard(ID_ARCHETYPE) and tc:IsType(TYPE_MONSTER) end, tp, LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE, 0, 1, nil)
		else
			return Duel.IsExistingMatchingCard(function(c) return not c:IsSetCard(ID_ARCHETYPE) and c:IsAbleToHand() end,tp,LOCATION_DECK,0,1,nil)
		end
	end
	local c = e:GetHandler()
	local e_banish = Effect.CreateEffect(c)
	e_banish:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e_banish:SetCode(EVENT_CHAIN_END)
	e_banish:SetLabelObject(c)
	e_banish:SetOperation(s.hand_banish_op)
	e_banish:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e_banish, tp)
end
function s.hand_banish_op(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetLabelObject()
	if c and (c:IsLocation(LOCATION_ONFIELD) or c:IsLocation(LOCATION_GRAVE) or c:IsLocation(LOCATION_HAND)) then
		Duel.Remove(c,POS_FACEUP,REASON_EFFECT)
	end
	e:Reset()
end
function s.pen_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local is_eff1 = s.is_empty_or_only_bb_st(tp, c)
	if is_eff1 then
		local hand_bb = Duel.GetMatchingGroup(function(tc) return tc:IsSetCard(ID_ARCHETYPE) and tc:IsType(TYPE_MONSTER) end, tp, LOCATION_HAND, 0, nil)
		if #hand_bb > 0 then
			Duel.SendtoDeck(hand_bb, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
			Duel.BreakEffect()
		end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local thg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(function(tc) return tc:IsSetCard(ID_ARCHETYPE) and tc:IsType(TYPE_MONSTER) and tc:IsAbleToHand() end),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		if #thg>0 and Duel.SendtoHand(thg,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,thg)
			local tc=thg:GetFirst()
			if tc:IsLocation(LOCATION_HAND) then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DECREASE_TRIBUTE)
				e1:SetValue(0x30003) 
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
				if tc:IsSummonable(true,nil) then
					Duel.BreakEffect()
					Duel.Summon(tp,tc,true,nil) 
				end
			end
		end
	else
		local deck=Duel.GetMatchingGroup(function(tc) return not tc:IsSetCard(ID_ARCHETYPE) and tc:IsAbleToHand() end,tp,LOCATION_DECK,0,nil)
		if #deck>0 then
			local rand=deck:RandomSelect(tp,1)
			Duel.SendtoHand(rand,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,rand)
		end
	end
	if c:IsRelateToEffect(e) then
		c:CancelToGrave() 
		Duel.SendtoDeck(c,nil,2,REASON_EFFECT)
	end
end

-- ==================================================================
-- [Card Logic: Astral Seal - Global Wipe]
-- ==================================================================
function s.neg_con(e,tp,eg,ep,ev,re,r,rp)
	local loc = Duel.GetChainInfo(ev, CHAININFO_TRIGGERING_LOCATION)
	return rp==1-tp and (loc & LOCATION_ONFIELD ~= 0) and Duel.IsChainDisablable(ev) and s.controls_only_bb(tp)
end

function s.atk_con(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetAttacker():IsControler(1-tp) and s.controls_only_bb(tp)
end

function s.card_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.has_free_pzone(tp) end
	if e:GetCode()==EVENT_CHAINING then
		Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	end
	s.setup_banish_hook(e,tp)
end

function s.global_chain_mark(e,tp,eg,ep,ev,re,r,rp)
	Duel.RegisterFlagEffect(rp, id+700, 0, 0, 1) 
end

function s.global_chain_solving(e,tp,eg,ep,ev,re,r,rp)
	for p=0,1 do
		if Duel.GetFlagEffect(p, id+500) > 0 then
			local opp_acted = Duel.GetFlagEffect(1-p, id+700) > 0
			local my_acted = Duel.GetFlagEffect(p, id+700) > 0
			
			if opp_acted and not my_acted and rp == 1-p then
				Duel.Hint(HINT_CARD, 0, id)
				Duel.NegateEffect(ev)
			end
		end
	end
end

function s.global_chain_end(e,tp,eg,ep,ev,re,r,rp)
	local p0_acted = Duel.GetFlagEffect(0, id+700) > 0
	local p1_acted = Duel.GetFlagEffect(1, id+700) > 0
	
	if Duel.GetFlagEffect(0, id+500) > 0 and p1_acted then
		Duel.ResetFlagEffect(0, id+500)
	end
	
	if Duel.GetFlagEffect(1, id+500) > 0 and p0_acted then
		Duel.ResetFlagEffect(1, id+500)
	end
	
	for p=0,1 do
		if Duel.GetFlagEffect(p, id+499) > 0 then
			Duel.ResetFlagEffect(p, id+499)
			Duel.RegisterFlagEffect(p, id+500, 0, 0, 1)
		end
		Duel.ResetFlagEffect(p, id+700)
	end
end

function s.neg_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not s.has_free_pzone(tp) then return end
	Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	
	if Duel.NegateEffect(ev) then
		Duel.RegisterFlagEffect(tp, id+499, 0, 0, 1)
		
		-- ตรวจสอบว่ามี Pisces Mist (188800009) บนสนามหรือไม่
		if Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsCode(ID_PISCES_MIST) end, tp, LOCATION_MZONE, 0, 1, nil) then
			Duel.BreakEffect()
			local g = Duel.GetFieldGroup(tp, 0, LOCATION_ONFIELD)
			if #g > 0 then
				Duel.Hint(HINT_SELECTMSG, 1-tp, HINTMSG_SET)
				local sg = g:Select(1-tp, 1, 1, nil)
				local tc = sg:GetFirst()
				if tc then
					Duel.ChangePosition(tc, POS_FACEDOWN_DEFENSE)
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
					e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
					tc:RegisterEffect(e1)
					local e2=e1:Clone()
					e2:SetCode(EFFECT_CANNOT_TRIGGER)
					tc:RegisterEffect(e2)
					local e3=e1:Clone()
					e3:SetCode(EFFECT_CANNOT_ACTIVATE)
					tc:RegisterEffect(e3)
				end
			end
		end
	end
end

function s.atk_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not s.has_free_pzone(tp) then return end
	Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	
	if Duel.NegateAttack() then
		Duel.RegisterFlagEffect(tp, id+499, 0, 0, 1)
		
		-- ตรวจสอบว่ามี Pisces Mist (188800009) บนสนามหรือไม่
		if Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsCode(ID_PISCES_MIST) end, tp, LOCATION_MZONE, 0, 1, nil) then
			Duel.BreakEffect()
			local g = Duel.GetFieldGroup(tp, 0, LOCATION_ONFIELD)
			if #g > 0 then
				Duel.Hint(HINT_SELECTMSG, 1-tp, HINTMSG_SET)
				local sg = g:Select(1-tp, 1, 1, nil)
				local tc = sg:GetFirst()
				if tc then
					Duel.ChangePosition(tc, POS_FACEDOWN_DEFENSE)
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
					e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
					tc:RegisterEffect(e1)
					local e2=e1:Clone()
					e2:SetCode(EFFECT_CANNOT_TRIGGER)
					tc:RegisterEffect(e2)
					local e3=e1:Clone()
					e3:SetCode(EFFECT_CANNOT_ACTIVATE)
					tc:RegisterEffect(e3)
				end
			end
		end
	end
end