DROP TABLE IF EXISTS booking;

CREATE TABLE IF NOT EXISTS booking (
    id SERIAL PRIMARY KEY,
    customer_email VARCHAR(255) NOT NULL,
    location VARCHAR(100) NOT NULL,
    room_name VARCHAR(100) NOT NULL,
    booking_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (location, room_name, booking_date),
    CONSTRAINT valid_status CHECK (status IN ('PENDING', 'PAID'))
);

CREATE INDEX IF NOT EXISTS idx_booking_customer_email ON booking(customer_email);
CREATE INDEX IF NOT EXISTS idx_booking_location_date ON booking(location, booking_date);
CREATE INDEX IF NOT EXISTS idx_booking_status ON booking(status);
