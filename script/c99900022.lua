-- Nikke Mica
-- ID: 99900022
local s,id=GetID()
local NIKKE_SET_ID = 0xc02

function s.initial_effect(c)
	-- 1. Special Summon from Hand
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- 2. Search Level 3 or lower (Deck/GY)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- 3. Synchro Shortcut (Full Fixed)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTarget(s.syntg)
	e4:SetOperation(s.synop)
	c:RegisterEffect(e4)
	
	-- 4. Treated as a Tuner
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetCode(EFFECT_ADD_TYPE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetValue(TYPE_TUNER)
	c:RegisterEffect(e5)

	-- 5. Can be treated as Non-Tuner
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCode(EFFECT_NONTUNER)
	e6:SetValue(s.ntval)
	c:RegisterEffect(e6)
end

-- Logic: Non-Tuner check
function s.ntval(c,sc,tp) 
	return not sc or sc:IsSetCard(NIKKE_SET_ID) 
end

-- ==================================================================
-- Effect 1: Self Summon
-- ==================================================================
function s.spfilter(c) return c:IsFaceup() and c:IsSetCard(NIKKE_SET_ID) end
function s.spcon(e,c)
	if c==nil then return true end
	return Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,c:GetControler(),LOCATION_MZONE,0,1,nil)
end

-- ==================================================================
-- Effect 2: Search (Deck or GY)
-- ==================================================================
function s.thfilter(c) 
	return c:IsSetCard(NIKKE_SET_ID) and c:IsLevelBelow(3) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand() 
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ==================================================================
-- Effect 3: Synchro Shortcut (Improved Logic)
-- ==================================================================

-- Filter เพื่อนที่จะเอามาถู: ต้องเป็น Machine / ส่งลงสุสานได้ / และ *ต้องเป็นวัตถุดิบซินโครได้*
function s.matfilter(c)
	return c:IsRace(RACE_MACHINE) 
		and c:IsAbleToGrave() 
		and c:IsCanBeSynchroMaterial()
end

-- Filter ตัว Synchro ปลายทาง: เช็คว่าลงได้ไหม โดยคำนวณช่องที่จะว่างลงจากการเอามอนสเตอร์กลุ่ม mg ออกไป
function s.synchrofilter(c,e,tp,mg)
	return c:IsSetCard(NIKKE_SET_ID) and c:IsType(TYPE_SYNCHRO)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,mg,c)>0 -- เช็คช่องโดยสมมติว่า mg หายไปแล้ว
end

function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		-- เงื่อนไข Target:
		-- 1. ตัวเองต้องส่งลงสุสานได้ และเป็นวัตถุดิบได้
		if not (c:IsAbleToGrave() and c:IsCanBeSynchroMaterial()) then return false end
		
		-- 2. ต้องมีเพื่อน (Machine) บนสนามที่ไม่ใช่ตัวเอง (Exclude c)
		local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,c)
		if #g==0 then return false end
		
		-- 3. ต้องมีตัว Synchro ใน Extra ที่เรียกออกมาได้ (โดยคำนวณช่องว่างจาก c ไปก่อนเป็นขั้นต่ำ)
		return Duel.IsExistingMatchingCard(s.synchrofilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_MZONE)
end

function s.synop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- ถ้าตัวเราไม่อยู่บนสนามแล้ว ให้ยกเลิกผล
	if not c:IsRelateToEffect(e) then return end

	-- 1. เลือกเพื่อน 1 ใบ (บังคับเลือกจาก MZone, ห้ามเลือกตัวเอง)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_MZONE,0,1,1,c)
	
	if #g>0 then
		g:AddCard(c) -- รวมร่าง: เพื่อน + เรา
		
		-- 2. เลือกตัว Synchro (โดยคำนวณช่องว่างจากกลุ่ม g ทั้ง 2 ใบ)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc_group=Duel.SelectMatchingCard(tp,s.synchrofilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,g)
		local sc=sc_group:GetFirst()
		
		if sc then
			-- Set Material: ผูกวัตถุดิบ
			sc:SetMaterial(g)
			
			-- ส่งลงสุสาน (Reason Synchro -> Animation Trigger!)
			if Duel.SendtoGrave(g,REASON_EFFECT+REASON_MATERIAL+REASON_SYNCHRO) > 0 then
				
				-- เช็คอีกรอบเพื่อความชัวร์ว่าลงได้ (กันเหนียว)
				if Duel.GetLocationCountFromEx(tp,tp,nil,sc) > 0 then
					Duel.BreakEffect()
					Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
					sc:CompleteProcedure()
				end
			end
		end
	end
end