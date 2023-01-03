ESX = nil

ESX = exports['es_extended']:getSharedObject()

function dodajPomoc(identifier,money)
  if not identifier then return end
  local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
  local money = math.floor(tonumber(money))
  if xPlayer then
      print("[^1"..GetCurrentResourceName().."^7] Dajem socijalnu pomoc "..GetPlayerName(xPlayer.source).." - "..identifier.." ("..tostring(money).."KM)")
      TriggerClientEvent('okokNotify:Alert', source, { type = "sucess", message = "Dobili ste socijalnu pomoć u iznosu od: " ..tostring(money), time = 5000, title = "BANKA" })
      xPlayer.addAccountMoney("bank", math.floor(money))
  else
      print("[^1"..GetCurrentResourceName().."^7] Problem se desio pokušavajući dati socijalnu pomoć "..identifier.." ("..tostring(money).."KM). Igrac je offline. Forsiram preko databaze.")
          MySQL.Async.fetchAll('SELECT accounts FROM users WHERE identifier = @identifier', { ["@identifier"] = identifier }, function(result)
    if result[1] ~= nil then
      local accs = json.decode(result[1].accounts)

      accs.bank = accs.bank + money

      MySQL.Async.execute("UPDATE users SET accounts = @newBank WHERE identifier = @identifier",
        {
          ["@identifier"] = identifier,
          ["@newBank"] = json.encode(accs)
        }
      )
    end
  end)
  end
end

function dodajPlatu(identifier, posao, cin)
  if not identifier then return end
  local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
  local money = MySQL.Async.fetchAll('SELECT salary FROM job_grades WHERE job_name = @job AND grade = @grade', {
  ['@job'] = posao,
  ['@grade'] = cin
  }, function(data)
  local salary = data[1].salary
  if xPlayer then
      print("[^1"..GetCurrentResourceName().."^7] Dajem platu "..GetPlayerName(xPlayer.source).." - "..identifier.." ("..tostring(salary).."KM)")
      TriggerClientEvent('okokNotify:Alert', source, { type = "sucess", message = "Dobili platu u iznosu od: " ..salary, time = 5000, title = "BANKA" })
      xPlayer.addAccountMoney("bank", math.floor(salary))
  else
               print("[^1"..GetCurrentResourceName().."^7] Problem se desio pokušavajući dati platu "..identifier.." ("..tostring(salary).."KM). Igrac je offline. Forsiram preko databaze.")
                  MySQL.Async.fetchAll('SELECT accounts FROM users WHERE identifier = @identifier', { ["@identifier"] = identifier }, function(result)
    if result[1] ~= nil then
      local accs = json.decode(result[1].accounts)

      accs.bank = accs.bank + salary

      MySQL.Async.execute("UPDATE users SET accounts = @newBank WHERE identifier = @identifier",
        {
          ["@identifier"] = identifier,
          ["@newBank"] = json.encode(accs)
        }
      )
    end
  end)
  end
  end)
end

function kreniplate(d,h,m)
  print('[^1Plate^7] ^7Plate stizu')
  CreateThread(function()
  local result = MySQL.query.await('SELECT * FROM users', {r})
  if result then
      for _, v in pairs(result) do
          --print(v.identifier, v.firstname, v.lastname, v.job, v.job_grade)
          if v.job == 'unemployed' or v.job == 'nezaposlen' or v.job == 'nezaposljen' then
              dodajPomoc(v.identifier, 50)        
          else
              dodajPlatu(v.identifier, v.job, v.job_grade)
          end
      end
  end
end)
end

Citizen.CreateThread(function()
  for i=0,23 do
      TriggerEvent("cron:runAt",i,0,runMoneyCoroutines)
  end
  print("[^6"..GetCurrentResourceName().."^7] Nemoj restartat boga ti dragog allaha")
end)
