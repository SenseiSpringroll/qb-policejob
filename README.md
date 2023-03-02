# qb-policejob with integrated Ped garage interaction and multi-department
[QB-Policejob]

Edited version of the original https://github.com/qbcore-framework/qb-policejob

#This is my first attempt at editing a resource to this degree so the code is probably a little messy, I apologize.


This edit of qb-policejob Includes mobile finger scanner. Made usage of Randolio's mobile finger scanner, just broke it down into snippets and integrated it in https://github.com/Randolio/randol_fingerprint and Includes Ped interaction and Supports multi-Department as well

#installation

make sure you have setr UseTarget true in your server.cfg

Started adding compatibility with mz-skills for numerous oncoming features!
https://github.com/MrZainRP/mz-skills

Can set mz-skills to false in Config if you dont want to use it

Add this to qbcore/shared/items.lua
```lua
["policetablet"] = { ["name"] = "policetablet", ["label"] = "Police Tablet", ["weight"] = 5000, ["type"] = "item", ["image"] = "policetablet.png", ["unique"] = true, ['useable'] = true, ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "A mobile fingerprint tablet." },
```

copy the policetablet.png from qb-policejob/html and paste it into qb-inventory/html/images ( or whatever inventory you use )

To make a new department simply add them into your qb-core/shared/jobs.lua and put the "type = leo" for example

```lua
	['police'] = {
		label = 'Law Enforcement',
        type = "leo",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            ['0'] = {
                name = 'Recruit',
                payment = 50
            },
			['1'] = {
                name = 'Officer',
                payment = 75
            },
			['2'] = {
                name = 'Sergeant',
                payment = 100
            },
			['3'] = {
                name = 'Lieutenant',
                payment = 125
            },
			['4'] = {
                name = 'Chief',
				isboss = true,
                payment = 150
            },
        },
    },
    ['sheriff'] = {
		label = 'Blaine County Sheriff',
        type = "leo",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            ['0'] = {
                name = 'Recruit',
                payment = 50
            },
			['1'] = {
                name = 'Officer',
                payment = 75
            },
			['2'] = {
                name = 'Sergeant',
                payment = 100
            },
			['3'] = {
                name = 'Lieutenant',
                payment = 125
            },
			['4'] = {
                name = 'Chief',
				isboss = true,
                payment = 150
            },
        },
    },
```

And that's it. The rest is already done.



Update 1.0
- Fully added multi-department support
- check to see if you have warrants through ps-mdt
- updated blip support to support multi
- updated evidence to see at a farther range rather than standing directly on it
- Added Ped integration on/off duty
- added Ped integration for armory
- both of the above ped integrations come with MRPD and gabz paleto locations preconfigured.
- Short little preview as well https://streamable.com/wsrixc

Update 1.1
- Fixed the blips issue
- added break free of cuff function
- added a skill config option with mz-skills the higher the criminals skill level is the easier
It will be for them to beat the minigame for breaking free. More will be added to benefit police in the future!
- Kind of added Helicopter spawn ped. It works but not the way I want it to


