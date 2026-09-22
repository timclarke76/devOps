package main

import (
	"database/sql"
	"fmt"
)

func selectByLocationAndName(location, name string) ([]Room, error) {
	if db == nil {
		return nil, fmt.Errorf("Database not initialised")
	}

	var room Room

	if err := db.QueryRow(`
		SELECT location, name, capacity, price_penny
		FROM room
		WHERE location = $1 AND name = $2
		ORDER BY location ASC, name ASC
	`, location, name).Scan(
		&room.Location,
		&room.Name,
		&room.Capacity,
		&room.Price,
	); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		} else {
			return nil, fmt.Errorf("Could not select room:\n%w", err)
		}
	}

	return []Room{room}, nil
}

func selectByLocation(location string) ([]Room, error) {
	if db == nil {
		return nil, fmt.Errorf("Database not initialised")
	}

	rows, err := db.Query(`
		SELECT location, name, capacity, price_penny
		FROM room
		WHERE location = $1
		ORDER BY location ASC, name ASC
	`, location)

	if err != nil {
		return nil, fmt.Errorf("Could not query room:\n%w", err)
	}

	defer rows.Close()
	var rooms []Room

	for rows.Next() {
		var room Room

		if err := rows.Scan(
			&room.Location,
			&room.Name,
			&room.Capacity,
			&room.Price,
		); err != nil {
			return nil, fmt.Errorf("Could not scan room:\n%w", err)
		}

		rooms = append(rooms, room)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("Row iteration error:\n%w", err)
	}

	return rooms, nil
}

func selectByName(name string) ([]Room, error) {
	if db == nil {
		return nil, fmt.Errorf("Database not initialised")
	}

	rows, err := db.Query(`
		SELECT location, name, capacity, price_penny
		FROM room
		WHERE name = $1
		ORDER BY location ASC, name ASC
	`, name)

	if err != nil {
		return nil, fmt.Errorf("Could not query room:\n%w", err)
	}

	defer rows.Close()
	var rooms []Room

	for rows.Next() {
		var room Room

		if err := rows.Scan(
			&room.Location,
			&room.Name,
			&room.Capacity,
			&room.Price,
		); err != nil {
			return nil, fmt.Errorf("Could not scan room:\n%w", err)
		}

		rooms = append(rooms, room)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("Row iteration error:\n%w", err)
	}

	return rooms, nil
}

func selectAll() ([]Room, error) {
	if db == nil {
		return nil, fmt.Errorf("Database not initialised")
	}

	rows, err := db.Query(`
		SELECT location, name, capacity, price_penny
		FROM room
	`)

	if err != nil {
		return nil, fmt.Errorf("Could not query room:\n%w", err)
	}

	defer rows.Close()
	var rooms []Room

	for rows.Next() {
		var room Room

		if err := rows.Scan(
			&room.Location,
			&room.Name,
			&room.Capacity,
			&room.Price,
		); err != nil {
			return nil, fmt.Errorf("Could not scan room:\n%w", err)
		}

		rooms = append(rooms, room)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("Row iteration error:\n%w", err)
	}

	return rooms, nil
}
