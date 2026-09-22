package main

import (
	"database/sql"
	"fmt"
)

func selectForecast(location, date string) (*Forecast, error) {
	if db == nil {
		return nil, fmt.Errorf("Database not initialised")
	}

	var forecast Forecast
	forecast.Location = location
	forecast.Date = date

	if err := db.QueryRow(`
		SELECT temperature
		FROM forecast
		WHERE location = $1 AND date = $2
	`, location, date).Scan(&forecast.Temperature); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		} else {
			return nil, fmt.Errorf("Could not select temperature:\n%w", err)
		}
	}

	return &forecast, nil
}
