-- Tyrant-Class Descent
-- ID: 99900204
local s,id=GetID()
local ID_RAPTURE = 0xc22

function s.initial_effect(c)
	-- อนุญาตให้ใช้งานจากบนมือได้ในเทิร์นอีกฝ่าย (ถ้าตรงเงื่อนไข)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	e0:SetCondition(s.handcon)
	c:RegisterEffect(e0)

	-- Activate (Quick-Play)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- ==================================================================
-- Logic: Hand Trap Condition (Opponent's Turn - Battle Phase)
-- ==================================================================
function s.handcon(e)
	local tp=e:GetHandlerPlayer()
	-- ถ้าเป็นเทิร์นเรา เราสามารถใช้ Quick-Play จากมือได้อยู่แล้ว ไม่ต้องพึ่งเอฟเฟคนี้
	if Duel.GetTurnPlayer()==tp then return false end
	
	local ph=Duel.GetCurrentPhase()
	-- ในเทิร์นอีกฝ่าย ใช้จากมือได้ถ้าอยู่ใน Battle Phase และมีการโจมตีหรือใช้เอฟเฟค
	if ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE then
		if Duel.GetAttacker() then return true end
		if Duel.GetCurrentChain()>0 then return true end
	end
	return false
end

-- ==================================================================
-- Logic: Condition (Main Phase OR Any Battle Phase attack/effect)
-- ==================================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	-- 1. ใช้ใน Main Phase ของเรา
	if Duel.GetTurnPlayer()==tp and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2) then
		return true
	end
	-- 2. ใช้ใน Battle Phase ของฝ่ายใดก็ได้ (เมื่อมีการโจมตี หรือใช้เอฟเฟค)
	if ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE then
		if Duel.GetAttacker() then return true end
		if Duel.GetCurrentChain()>0 then return true end
	end
	return false
end

-- ==================================================================
-- Logic: Destroy 1 Machine + 1 Other -> Summon Lv/Rank 8
-- ==================================================================
function s.machine_filter(c)
	return c:IsRace(RACE_MACHINE) and c:IsFaceup()
end

function s.sumfilter(c,e,tp)
	return c:IsSetCard(ID_RAPTURE) and (c:IsLevel(8) or c:IsRank(8))
		and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

function s.des_check(sg,e,tp)
	if not sg:IsExists(s.machine_filter,1,nil) then return false end
	local can_main = Duel.GetMZoneCount(tp,sg)>0 and Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	local can_ex = Duel.GetLocationCountFromEx(tp,tp,sg,nil)>0 and Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	return can_main or can_ex
end

function s.mat_filter(c)
	return c:IsSetCard(ID_RAPTURE) and c:IsType(TYPE_MONSTER)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local rg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then 
		return rg:CheckSubGroup(s.des_check,2,2,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local rg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	
	local sg=rg:SelectSubGroup(tp,s.des_check,false,2,2,e,tp)
	if not sg or #sg~=2 then return end
	
	Duel.HintSelection(sg)
	if Duel.Destroy(sg,REASON_EFFECT)==2 then
		local b1 = Duel.GetMZoneCount(tp)>0
		local b2 = Duel.GetLocationCountFromEx(tp)>0
		
		local loc = 0
		if b1 then loc = loc + LOCATION_DECK + LOCATION_GRAVE end
		if b2 then loc = loc + LOCATION_EXTRA end
		if loc == 0 then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g_sum=Duel.SelectMatchingCard(tp,s.sumfilter,tp,loc,0,1,1,nil,e,tp)
		local tc=g_sum:GetFirst()
		if tc then
			if Duel.SpecialSummonStep(tc,0,tp,tp,true,true,POS_FACEUP) then
				tc:CompleteProcedure()

				-- 2.1 Cannot be Removed (Banished)
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetDescription(aux.Stringid(id,2))
				e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CANNOT_REMOVE)
				e1:SetValue(1)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e1)
				
				-- 2.2 Destroy at End Phase
				local e2=Effect.CreateEffect(e:GetHandler())
				e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
				e2:SetCode(EVENT_PHASE+PHASE_END)
				e2:SetCountLimit(1)
				e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
				e2:SetLabelObject(tc)
				e2:SetCondition(s.descon)
				e2:SetOperation(s.desop)
				e2:SetReset(RESET_PHASE+PHASE_END)
				Duel.RegisterEffect(e2,tp)
			end
			Duel.SpecialSummonComplete()
			
			-- ถ้าลงมาเป็น Xyz สุ่มติดเมทิเรียล
			if tc:IsType(TYPE_XYZ) then
				local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.mat_filter),tp,LOCATION_GRAVE,0,nil)
				if #mg>0 then
					local mat=mg:RandomSelect(tp,1)
					Duel.Overlay(tc,mat)
				end
			end
		end
	end

	-- 4. Register Global Effect: When Lv/Rank 8 Rapture leaves -> Add Lv8 Machine
	if Duel.GetFlagEffect(tp,id)==0 then
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e3:SetCode(EVENT_LEAVE_FIELD)
		e3:SetCondition(s.regcon)
		e3:SetOperation(s.regop)
		e3:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e3,tp)
	end
end

-- ==================================================================
-- Logic: End Phase Destroy & Search Logic
-- ==================================================================
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if not tc or not tc:IsLocation(LOCATION_MZONE) then return false end
	return true
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.Destroy(tc,REASON_EFFECT)
end

function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.leave_filter,1,nil,tp)
end

function s.leave_filter(c,tp)
	return c:IsSetCard(ID_RAPTURE) and (c:IsLevel(8) or c:IsRank(8)) 
	   and c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFlagEffect(tp,id)>0 then return end

	if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
		Duel.Hint(HINT_CARD,0,id)
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

function s.thfilter(c)
	return c:IsRace(RACE_MACHINE) and c:IsLevel(8) and c:IsAbleToHand()
end