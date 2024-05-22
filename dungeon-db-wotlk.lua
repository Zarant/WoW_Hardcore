-- dungeon-db-wotlk.lua
-- Dungeon database for the dungeon tracker
-- Written by Frank de Jong


-- dt_db ( = dungeon tracker database )
--
-- Contains all the info for the dungeons:
-- { instanceMapID, zoneID, "English Name", type = { "D", "R", "B", "O" }, max_players, max_runs, { max_level_era, max_level_wotlk }, { quests }, { bosses } },
-- Types: D = dungeon (5-player), R = raid, B = battleground, O = other

-- The following dungeon table was compiled with help from @Jordynna (thanks!) and @Flayz
-- Note that quests that can be completed inside the instance have been removed, as they can lead to double runs,
-- when the player's client crashes after turning them in inside the dungeon.

dt_db = {

	-- Era dungeons
	{ 389, 2437, "Ragefire Chasm", "D", 5, 1, { 18, 20 },
				{ 5728, 5761, 5723, 5724, 5725 }, 			-- "Searching for the lost satchel" replaced by "Returning the Lost satchel" because the former can be finished inside
				{{"Bazzalan",11519}, {"Taramagan the Hungerer",11520}, {"Oggleflint",11517}, {"Jergosh the Invoker",11518}}
	},
	{ 43, 718, "Wailing Caverns", "D", 5, 1, { 24, 24 },
				{ 914, 1487, 3366 },			-- Leaders of the Fang, Deviate Eradication, The Glowing Shard
				{{"Mutanus",3654}, {"Kresh",3653}, {"Lady Anacondra",3671}, {"Lord Cobrahn",3669}, {"Lord Pythas",3670}, {"Skum",3674}, {"Lord Serpentis",3673}, {"Verdan the Everliving",5775}}
	}, 
	{ 36, 1581, "The Deadmines", "D", 5, 1, { 26, 24 },
				{ 2040, 166, 373 }, 					-- Underground Assault, The Defias Brotherhood, The Unsent Letter
				{{"Edwin VanCleef",639}, {"Rhahk'Zor",644}, {"Sneed's Shredder",642}, {"Gilnid",1763}, {"Mr. Smite",646}, {"Captain Greenskin",647}, {"Cookie",645}}
	},
	{ 33, 209, "Shadowfang Keep", "D", 5, 1, { 30, 25 },
				{ 1013, 1014 }, -- The Book of Ur, Arugal Must Die // Deathstalkers in Shadowfang removed (inside completion)
				{{"Archmage Arugal",4275}, {"Rethilgore",3914}, {"Razorclaw the Butcher",3886}, {"Baron Silverlaine",3887}, {"Commander Springvale",4278}, {"Odo the Blindwatcher",4279}, {"Fenrus the Devourer",4274}, {"Wolf Master Nandos",3927}}
	},
	{ 48, 719, "Blackfathom Deeps", "D", 5, 1, { 32, 28 },
				{ 971, 1199, 6565, 6921, 1200, 6561, 6922 },		-- 1198 removed (inside completion)
				{{"Aku'mai",4829}, {"Ghamoo-ra",4887}, {"Lady Sarevess",4831}, {"Gelihast",6243}, {"Lorgus Jett",12902}, {"Twilight Lord Kelris",4832}, {"Old Serra'kis",4830}}
	},				
	{ 34, 717, "The Stockade", "D", 5, 1, { 32, 29 },
				{ 387, 386, 378, 388, 377, 391 },
				{{"Bazil Thredd",1716}, {"Targorr the Dread",1696}, {"Kam Deepfury",1666}, {"Hamhock",1717}, {"Dextren Ward",1663}}
	},
	{ 47, 491, "Razorfen Kraul", "D", 5, 1, { 38, 31 },
				{ 1221, 1102, 1109, 1101, 1142, 6522 },			-- 1144 removed (inside completion)
				{{"Charlga Razorflank",4421}, {"Roogug",6168}, {"Aggem Thorncurse",4424}, {"Death Speaker Jargba",4428}, {"Overlord Ramtusk",4420}, {"Agathelos the Raging",4422}}
	},
	{ 90, 721, "Gnomeregan", "D", 5, 1, { 38, 32 },
				{ 2904, 2924, 2930, 2929, 2841 },		-- 2945, 2951 removed (inside completion), 2929 removed (outside quest)
				{{"Mekgineer Thermaplugg",7800}, {"Grubbis ",7361}, {"Viscous Fallout",7079}, {"Electrocutioner 6000",6235}, {"Crowd Pummeler 9-60",6229}}
	},
	{ 129, 722, "Razorfen Downs", "D", 5, 1, { 46, 41 },
				{ 3636, 3341 },								-- 3525 removed (inside completion)
				{{"Amnennar the Coldbringer",7358}, {"Tuten'kash",7355}, {"Mordresh Fire Eye",7357}, {"Glutton",8567}}
	},
	{ 189, 796, "Scarlet Monastery", "D", 5, 1, { 45, 44 },
				{}, 
				{} 																-- Empty boss list allows logging of bosses in the wings (do not touch!)
	},			
	{ 18901, 79601, "Scarlet Monastery (GY)", "D", 5, 1, { 45, 44 }, 	 		-- Bit of a hack here, the 4 wings don't have a separate ID, so we fake one for them
				{},																-- No quests in GY
				{ {"Bloodmage Thalnos", 4543}, {"Interrogator Vishas", 3983} }
	}, 
	{ 18902, 79602, "Scarlet Monastery (Lib)", "D", 5, 1, { 45, 44 },
				{ 1050, 1053, 1049, 1048, 1160, 1951 }, 						-- 1048+1053: kill 4 bosses needs Lib+Cath+Arm
				{ {"Arcanist Doan", 6487}, {"Houndmaster Loksey", 3974} }
	}, 
	{ 18903, 79603, "Scarlet Monastery (Cath)", "D", 5, 1, { 45, 44 },
				{ 1053, 1048 },													-- 1048+1053: kill 4 bosses needs Lib+Cath+Arm
				{ {"Scarlet Commander Mograine", 3976}, {"High Inquisitor Whitemane", 3977}, {"High Inquisitor Fairbanks", 4542 } } 
	},
	{ 18904, 79604, "Scarlet Monastery (Arm)", "D", 5, 1, { 45, 44 },
				{ 1053, 1048 },													-- 1048+1053: kill 4 bosses needs Lib+Cath+Arm
				{ {"Herod", 3975} } 
	},
	{ 70, 1137, "Uldaman", "D", 5, 1, { 51, 44 },
				{ 2240, 1139, 2204 },											-- 2278 removed (inside completion)
				{{"Archaedas",2748}, {"Revelosh",6910}, {"Ironaya",7228}, {"Obsidian Sentinel",7023}, {"Ancient Stone Keeper",7206}, {"Galgann Firehammer",7291}, {"Grimlok",4854}}
	},
	{ 209, 1176, "Zul'Farrak", "D", 5, 1, { 54, 50 },
				{ 3042, 2865, 2846, 2768, 2770, 3527, 2991, 2936 },
				{{"Chief Ukorz Sandscalp",7267}, {"Ruuzlu",7797}, {"Antu'sul",8127}, {"Theka the Martyr",7272}, {"Witch Doctor Zum'rah",7271}, {"Nekrum Gutchewer",7796}, {"Shadowpriest Sezz'ziz",7275}, {"Sergeant Bly",7604}, {"Hydromancer Velratha",7795}}
	},
	{ 349, 2100, "Maraudon", "D", 5, 1, { 55, 52 },
				{ 7041, 7029, 7065, 7064, 7067 },							-- 7044+7046 removed (inside completion)
				{{"Princess Theradras",12201}, {"Noxxion",13282}, {"Razorlash",12258}, {"Lord Vyletongue",12236}, {"Celebras the Cursed",12225}, {"Landslide",12203}, {"Tinkerer Gizlock",13601}, {"Rotgrip",13596}}
	},
	{ 109, 1477, "The Temple of Atal'Hakkar", "D", 5, 1, { 60, 54 },
				{ 3528 },  										-- 1475, 4143, 4146, removed: tablets and haze drop outside; 3446+3373+3447 removed (inside completion)
				{{"Shade of Eranikus",5709}, {"Atal'alarion",8580}, {"Dreamscythe",5721}, {"Weaver",5720}, {"Jammal'an the Prophet",5710}, {"Ogom the Wretched",5711}, {"Morphaz",5719}, {"Hazzas",5722}, {"Avatar of Hakkar",8443}}
	},
	{ 229, 1583, "Blackrock Spire",	"D", 10, 1, { 60, 62 },
				{ 4701, 4724, 4903, 4862, 4729, 4788, 4768, 4974, 4764, 5102, 6821 }, 	-- 4982+5001+7761 removed (inside completion)
				{{"General Drakkisath",10363}, {"Highlord Omokk",9196}, {"Shadow Hunter Vosh'gajin",9236}, {"War Master Voone",9237}, {"Mor Grayhoof",16080}, {"Mother Smolderweb",10596},
						{"Urok Doomhowl",10584}, {"Quartermaster Zigris",9736}, {"Halycon",10220}, {"Gizrul the Slavener",10268},{"Overlord Wyrmthalak",9537},
						{"Pyroguard Emberseer",9816}, {"Solakar Flamewreath",10264}, {"Goraluk Anvilcrack",10899}, {"Warchief Rend Blackhand",10429}, {"Gyth",10339}, {"The Beast",10430} 
				}
	}, -- UBRS and LBRS are one instance
	{ 230, 1584, "Blackrock Depths", "D", 5, 1, { 60, 60 },
				{ 4136, 4123, 4286, 4126, 4081, 4134 },
				{{"Emperor Dagran Thaurissan",9019}, {"Lord Roccor",9025}, {"Bael'Gar",9016}, {"Houndmaster Grebmar",9319}, {"High Interrogator Gerstahn",9018}, {"High Justice Grimstone",10096}, 
						{"Pyromancer Loregrain",9024}, {"General Angerforge",9033}, {"Golem Lord Argelmach",8983}, 
						{"Ribbly Screwspigot",9543}, {"Hurley Blackbreath",9537}, {"Plugger Spazzring",9499}, {"Phalanx",9502}, 
						{"Lord Incendius",9017}, {"Fineous Darkvire",9056}, {"Warder Stilgiss",9041}, {"Ambassador Flamelash",9156}, {"Magmus",9938}, 
						{"Princess Moira Bronzebeard",8929}}
	},
	{ 289, 2057, "Scholomance", "D", 5, 1, { 60, 62 },
				{ 5529, 5582, 5382, 5384, 5466, 5343, 5341 },
				{{"Darkmaster Gandling",1853}, {"Kirtonos the Herald",10506}, {"Jandice Barov",10503}, {"Rattlegore",11622}, {"Marduk Blackpool",10433}, {"Vectus",10432}, {"Ras Frostwhisper",10508}, {"Instructor Malicia",10505}, {"Doctor Theolin Krastinov",11261}, {"Lorekeeper Polkelt",10901}, {"The Ravenian",10507}, {"Lord Alexei Barov",10504}, {"Lady Ilucia Barov",10502}}
	},
	{ 429, 2557, "Dire Maul", "D", 5, 1, { 60, 62 },
				{ 7488, 7489, 7441, 5526 },				-- 7461+7462+7703 removed (inside completion)
				{ {"King Gordok",11501},{"Pusillin",14354},{"Lethendris",14327}, {"Hydrospawn",13280}, {"Zevrim Thornhoof",11490},{"Alzzin the Wildshaper",11492},
					{"Guard Mol'dar",14326},{"Stomper Kreeg",14322},{"Guard Fengus",14321},{"Guard Slip'kik",14323},{"Captain Kromcrush",14325},{"Cho'Rush the Observer",14324},
					{"Tendris Warpwood",11489},{"Magister Kalendris",11487},{"Tsu'zee",11467},{"Illyanna Ravenoak",11488},{"Immol'thar",11496},{"Prince Tortheldrin",11486},
				}
	},
	{ 329, 2017, "Stratholme", "D",	5, 1, { 60, 62 },
				{ 5282, 5214, 5251, 5262, 5848, 5212, 5263, 5243, 6163 },			-- 5122+5463+8945 removed (inside completion)
				{ {"Baron Rivendare",10440},
					{"Fras Siabi",11058}, {"The Unforgiven",10516}, {"Postmaster Malown",11143},{"Timmy the Cruel",10808},
					{"Malor the Zealous",11032},{"Cannon Master Willey",10997}, {"Crimson Hammersmith",11120}, {"Archivist Galford",10811},{"Balnazzar",10813},
					{"Magistrate Barthilas",10435},{"Nerub'enkan",10437}, {"Baroness Anastari",10436}, {"Maleki the Pallid",10438},{"Ramstein the Gorger",10439}
				}
	}, -- Undead / Live parts are one instance

	-- Era Raids
	{ 249, 2159, "Onyxia's Lair", "R", 40, 1000, { 1000, 1000 }, {} },
	{ 309, 1977, "Zul'Gurub", "R", 20, 1000, { 1000, 1000 }, {} },
	{ 409, 2717, "Molten Core", "R", 40, 1000, { 1000, 1000 }, {} },
	{ 469, 2677, "Blackwing Lair", "R", 40, 1000, { 1000, 1000 }, {} },
	{ 509, 3429, "Ruins of Ahn'Qiraj", "R", 20, 1000, { 1000, 1000 }, {} },
	{ 531, 3428, "Ahn'Qiraj", "R", 40, 1000, { 1000, 1000 }, {} },

	-- Era Battlegrounds
	{ 489, 3277, "Warsong Gulch", "B", 10, 1000, { 1000, 1000 }, {} },
	{ 30, 2597, "Alterac Valley", "B", 40, 1000, { 1000, 1000 }, {} },
	{ 529, 3358, "Arathi Basin", "B", 15, 1000, { 1000, 1000 }, {} },

	-- TBC dungeons
	{ 543, 3562, "Hellfire Ramparts", "D", 5, 1, { 1000, 64 }, { 9575, 9572, 9587, 9588 } },
	{ 542, 3713, "The Blood Furnace", "D", 5, 1, { 1000, 65 }, { 9607, 9608, 9589, 9590 } },
	{ 547, 3717, "The Slave Pens", "D", 5, 1, { 1000, 66 }, { 9738 } },
	{ 546, 3716, "The Underbog", "D", 5, 1, { 1000, 66 }, { 9738, 9717, 9719 } }, -- 9715 removed because also drops in Steamvault
	{ 557, 3792, "Mana-Tombs", "D", 5, 1, { 1000, 68 }, { 10216, 10218, 10165 } },
	{ 558, 3790, "Auchenai Crypts", "D", 5, 1, { 1000, 70 }, { 10164, 10167 } }, -- "All remaining TBC dungeons have a MAX level of 70"
	{ 560, 2367, "Old Hillsbrad Foothills", "D", 5, 1, { 1000, 70 }, { 10283, 10284, 10285 } },
	{ 556, 3791, "Sethekk Halls", "D", 5, 1, { 1000, 70 }, { 10097, 10098 } },
	{ 553, 3847, "The Botanica", "D", 5, 1, { 1000, 70 }, { 10704, 10257, 10897 } },
	{ 555, 3789, "Shadow Labyrinth", "D", 5, 1, { 1000, 70 }, { 10885, 10094, 10095, 10091, 10649, 10666, 9831 } },
	{ 545, 3715, "The Steamvault", "D", 5, 1, { 1000, 70 }, { 9763, 9832, 10667, 10885 } },
	{ 540, 3714, "The Shattered Halls", "D", 5, 1, { 1000, 70 }, { 9492, 9495, 9493, 9496, 10670 } },
	{ 554, 3849, "The Mechanar", "D", 5, 1, { 1000, 70 }, { 10704, 10665 } },
	{ 269, 2366, "The Black Morass", "D", 5, 1, { 1000, 70 }, { 10296, 10297, 10298, 9836, 9837, 10902 } },
	{ 552, 3848, "The Arcatraz", "D", 5, 1, { 1000, 70 }, { 9832, 10886 } },
	{ 585, 4131, "Magisters' Terrace", "D", 5, 1, { 1000, 70 }, { 11492, 11499 } },
	-- TBC Raids
	{ 532, 3457, "Karazhan", "R", 10, 1000, { 1000, 1000 }, {} },
	{ 533, 3456, "Naxxramas", "R", 40, 1000, { 1000, 1000 }, {} },
	{ 534, 3606, "Hyjal Summit", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 544, 3836, "Magtheridon's Lair", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 548, 3607, "Serpentshrine Cavern", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 564, 3959, "Black Temple", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 565, 3923, "Gruul's Lair", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 568, 3805, "Zul'Aman", "R", 10, 1000, { 1000, 1000 }, {} },
	{ 580, 4075, "Sunwell Plateau", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 550, 3845, "Tempest Keep", "R", 25, 1000, { 1000, 1000 }, {} },
	-- TBC Battlegrounds
	{ 566, 3820, "The Eye of the Storm", "B", 15, 1000, { 1000, 1000 }, {} },

	-- WotLK dungeons
	{ 574, 206, "Utgarde Keep", "D", 5, 1, { 1000, 74 }, { 11272, 13206, 11262, 13245, 13205, 11252 } },
	{ 576, 4265, "The Nexus", "D", 5, 1, { 1000, 75 }, { 13094, 13095, 11905, 11911, 11973, 13246 } },
	{ 601, 4277, "Azjol-Nerub", "D", 5, 1, { 1000, 76 }, { 13167, 13182, 13254 } },
	{ 619, 4494, "Ahn'kahet: The Old Kingdom", "D", 5, 1, { 1000, 77 }, { 13187, 13204, 13190, 13255 } },
	{ 600, 4196, "Drak'Tharon Keep", "D", 5, 1, { 1000, 78 }, { 12238, 12037, 13129, 13249 } },
	{ 608, 4415, "The Violet Hold", "D", 5, 1, { 1000, 79 }, { 13158, 13159, 13256 } },
	{ 604, 4416, "Gundrak", "D", 5, 1, { 1000, 80 }, { 13098, 13096, 13111, 13250 } },
	{ 599, 4264, "Halls of Stone", "D", 5, 1, { 1000, 80 }, { 13207, 13252 } },
	{ 602, 4272, "Halls of Lightning", "D", 5, 1, { 1000, 80 }, { 13109, 13108, 13244, 13253 } },
	{ 668, 4820, "Halls of Reflection", "D", 5, 1, { 1000, 80 }, { 24713, 24711, 24802, 24500, 24561, 24480 } },
	{ 595, 4100, "The Culling of Stratholme", "D", 5, 1, { 1000, 80 }, { 13151, 13149, 13240, 13251 } },
	{ 575, 1196, "Utgarde Pinnacle", "D", 5, 1, { 1000, 80 }, { 13131, 13132, 13241, 13248 } },
	{ 578, 4228, "The Oculus", "D", 5, 1, { 1000, 80 }, { 13124, 13126, 13127, 13128, 13240, 13247 } },
	{ 650, 4723, "Trial of the Champion", "D", 5, 1, { 1000, 80 }, { 14199 } },
	{ 632, 4809, "The Forge of Souls", "D", 5, 1, { 1000, 80 }, { 24506, 24510, 24511, 24499, 24682, 24683 } },
	{ 658, 4813, "Pit of Saron", "D", 5, 1, { 1000, 80 },{ 24682, 24683, 24507, 24498, 24712, 24710, 24713, 24711, 24559, 24461 }},
	-- WotLK raids
	{ 603, 4273, "Ulduar", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 615, 4493, "The Obsidian Sanctum", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 616, 4500, "The Eye of Eternity", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 624, 4603, "Vault of Archavon", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 631, 4812, "Icecrown Citadel", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 649, 4722, "Trial of the Crusader", "R", 25, 1000, { 1000, 1000 }, {} },
	{ 724, 4987, "Ruby Sanctum", "R", 25, 1000, { 1000, 1000 }, {} },
	-- WotLK Battlegrounds
	{ 628, 4710, "Isle of Conquest", "B", 40, 1000, { 1000, 1000 }, {} },

	-- Other
	--{ 449, "Champion's Hall", 1000, 1000, { 1000, 1000 }, {} },
	--{ 450, "Hall of Legends", 1000, 1000, { 1000, 1000 }, {} },
	--{ , "Borean Tundra", },					-- TO BE DONE, maybe
	--{ , "Strand of the Ancients", },			-- TO BE DONE, maybe
}
