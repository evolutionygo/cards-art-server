-- Rapture Queen
-- ID: 99900210
local s,id=GetID()
local ID_RAPTURE = 0xc22
local ID_HERETIC = 0xc20

function s.initial_effect(c)
	c:EnableReviveLimit()
	
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- You can only control 1 "Rapture Queen"
	c:SetUniqueOnField(1,0,id)

	-- 1. Ignition (Extra Deck/GY): Destroy 4+ Machines -> Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_EXTRA+LOCATION_GRAVE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. On Summon Trigger: Unaffected by opponent's effects (Unchainable)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetTarget(s.immtg)
	e2:SetOperation(s.immop)
	c:RegisterEffect(e2)

	-- 3. Continuous: Protection (Effects)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_ONFIELD,0)
	e3:SetTarget(s.protect_tg)
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)

	-- 4. Continuous: Protection (Attacks)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(0,LOCATION_MZONE)
	e4:SetValue(s.protect_tg)
	c:RegisterEffect(e4)

	-- 5. Quick Effect: Force Opponent to Negate & Attack (Ignore Immune)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_DISABLE+CATEGORY_POSITION)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e5:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e5:SetCountLimit(1,id)
	e5:SetTarget(s.negtg)
	e5:SetOperation(s.negop)
	c:RegisterEffect(e5)

	-- 6. Cannot Attack
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_CANNOT_ATTACK)
	c:RegisterEffect(e6)

	-- 7. Continuous ATK based on Level/Rank of Rapture/Heretic
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCode(EFFECT_SET_BASE_ATTACK)
	e7:SetValue(s.atkval)
	c:RegisterEffect(e7)
end

function s.splimit(e,se,sp,st)
	return (st&SUMMON_TYPE_LINK)~=SUMMON_TYPE_LINK
end

-- ==================================================================
-- Logic 1: Summon 
-- ==================================================================
function s.sum_filter(c)
	return c:IsRace(RACE_MACHINE)
end

function s.sum_check(sg,e,tp)
	local c=e:GetHandler()
	if not sg:IsExists(Card.IsSetCard,1,nil,ID_RAPTURE) then return false end
	if c:IsLocation(LOCATION_EXTRA) then
		return Duel.GetLocationCountFromEx(tp,tp,sg,c)>0
	else
		return Duel.GetMZoneCount(tp,sg)>0
	end
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local c=e:GetHandler()
	local rg=Duel.GetMatchingGroup(s.sum_filter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then 
		return c:IsCanBeSpecialSummoned(e,0,tp,true,true) 
		   and rg:CheckSubGroup(s.sum_check,4,99,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local sg=rg:SelectSubGroup(tp,s.sum_check,false,4,99,e,tp)
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,sg,#sg,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	
	if #g>=4 then
		if Duel.Destroy(g,REASON_EFFECT)>=4 then
			if Duel.SpecialSummon(c,0,tp,tp,true,true,POS_FACEUP)>0 then
				c:CompleteProcedure()
			end
		end
	end
end

-- ==================================================================
-- Logic 2: On Summon -> Immune (Unchainable)
-- ==================================================================
function s.immtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetChainLimit(aux.FALSE)
end

function s.immop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.efilter)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
	c:RegisterEffect(e1)
end

function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- ==================================================================
-- Logic 3 & 4: Protection (Taunt)
-- ==================================================================
function s.protect_tg(e,c)
	return c~=e:GetHandler()
end

-- ==================================================================
-- Logic 5: Force Negate & Attack (Ignore Immune)
-- ==================================================================
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil) end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_NEGATE)
	local g=Duel.SelectMatchingCard(1-tp,Card.IsFaceup,1-tp,LOCATION_ONFIELD,0,1,1,nil)
	local tc=g:GetFirst()
	
	if tc then
		Duel.HintSelection(g)
		
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE) 
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
		
		if tc:IsType(TYPE_MONSTER) then
			if tc:IsPosition(POS_DEFENSE) then
				Duel.ChangePosition(tc,POS_FACEUP_ATTACK)
			end
			
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_MUST_ATTACK)
			e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e3)
		end
	end
end

-- ==================================================================
-- Logic 7: ATK Calculation (Level/Rank * 200)
-- ==================================================================
function s.atkfilter(c)
	-- หา Rapture และ Heretic (ที่ไม่ใช่ Link Monster เพราะลิงก์ไม่มีดาว/แรงค์)
	return (c:IsSetCard(ID_RAPTURE) or c:IsSetCard(ID_HERETIC)) 
	   and c:IsType(TYPE_MONSTER) 
	   and not c:IsType(TYPE_LINK)
end

function s.atkval(e,c)
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.atkfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	local sum_lvl = 0
	
	for tc in aux.Next(g) do
		-- เช็คว่าเป็น Xyz ไหม ถ้าใช่ให้ดึงค่า Rank ถ้าไม่ใช่ให้ดึง Level
		if tc:IsType(TYPE_XYZ) then
			local rank = tc:GetRank()
			if rank > 0 then sum_lvl = sum_lvl + rank end
		else
			local lvl = tc:GetLevel()
			if lvl > 0 then sum_lvl = sum_lvl + lvl end
		end
	end
	
	-- นำจำนวนดาว/แรงค์รวม มาคูณ 200
	return sum_lvl * 200
end