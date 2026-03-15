-- Brave Blade - Phase Shift
-- ID: 188800008
local s,id=GetID()
local ID_ARCHETYPE = 0xbb8  
local ID_MOON_FEST = 188800005

function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	c:RegisterEffect(e0)

	-- [HAND EFFECT / PENDULUM]
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

	-- [TRAP EFFECT: Forced Banish & Swap]
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_DECK)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.sum_con)
	e2:SetTarget(s.card_tg)
	e2:SetOperation(s.card_op)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	local e4=e2:Clone()
	e4:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e4)

	-- Trigger 2: Opponent activates a monster effect on the field
	local e5=e2:Clone()
	e5:SetCode(EVENT_CHAINING)
	e5:SetCondition(s.chain_con)
	c:RegisterEffect(e5)

	-- Trigger 3: Opponent declares an attack
	local e6=e2:Clone()
	e6:SetCode(EVENT_ATTACK_ANNOUNCE)
	e6:SetCondition(s.atk_con)
	c:RegisterEffect(e6)
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

-- ฟังก์ชันสำหรับเนเกจเอฟเฟคตอนกลับลงสนาม
function s.apply_negation(tc, c)
	if not c then c = tc end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	tc:RegisterEffect(e1)
	
	local e2=e1:Clone()
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	tc:RegisterEffect(e2)
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
-- [Card Logic: Phase Shift - Banish & Swap]
-- ==================================================================
function s.sum_con(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsControler, 1, nil, 1-tp) and s.controls_only_bb(tp)
end

function s.chain_con(e,tp,eg,ep,ev,re,r,rp)
	local loc = Duel.GetChainInfo(ev, CHAININFO_TRIGGERING_LOCATION)
	return rp == 1-tp and (loc & LOCATION_MZONE ~= 0) and re:IsActiveType(TYPE_MONSTER) and s.controls_only_bb(tp)
end

function s.atk_con(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetAttacker():IsControler(1-tp) and s.controls_only_bb(tp)
end

function s.card_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return s.has_free_pzone(tp) 
			and Duel.IsExistingMatchingCard(nil, tp, LOCATION_MZONE, 0, 1, nil)
			and Duel.IsExistingMatchingCard(nil, tp, 0, LOCATION_MZONE, 1, nil)
	end
	s.setup_banish_hook(e,tp)
end

function s.card_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not s.has_free_pzone(tp) then return end
	Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	
	local g1 = Duel.GetMatchingGroup(nil, tp, 0, LOCATION_MZONE, nil) 
	local g2 = Duel.GetMatchingGroup(nil, tp, LOCATION_MZONE, 0, nil) 
	
	if #g1 > 0 and #g2 > 0 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
		local sg1 = g1:Select(tp, 1, 1, nil)
		
		Duel.Hint(HINT_SELECTMSG, 1-tp, HINTMSG_REMOVE)
		local sg2 = g2:Select(1-tp, 1, 1, nil)
		
		sg1:Merge(sg2)
		
		if Duel.Remove(sg1, POS_FACEUP, REASON_RULE) > 0 then
			local og = Duel.GetOperatedGroup()
			local tc = og:GetFirst()
			
			while tc do
				local is_my_monster = tc:GetPreviousControler() == tp
				local is_moon_fest = tc:IsCode(ID_MOON_FEST)
				local has_moon_fest = Duel.IsExistingMatchingCard(function(mc) return mc:IsFaceup() and mc:IsCode(ID_MOON_FEST) end, tp, LOCATION_MZONE, 0, 1, nil)
				
				if is_my_monster and (is_moon_fest or has_moon_fest) then
					if Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP) > 0 then
						s.apply_negation(tc, c)
					end
				else
					tc:RegisterFlagEffect(id, RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END, 0, 1)
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
					e1:SetCode(EVENT_PHASE+PHASE_END)
					e1:SetCountLimit(1)
					e1:SetLabelObject(tc)
					e1:SetCondition(s.retcon)
					e1:SetOperation(s.retop)
					e1:SetReset(RESET_PHASE+PHASE_END)
					Duel.RegisterEffect(e1, tp)
				end
				tc = og:GetNext()
			end
		end
	end
end

function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	return tc:GetFlagEffect(id)~=0
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc and tc:GetFlagEffect(id)~=0 then
		local p = tc:GetPreviousControler()
		if Duel.SpecialSummon(tc, 0, p, p, false, false, POS_FACEUP) > 0 then
			s.apply_negation(tc, e:GetHandler())
		end
	end
end