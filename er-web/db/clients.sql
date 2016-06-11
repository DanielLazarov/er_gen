CREATE SEQUENCE clients_client_number_seq INCREMENT BY 1 MINVALUE 1000000;

CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    account_id TEXT UNIQUE NOT NULL DEFAULT  md5(now()::text || random()::text || now()::text || random()::text),
    client_number INTEGER UNIQUE NOT NULL DEFAULT nextval('clients_client_number_seq'::regclass),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL,
    telephone_numbers TEXT,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT NOT NULL,
    city TEXT NOT NULL,
    postcode TEXT NOT NULL,
    notes TEXT,
    inserted_at TIMESTAMP NOT NULL DEFAULT now(),
    inserted_by TEXT NOT NULL DEFAULT 'SYSTEM',
    updated_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_by  TEXT NOT NULL DEFAULT 'SYSTEM',
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);
