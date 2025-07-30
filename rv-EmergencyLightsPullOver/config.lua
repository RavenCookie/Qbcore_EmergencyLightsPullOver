Config = {}

-- Distance at which AI vehicles will react to emergency vehicles
Config.DetectionRadius = 100.0

-- How far AI vehicles will pull over to the side (in meters)
Config.PullOverDistance = 3.0

-- How long AI vehicles stay pulled over after emergency vehicle passes (in ms)
Config.StayPulledOverTime = 5000

-- How aggressively vehicles move to the side of the road (1.0 = normal, 2.0 = faster/more aggressively)
Config.PullOverAggressiveness = 2.0

-- One-way lane settings
Config.OneWayLaneEnabled = true -- Enable special handling for one-way lanes
Config.OneWayPullOverThreshold = 25.0 -- Distance from lane edge to determine pull-over direction

-- Minimum distance to the edge of the road to trigger pull-over
Config.MinDistanceToEdge = 5.0 -- Changed from 10.0 to 5.0 (approximately 15 feet)

Config.MaxDistanceToEdge = 20.0 -- Changed from 25.0 to 20.0 (approximately 60 feet)

-- Minimum distance to the emergency vehicle to trigger pull-over
Config.MinDistanceToEmergencyVehicle = 10.0 -- Changed from 15.0 to 10.0 (approximately 30 feet)

-- Minimum speed for vehicles to pull over (in km/h)
Config.MinSpeed = 40.0 -- Changed from 10.0 to 20.0 (approximately 30 mph)

-- Maximum speed of AI vehicles when pulling over (in mph)
Config.MaxSpeed = 5.0 -- Changed from 20.0 to 5.0 (approximately 5 mph)

-- Enable honking when pulling over in the middle of the road
Config.HonkHorn = true

-- Debug mode
Config.Debug = false
