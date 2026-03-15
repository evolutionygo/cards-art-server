-- Tactical Nikke Eunhwa 
-- ID: 99900013
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	-- 1. On Summon: Send Highest Stat to GY + Burn
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)

	-- 2. Sniper Zone (Continuous Negate + Burn punishment)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.negcon)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-- ==================================================================
-- Logic 1: Send Highest Stat
-- ==================================================================
function s.tgfilter(c)
	return c:IsFaceup() and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,1-tp,LOCATION_MZONE)
	if Duel.GetFlagEffect(tp,99900009)>0 then -- เช็คว่า Nikke TACTICAL! ทำงานหรือยัง
		Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0) 
	end
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.tgfilter,tp,0,LOCATION_MZONE,nil)
	if #g==0 then return end
	local max_stat = 0
	for tc in aux.Next(g) do
		local val = math.max(tc:GetAttack(), tc:GetDefense())
		if val > max_stat then max_stat = val end
	end
	local sg = g:Filter(function(c) return math.max(c:GetAttack(), c:GetDefense()) == max_stat end, nil)
	if #sg>0 then
		local tc = sg:Select(tp,1,1,nil):GetFirst()
		local val = math.max(tc:GetAttack(), tc:GetDefense())
		if Duel.SendtoGrave(tc,REASON_EFFECT)~=0 and Duel.GetFlagEffect(tp,99900009)>0 then
			if val > 0 then
				Duel.Damage(1-tp,val/2,REASON_EFFECT)
			end
		end
	end
end

-- ==================================================================
-- Logic 2: Continuous Negate (Hand/GY) + [UPDATED] Burn
-- ==================================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local loc=re:GetActivateLocation()
	-- เงื่อนไข: คู่แข่งใช้จากมือ/สุสาน + Eunhwa ยังไม่ตาย
	return rp==1-tp 
		and (loc==LOCATION_HAND or loc==LOCATION_GRAVE)
		and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) 
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	-- หาการ์ดบนสนามฝ่ายตรงข้ามที่ส่งลงสุสานได้
	local g=Duel.GetMatchingGroup(Card.IsAbleToGrave,1-tp,LOCATION_ONFIELD,0,nil)
	
	local paid = false
	if #g>0 then
		-- ถามฝ่ายตรงข้ามว่าจะส่งลงสุสานไหม?
		if Duel.SelectYesNo(1-tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_TOGRAVE)
			local sg=g:Select(1-tp,1,1,nil)
			if #sg>0 then
				-- ถ้าส่งสำเร็จ
				if Duel.SendtoGrave(sg,REASON_EFFECT) > 0 then
					paid = true
					
					-- [NEW] ตรวจสอบว่าใบที่ส่งไปเป็นมอนสเตอร์หรือไม่
					local tc = sg:GetFirst()
					if tc:IsLocation(LOCATION_GRAVE) and tc:IsType(TYPE_MONSTER) then
						-- หาค่า Original ATK/DEF
						local base_atk = tc:GetBaseAttack()
						local base_def = tc:GetBaseDefense()
						-- กันค่าติดลบ (กรณี ? ATK)
						if base_atk < 0 then base_atk = 0 end
						if base_def < 0 then base_def = 0 end
						
						-- คำนวณดาเมจ (ครึ่งหนึ่งของค่าสูงสุด)
						local dmg = math.max(base_atk, base_def) / 2
						
						if dmg > 0 then
							Duel.BreakEffect() -- ตัด Effect เพื่อให้ Damage เกิดทีหลัง
							Duel.Damage(1-tp, dmg, REASON_EFFECT)
						end
					end
				end
			end
		end
	end
	
	-- ถ้าไม่จ่าย (ไม่ส่ง หรือไม่มีให้ส่ง) -> Negate
	if not paid then
		Duel.Hint(HINT_CARD,0,id)
		Duel.NegateEffect(ev) 
	end
end