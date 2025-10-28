-----------------------------------------------------
-- Robbery Location Configuration
-----------------------------------------------------
Locations =
 {
    {                                                               -- ARMAZEM VALENTINE
        Id = 1,                                                     --this has to be unique to each robbery
        StartingCoords = vector3(2256.46, -772.11, 42.78),          --coords you have to be near to start the robbery
        Distance = 1,                                               -- Distance from 'StartingCoords' to trigger the robbery
        EnemyNpcs = true,                                           --if true enemy npcs will spawn and attack the player
        NpcModel = 'a_m_m_huntertravelers_cool_01',                 --model of the enemy npc
        EnemyDifficulty = 'easy',                                   --difficulty of enemies: 'easy', 'medium', 'hard'
        WaitBeforeLoot = 300,                                        --wait in seconds before player can loot 0 for none
        LootLocations = {                                           --This is the loot location setup, add as many as youd like
            {                                                       -- Downstairs
                LootCoordinates = vector3(2256.46, -772.11, 42.78), --coordinates of the loot box
                CashReward = math.random(50, 450),                  --amount of cash to reward
                GoldReward = math.random(1, 5),                     --amount of gold to reward
                RolReward = math.random(10, 50),                    --amount of rol to reward
                ItemRewards = {                                     --these are the items it will reward can add as many as youd like
                    {
                        name = 'iron',                              --the name of the item in the database
                        label = 'Iron',
                        count = math.random(1, 5),                  --amount to give
                    },
                },
            },
        },
       
    },

     {                                                               -- ARMAZEM VALENTINE
        Id = 2,                                                     --this has to be unique to each robbery
        StartingCoords = vector3(-46.20, 33.36, 92.27),          --coords you have to be near to start the robbery
        Distance = 1,                                               -- Distance from 'StartingCoords' to trigger the robbery
        EnemyNpcs = true,                                           --if true enemy npcs will spawn and attack the player
        NpcModel = 'a_m_m_huntertravelers_cool_01',                 --model of the enemy npc
        EnemyDifficulty = 'easy',                                   --difficulty of enemies: 'easy', 'medium', 'hard'
        WaitBeforeLoot = 300,                                        --wait in seconds before player can loot 0 for none
        LootLocations = {                                           --This is the loot location setup, add as many as youd like
            {                                                       -- Downstairs
                LootCoordinates = vector3(-46.20, 33.36, 92.27), --coordinates of the loot box
                CashReward = math.random(50, 450),                  --amount of cash to reward
                GoldReward = math.random(1, 5),                     --amount of gold to reward
                RolReward = math.random(10, 50),                    --amount of rol to reward
                ItemRewards = {                                     --these are the items it will reward can add as many as youd like
                    {
                        name = 'iron',                              --the name of the item in the database
                        label = 'Iron',
                        count = math.random(1, 5),                  --amount to give
                    },
                },
            },
        },
       
    },

    
    

}
