-- Brave Blade - Lunar Mirage
-- ID: 188800006
local s,id=GetID()
local ID_ARCHETYPE = 0xbb8  
local ID_MOON_FEST = 188800005

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

	-- [CARD EFFECT: Lunar Mirage (Add & Normal Summon)]
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMING_STANDBY_PHASE+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e2:SetRange(LOCATION_DECK)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.ns_con)
	e2:SetTarget(s.ns_tg)
	e2:SetOperation(s.ns_op)
	c:RegisterEffect(e2)
end

-- ==================================================================
-- [Shared Logic]
-- ==================================================================
function s.has_free_pzone(tp)
	return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)
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

function s.moon_fest_filter(c)
	return c:IsFaceup() and c:IsCode(ID_MOON_FEST)
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
-- [Card Logic: Lunar Mirage (Normal Summon Variant)]
-- ==================================================================
function s.ns_con(e,tp,eg,ep,ev,re,r,rp)
	local ph = Duel.GetCurrentPhase()
	if ph ~= PHASE_STANDBY and (ph < PHASE_BATTLE_START or ph > PHASE_BATTLE) then return false end
	
	local g = Duel.GetFieldGroup(tp,LOCATION_ONFIELD,0)
	local m_count = 0
	for tc in aux.Next(g) do
		if tc:IsFaceup() and not tc:IsSetCard(ID_ARCHETYPE) then return false end
		if tc:IsFaceup() and tc:IsType(TYPE_MONSTER) then
			m_count = m_count + 1
		end
	end
	if m_count > 1 then return false end
	
	return true
end

function s.ns_filter(c)
	return c:IsSetCard(ID_ARCHETYPE) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand() 
		   and (c:IsLocation(LOCATION_DECK) or c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end

function s.ns_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local has_hand = Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0) > 0
		local has_target = Duel.IsExistingMatchingCard(s.ns_filter, tp, LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED, 0, 1, nil)
		local can_unbrick = Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(ID_ARCHETYPE) and c:IsType(TYPE_MONSTER) end, tp, LOCATION_HAND, 0, 1, nil)
		return s.has_free_pzone(tp) and Duel.GetLocationCount(tp,LOCATION_MZONE) > 0 and has_hand and (has_target or can_unbrick)
	end
	Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 1, tp, LOCATION_HAND)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0, CATEGORY_SUMMON, nil, 1, 0, 0)
	
	-- ลบ Duel.SetChainLimit(aux.FALSE) ออกแล้ว
	
	s.setup_banish_hook(e,tp)
end

function s.ns_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not s.has_free_pzone(tp) then return end
	Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	
	if Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0) == 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
	local hg = Duel.SelectMatchingCard(tp, aux.TRUE, tp, LOCATION_HAND, 0, 1, 1, nil)
	
	if #hg > 0 and Duel.SendtoDeck(hg, nil, SEQ_DECKSHUFFLE, REASON_EFFECT) > 0 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE) <= 0 then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.ns_filter),tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
		
		if #g>0 then
			local tc=g:GetFirst()
			-- นำการ์ดขึ้นมือ
			if Duel.SendtoHand(tc,nil,REASON_EFFECT) > 0 then
				Duel.ConfirmCards(1-tp, tc)
				-- สั่ง Normal Summon ทันที (ไม่ใช้เครื่องสังเวย)
				if tc:IsLocation(LOCATION_HAND) then
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_DECREASE_TRIBUTE)
					e1:SetValue(0x30003) 
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e1)
					
					if tc:IsSummonable(true, nil) then
						Duel.BreakEffect()
						Duel.Summon(tp, tc, true, nil)
						
						-- โบนัสอมตะ: ทำงานเมื่อลงสนามสำเร็จ และมี Moon Fest หงายหน้าอยู่
						if Duel.IsExistingMatchingCard(s.moon_fest_filter,tp,LOCATION_MZONE,0,1,nil) then
							local e2=Effect.CreateEffect(c)
							e2:SetType(EFFECT_TYPE_SINGLE)
							e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
							e2:SetValue(1)
							e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
							tc:RegisterEffect(e2)
							local e3=e2:Clone()
							e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
							tc:RegisterEffect(e3)
						end
					end
				end
			end
		end
	end
end