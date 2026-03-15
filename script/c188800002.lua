-- Brave Blade - Ember Shield
-- ID: 188800002
local s,id=GetID()
local ID_ARCHETYPE = 0xbb8  
local ID_SUN_DANCE = 188800000 

function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	c:RegisterEffect(e0)

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

	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY+CATEGORY_ATKCHANGE+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_DECK)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetCountLimit(1,id+100) 
	e2:SetCondition(s.neg_con)
	e2:SetTarget(s.neg_tg)
	e2:SetOperation(s.neg_op)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCondition(s.atk_con)
	e3:SetTarget(s.atk_tg)
	e3:SetOperation(s.atk_op)
	c:RegisterEffect(e3)
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

function s.sun_dance_filter(c)
	return c:IsFaceup() and c:IsCode(ID_SUN_DANCE)
end

function s.buff_sun_dance(c,tp)
	local sg=Duel.GetMatchingGroup(s.sun_dance_filter,tp,LOCATION_MZONE,0,nil)
	for sc in aux.Next(sg) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(200) -- เปลี่ยนเป็น +200 ถาวร
		e1:SetReset(RESET_EVENT+RESETS_STANDARD) 
		sc:RegisterEffect(e1)
	end
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
			return Duel.IsExistingMatchingCard(s.non_bb_filter,tp,LOCATION_DECK,0,1,nil)
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

function s.bb_monster_filter(c)
	return c:IsSetCard(ID_ARCHETYPE) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.non_bb_filter(c)
	return not c:IsSetCard(ID_ARCHETYPE) and c:IsAbleToHand()
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
		local thg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.bb_monster_filter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
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
		local deck=Duel.GetMatchingGroup(s.non_bb_filter,tp,LOCATION_DECK,0,nil)
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
-- [Card Logic: Negate Effect & Attack (จาก Deck)]
-- ==================================================================
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

function s.bb_target_filter(c,tp)
	return c:IsControler(tp) and c:IsSetCard(ID_ARCHETYPE) and c:IsType(TYPE_MONSTER) and c:IsFaceup()
end

function s.neg_con(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not s.controls_only_bb(tp) or not Duel.IsChainDisablable(ev) then return false end
	
	local cat=re:GetCategory()
	local is_dangerous = (cat & (CATEGORY_DESTROY+CATEGORY_REMOVE+CATEGORY_TOHAND+CATEGORY_TODECK+CATEGORY_CONTROL+CATEGORY_TOGRAVE)) ~= 0
	if not is_dangerous then return false end

	if re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
		if tg and tg:IsExists(s.bb_target_filter,1,nil,tp) then return true end
	end

	local ex,tg,tc = Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
	if ex and tg and tg:IsExists(s.bb_target_filter,1,nil,tp) then return true end

	ex,tg,tc = Duel.GetOperationInfo(ev,CATEGORY_REMOVE)
	if ex and tg and tg:IsExists(s.bb_target_filter,1,nil,tp) then return true end

	ex,tg,tc = Duel.GetOperationInfo(ev,CATEGORY_TOHAND)
	if ex and tg and tg:IsExists(s.bb_target_filter,1,nil,tp) then return true end

	ex,tg,tc = Duel.GetOperationInfo(ev,CATEGORY_TODECK)
	if ex and tg and tg:IsExists(s.bb_target_filter,1,nil,tp) then return true end

	ex,tg,tc = Duel.GetOperationInfo(ev,CATEGORY_CONTROL)
	if ex and tg and tg:IsExists(s.bb_target_filter,1,nil,tp) then return true end

	ex,tg,tc = Duel.GetOperationInfo(ev,CATEGORY_TOGRAVE)
	if ex and tg and tg:IsExists(s.bb_target_filter,1,nil,tp) then return true end

	return false
end

function s.neg_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.has_free_pzone(tp) end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
	s.setup_banish_hook(e,tp)
end

function s.neg_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not s.has_free_pzone(tp) then return end
	
	-- วางบน P-Zone
	Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	
	-- บัพพลัง Sun Dance 200 ถาวร ทันทีที่สั่งใช้สำเร็จ ไม่ต้องรอให้เนเกจ/ทำลายผ่าน
	s.buff_sun_dance(c,tp)
	
	-- จากนั้นค่อยไปเนเกจ และทำลาย
	if Duel.NegateEffect(ev) then
		if re:GetHandler():IsRelateToEffect(re) then
			Duel.Destroy(re:GetHandler(),REASON_EFFECT)
		end
	end
end

function s.atk_con(e,tp,eg,ep,ev,re,r,rp)
	local at=Duel.GetAttacker()
	local tg=Duel.GetAttackTarget()
	if not tg then return false end 
	return Card.IsControler(at, 1-tp) and Card.IsControler(tg, tp) and s.controls_only_bb(tp)
end

function s.atk_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.has_free_pzone(tp) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,Duel.GetAttacker(),1,0,0)
	s.setup_banish_hook(e,tp)
end

function s.atk_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not s.has_free_pzone(tp) then return end
	
	-- วางบน P-Zone
	Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	
	-- บัพพลัง Sun Dance 200 ถาวร ทันทีที่สั่งใช้สำเร็จ
	s.buff_sun_dance(c,tp)
	
	local at=Duel.GetAttacker()
	if Duel.NegateAttack() and at and at:IsRelateToBattle() then
		Duel.Destroy(at,REASON_EFFECT)
	end
end