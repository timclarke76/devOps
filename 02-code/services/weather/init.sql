DROP TABLE IF EXISTS forecast;

CREATE TABLE IF NOT EXISTS forecast (
    location VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    temperature DECIMAL(4,1) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (location, date)
);

-- Generate unrealistic temperatures for 20 UK towns/cities for next 30 days
DO $$
DECLARE
    loc TEXT;
    locations TEXT[] := ARRAY[
        'Aberdeen',
        'Belfast', 
        'Birmingham',
        'Bristol',
        'Cambridge',
        'Cardiff',
        'Edinburgh',
        'Glasgow',
        'Leeds',
        'Leicester',
        'Liverpool', 
        'London',
        'Manchester',
        'Newcastle',
        'Nottingham',
        'Oxford',
        'Portsmouth',
        'Sheffield',
        'Southampton', 
        'York'
    ];
    start_date DATE := CURRENT_DATE;  -- Start from today
    day_offset INT;
    base_temp CONSTANT DECIMAL := 21.0;  -- Base temperature
    variation_range CONSTANT DECIMAL := 25.0;  -- ±25°C variation
    final_temp DECIMAL;
    daily_seed DECIMAL;
BEGIN
    -- Set random seed for reproducible "randomness"
    PERFORM setseed(0.12345);
    
    FOREACH loc IN ARRAY locations
    LOOP
        FOR day_offset IN 0..29  -- Next 30 days
        LOOP
            -- Generate random temperature: 21°C ± 25°C
            daily_seed := (RANDOM() * variation_range * 2) - variation_range;
            final_temp := base_temp + daily_seed;
            
            -- Round to 1 decimal place
            final_temp := ROUND(final_temp::NUMERIC, 1);
            
            -- Insert the forecast
            INSERT INTO forecast (location, date, temperature)
            VALUES (loc, start_date + day_offset, final_temp)
            ON CONFLICT (location, date) DO NOTHING;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Inserted unrealistic temperatures (-4°C to 46°C) for 20 UK towns/cities for 30 days starting from %', start_date;
END $$;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_forecast_location_date ON forecast(location, date);

-- Show some sample data
SELECT location, date, temperature 
FROM forecast 
WHERE date = CURRENT_DATE 
ORDER BY temperature DESC 
LIMIT 10;
