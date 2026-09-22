DROP TABLE IF EXISTS room;

CREATE TABLE IF NOT EXISTS room (
    location VARCHAR(100),
    name VARCHAR(100),
    capacity INTEGER NOT NULL,
    price_penny INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (location, name)
);

CREATE INDEX IF NOT EXISTS idx_room_location_name ON room(location, name);

INSERT INTO room (location, name, capacity, price_penny) VALUES
    ('Aberdeen', 'Granite City Boardroom', 16, 48000),
    ('Aberdeen', 'Maritime Conference Suite', 35, 82000),
    ('Aberdeen', 'Oil Capital Meeting Room', 12, 32000),
    
    ('Belfast', 'Titanic Conference Centre', 45, 105000),
    ('Belfast', 'Emerald Executive Suite', 22, 62000),
    ('Belfast', 'Lagan View Room', 18, 52000),
    ('Belfast', 'Hillsborough Boardroom', 8, 28000),
    
    ('Birmingham', 'Bullring Executive Suite', 40, 95000),
    ('Birmingham', 'Jewellery Quarter Room', 15, 42000),
    ('Birmingham', 'Midlands Conference Hall', 60, 125000),
    ('Birmingham', 'Canal Side Meeting Space', 10, 31000),
    ('Birmingham', 'Library of Birmingham Room', 30, 72000),
    
    ('Bristol', 'Clifton Suspension Room', 25, 65000),
    ('Bristol', 'Harbourside Conference', 32, 78000),
    ('Bristol', 'SS Great Britain Hall', 28, 70000),
    ('Bristol', 'Balloon Fiesta Suite', 20, 55000),
    
    ('Cambridge', 'University Senate Room', 40, 98000),
    ('Cambridge', 'River Cam Conference', 18, 52000),
    ('Cambridge', 'Mathematical Bridge Room', 12, 35000),
    ('Cambridge', 'King''s College Hall', 50, 115000),
    ('Cambridge', 'Fitzwilliam Meeting Room', 15, 42000),
    
    ('Cardiff', 'Millennium Conference Centre', 55, 135000),
    ('Cardiff', 'Dragon Suite', 25, 68000),
    ('Cardiff', 'Bay View Boardroom', 16, 48000),
    ('Cardiff', 'Principality Meeting Room', 30, 75000),
    
    ('Edinburgh', 'Castle View Conference', 45, 110000),
    ('Edinburgh', 'Royal Mile Boardroom', 22, 62000),
    ('Edinburgh', 'Holyrood Executive Suite', 35, 85000),
    ('Edinburgh', 'Arthur''s Seat Room', 15, 45000),
    ('Edinburgh', 'New Town Conference Hall', 28, 72000),
    
    ('Glasgow', 'Clyde Auditorium', 65, 155000),
    ('Glasgow', 'Kelvingrove Boardroom', 20, 58000),
    ('Glasgow', 'Merchant City Suite', 32, 78000),
    ('Glasgow', 'Science Centre Room', 25, 65000),
    
    ('Leeds', 'Victoria Quarter Conference', 38, 92000),
    ('Leeds', 'Royal Armouries Hall', 42, 98000),
    ('Leeds', 'Kirkgate Meeting Room', 14, 38000),
    
    ('Leicester', 'King Power Executive Suite', 30, 75000),
    ('Leicester', 'Richard III Conference Room', 22, 62000),
    ('Leicester', 'Space Centre Boardroom', 18, 52000),
    
    ('Liverpool', 'Albert Dock Conference', 48, 115000),
    ('Liverpool', 'Beatles Experience Room', 25, 68000),
    ('Liverpool', 'Mersey View Suite', 20, 58000),
    ('Liverpool', 'Cathedral Meeting Room', 35, 82000),
    ('Liverpool', 'Anfield Boardroom', 15, 45000),
    
    ('London', 'Thames Executive Suite', 75, 185000),
    ('London', 'Westminster Conference Hall', 45, 125000),
    ('London', 'City Boardroom', 25, 75000),
    ('London', 'Shard Meeting Room', 18, 65000),
    ('London', 'Hyde Park Conference', 60, 145000),
    
    ('Manchester', 'Old Trafford Conference', 55, 135000),
    ('Manchester', 'Northern Quarter Creative Space', 20, 58000),
    ('Manchester', 'Town Hall Boardroom', 35, 85000),
    ('Manchester', 'MediaCityUK Suite', 40, 95000),
    
    ('Newcastle', 'Tyne Bridge Conference', 38, 92000),
    ('Newcastle', 'Quayside Executive Room', 25, 68000),
    ('Newcastle', 'St James'' Park Boardroom', 30, 75000),
    ('Newcastle', 'Angel of the North Room', 15, 42000),
    
    ('Nottingham', 'Robin Hood Conference Hall', 32, 82000),
    ('Nottingham', 'Castle View Boardroom', 20, 58000),
    ('Nottingham', 'Sherwood Forest Room', 15, 45000),
    ('Nottingham', 'Lace Market Suite', 28, 72000),
    
    ('Oxford', 'Radcliffe Camera Conference', 45, 125000),
    ('Oxford', 'University Parks Room', 18, 62000),
    ('Oxford', 'Bodleian Library Boardroom', 22, 68000),
    ('Oxford', 'Christ Church Hall', 35, 95000),
    ('Oxford', 'Bridge of Sighs Meeting Room', 12, 42000),
    
    ('Portsmouth', 'Naval Heritage Conference', 40, 92000),
    ('Portsmouth', 'Spinnaker Tower Room', 25, 65000),
    ('Portsmouth', 'Dockyard Boardroom', 18, 52000),
    
    ('Sheffield', 'Winter Garden Conference', 42, 98000),
    ('Sheffield', 'Crucible Theatre Room', 30, 75000),
    ('Sheffield', 'Steelworks Boardroom', 22, 62000),
    ('Sheffield', 'Meadowhall Meeting Space', 35, 82000),
    
    ('Southampton', 'Ocean Gateway Conference', 48, 115000),
    ('Southampton', 'Mayflower Theatre Room', 28, 72000),
    ('Southampton', 'Maritime Museum Boardroom', 16, 48000),
    ('Southampton', 'New Forest Suite', 20, 58000),
    
    ('York', 'Minster Chapter House', 38, 95000),
    ('York', 'Viking Conference Centre', 32, 82000),
    ('York', 'Shambles Meeting Room', 12, 38000),
    ('York', 'Railway Museum Hall', 45, 105000),
    ('York', 'City Walls Boardroom', 18, 52000)
ON CONFLICT (location, name) DO NOTHING;
