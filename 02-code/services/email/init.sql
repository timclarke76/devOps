DROP TABLE IF EXISTS sent;
DROP TABLE IF EXISTS template;

CREATE TABLE IF NOT EXISTS template (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sent (
    id SERIAL PRIMARY KEY,
    template INT NOT NULL REFERENCES template(id) ON DELETE CASCADE,
    recipient VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO template (id, name, subject, body) VALUES
    (1, 'welcome', 'Welcome to Boardroom Collective', 'Dear customer, welcome to our service!'),
    (2, 'booking_confirmation', 'Booking Confirmation', 'Your booking has been confirmed.')
ON CONFLICT (id) DO NOTHING;
