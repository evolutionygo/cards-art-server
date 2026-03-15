-- Burst: Laplace Buster (ID: 99900020)
local s,id=GetID()
local LAPLACE_ID = 99900019

function s.initial_effect(c)
	-- Activate & Equip
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	
	-- Equip Limit
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EQUIP_LIMIT)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetValue(s.eqlimit)
	c:RegisterEffect(e2)
	
	-- 3. Cannot Attack
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_CANNOT_ATTACK)
	c:RegisterEffect(e3)
end

function s.eqlimit(e,c)
	return c:IsCode(LAPLACE_ID)
end

function s.filter(c)
	return c:IsCode(LAPLACE_ID) and c:IsFaceup() and c:GetAttackAnnouncedCount()==0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	
	if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		if Duel.Equip(tp,c,tc) then
			-- 1. บันทึกค่าพลังโจมตี
			local recorded_atk = tc:GetAttack()
			if recorded_atk < 0 then recorded_atk = 0 end
			c:RegisterFlagEffect(id+100,RESET_EVENT+RESETS_STANDARD,0,1,recorded_atk)
			
			-- 2. บันทึกเลขเทิร์น
			c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,Duel.GetTurnCount())
			
			-- 3. Trigger Effects (Battle Phase / End Phase)
			local e1=Effect.CreateEffect(c)
			e1:SetDescription(aux.Stringid(id,1))
			e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
			e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
			e1:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
			e1:SetRange(LOCATION_SZONE)
			e1:SetCountLimit(1)
			e1:SetLabelObject(tc)
			e1:SetCondition(s.boomcon)
			e1:SetOperation(s.boomop)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e1)
			
			local e2=e1:Clone()
			e2:SetCode(EVENT_PHASE+PHASE_END)
			c:RegisterEffect(e2)
			
			Duel.Hint(HINT_NUMBER,tp,recorded_atk)
		end
	end
end

function s.boomcon(e,tp,eg,ep,ev,re,r,rp)
	local start_turn = e:GetHandler():GetFlagEffectLabel(id)
	return e:GetHandler():IsLocation(LOCATION_SZONE) 
		and start_turn 
		and Duel.GetTurnCount() > start_turn
end

-- Logic ใหม่: ยิงเลเซอร์ (ปรับปรุง)
function s.boomop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=e:GetLabelObject() -- ตัว Laplace ที่สวมอยู่
	
	-- ดึง dmg ที่บันทึกไว้
	local dmg = c:GetFlagEffectLabel(id+100)
	if not dmg then dmg = 0 end
	
	if not c:IsRelateToEffect(e) then return end
	
	-- 1. ทำลายตัวเองก่อน (ยิงออกไป)
	if Duel.Destroy(c,REASON_EFFECT) > 0 then
		
		-- เช็ค Laplace ว่ายังอยู่ไหม
		if tc and tc:IsFaceup() and tc:IsLocation(LOCATION_MZONE) then
			
			-- หา "มอนสเตอร์ฝ่ายตรงข้าม" ที่ขวางทางอยู่ (ไม่นับเวท/กับดัก)
			local g = tc:GetColumnGroup():Filter(function(c) 
				return c:IsControler(1-tp) and c:IsType(TYPE_MONSTER) 
			end, nil)
			
			if #g == 0 then
				-- กรณี A: ช่องว่าง (ไม่มีมอนสเตอร์ขวาง) -> Damage เต็ม (100%)
				if dmg > 0 then 
					Duel.Damage(1-tp,dmg,REASON_EFFECT) 
				end
				
			else
				-- กรณี B: มีมอนสเตอร์ขวาง -> ทำลาย
				Duel.BreakEffect()
				local ct = Duel.Destroy(g,REASON_EFFECT)
				
				if ct > 0 then
					-- B1: ทำลายสำเร็จ -> Damage ครึ่งเดียว (50%)
					local half_dmg = math.floor(dmg/2)
					if half_dmg > 0 then
						Duel.Damage(1-tp,half_dmg,REASON_EFFECT)
					end
				else
					-- B2: ทำลายไม่สำเร็จ (ct=0) -> ไม่สร้าง Damage (ตามเงื่อนไข)
				end
			end
		end
	end
end