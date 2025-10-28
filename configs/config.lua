-----------------------------------------------------
-- Configuração Principal de Assalto
-----------------------------------------------------
Config = {}

-- Definir Idioma
Config.defaultlang = 'pt_lang'
-----------------------------------------------------

Config.Keys = {
    Loot = 0x760A9C6F, -- [G]
}
-----------------------------------------------------

-- Configuração do Webhook do Discord
Config.Webhook = {
    URL = '',
    Title = 'BCC-Waves-Itska',
    Avatar = ''
}
-----------------------------------------------------

Config.RobberyCommand = 'waves' -- comando para ativar assaltos
-----------------------------------------------------

Config.RobberyCooldown = 999 -- Tempo em minutos antes que o local possa ser assaltado novamente
-----------------------------------------------------

Config.AreaRadius = 100.0 -- Raio da área de assalto em unidades (para blip)
-----------------------------------------------------

Config.EnemyWaveDelay = 10 -- Tempo em segundos entre ondas de inimigos
Config.FirstWaveDelay = 10 -- Tempo em segundos antes da primeira onda de inimigos aparecer
-----------------------------------------------------

Config.EnemyWaves = {10, 5, 10, 5, 10} -- Número de inimigos por onda (ex.: {3, 3, 3, 5, 5} significa 5 ondas: primeiras 3 com 3 inimigos, últimas 2 com 5 inimigos)
-----------------------------------------------------

Config.Jobs = {
    Prohibited = {} -- Lista de empregos proibidos para iniciar assaltos (ex.: {'police', 'sheriff'})
}
-----------------------------------------------------

-- --Configuração de Arrombamento
-- Config.LockPick = {
--     MaxAttemptsPerLock = 7,
--     lockpickitem = 'lockpick',
--     difficulty = 10,
--     hintdelay = 500,
--     volume = 0.5, -- Volume do som de arrombamento (0.0 a 1.0)
--     pins = { -- pinos codificados, se randomPins definido como true, então isso será ignorado.
--         {
--             deg = 25 -- 0-360 graus
--         },
--         {
--             deg = 0 -- 0-360 graus
--         },
--         {
--             deg = 300 -- 0-360 graus
--         }
--     },
--     randomPins = true --Se definido como True, então os pinos acima serão ignorados.
-- }
-----------------------------------------------------

-- Config.Alerts = {
--     Police = {
--         name = 'bcc-waves-itskaaas-police', --O nome do alerta
--         command = '', -- o comando, isso é o que os jogadores usarão com /
--         message = 'Estão roubando um comércio!', -- Mensagem para mostrar à polícia
--         messageTime = 40000, -- Tempo que a mensagem ficará na tela (milissegundos)
--         jobs = {}, -- Trabalho para o qual o alerta é destinado
--         jobgrade =
--         {
--             -- Nenhum trabalho para alertar
--
--         }, -- Quais graus o alerta afetará
--         icon = 'star', -- O ícone que o alerta usará
--         color = 'COLOR_GOLD', -- A cor do ícone / https://github.com/femga/rdr3_discoveries/tree/master/useful_info_from_rpfs/colours
--         texturedict = 'generic_textures', --https://github.com/femga/rdr3_discoveries/tree/master/useful_info_from_rpfs/textures/menu_textures
--         hash = -1282792512, -- O raio do blip
--         radius = 40.0, -- O tamanho do raio do blip
--         blipTime = 60000, -- Quanto tempo o blip ficará para o trabalho (milissegundos)
--         blipDelay = 5000, -- Tempo de atraso antes que o trabalho seja notificado (milissegundos)
--         originText = '', -- Texto exibido ao usuário que executou o comando
--         originTime = 0 -- O tempo que o origintext é exibido (milissegundos)
--     },
-- }
