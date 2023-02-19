# qb-policejob with integrated Ped garage interaction and multi-department
[QB-Policejob]

Edited version of the original https://github.com/qbcore-framework/qb-policejob

#This is my first attempt at editing a resource to this degree so the code is probably a little messy, I apologize.


This edit of qb-policejob Includes mobile finger scanner. Made usage of Randolio's mobile finger scanner, just broke it down into snippets and integrated it in https://github.com/Randolio/randol_fingerprint and Includes Ped interaction for garage ( so far ) to take out and store Police Vehicles. Supports multi-Department as well

Slowly working on making armory, on/off duty, stashes, impound etc all Interacted with Peds. So this will be updated in due time. For now it is just Garages.

#installation

Make sure you have your target set to true in server.cfg otherwise this will NOT work

Add this to qbcore/shared/items.lua
```lua
["policetablet"] = { ["name"] = "policetablet", ["label"] = "Police Tablet", ["weight"] = 5000, ["type"] = "item", ["image"] = "policetablet.png", ["unique"] = true, ['useable'] = true, ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "A mobile fingerprint tablet." },
```

copy the policetablet.png from qb-policejob/html and paste it into qb-inventory/html/images ( or whatever inventory you use )

To make a new department simply add them into your qb-core/shared/jobs.lua and put the "type = leo" for example

```lua
['sasp'] = {
		label = 'San Andreas State Police',
        	type = "leo",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            ['0'] = {
                name = 'Probationary Trooper',
                payment = 100
            },
		    ['1'] = {
                name = 'Trooper I',
                payment = 125
            },
	    },
	    ['bcso'] = {
	    	label = 'Blaine County Sheriffs Office',
            	type = "leo",
	    	defaultDuty = true,
	    	offDutyPay = false,
	    	grades = {
                ['0'] = {
                    name = 'Cadet/Probationary',
                    payment = 75
                },
	    	    ['1'] = {
                    name = 'Deputy I',
                    payment = 100
                },
	    },
	    ['lspd'] = {
	    	label = 'Los Santos Police Department',
            	type = "leo",
	    	defaultDuty = true,
	    	offDutyPay = false,
	    	grades = {
                ['0'] = {
                    name = 'Cadet/Probationary',
                    payment = 75
                },
	    	    ['1'] = {
                    name = 'Officer I',
                    payment = 100
            },
        }
    }
}
}
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


