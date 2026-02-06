CREATE TABLE powiaty (
    kod_teryt VARCHAR(7) PRIMARY KEY,
    nazwa VARCHAR(100)
);

CREATE TABLE ruch_naturalny (
    id SERIAL PRIMARY KEY,
    id_powiatu VARCHAR(7) NOT NULL,
    rok INT,
    plec VARCHAR(10),
    typ_ruchu VARCHAR(100),
    liczba_osob INT,

    FOREIGN KEY (id_powiatu) REFERENCES powiaty(kod_teryt)
);

CREATE TABLE migracje (
    id SERIAL PRIMARY KEY,
    id_powiatu VARCHAR(7) NOT NULL,
    rok INT,
    plec VARCHAR(10),
    typ_migracji VARCHAR(100),
    liczba_osob INT,

    FOREIGN KEY (id_powiatu) REFERENCES powiaty(kod_teryt)
);

CREATE TABLE ludnosc (
    id SERIAL PRIMARY KEY,
    id_powiatu VARCHAR(7) NOT NULL,
    rok INT,
    plec VARCHAR(10),
    grupa_wieku VARCHAR(50),
    liczba_osob INT,

    FOREIGN KEY (id_powiatu) REFERENCES powiaty(kod_teryt)
);

CREATE TABLE stolice (
    id SERIAL PRIMARY KEY,
    nazwa_miasta VARCHAR(100),
    id_powiatu VARCHAR(7) NOT NULL,

    FOREIGN KEY (id_powiatu) REFERENCES powiaty(kod_teryt)
);

INSERT INTO stolice (nazwa_miasta, id_powiatu) VALUES
('Wrocław', '0264000'),
('Bydgoszcz', '0461000'),
('Toruń', '0463000'),
('Lublin', '0663000'),
('Gorzów Wlkp.', '0861000'),
('Zielona Góra', '0862000'),
('Łódź', '1061000'),
('Kraków', '1261000'),
('Warszawa', '1465000'),
('Opole', '1661000'),
('Rzeszów', '1863000'),
('Białystok', '2061000'),
('Gdańsk', '2261000'),
('Katowice', '2469000'),
('Kielce', '2661000'),
('Olsztyn', '2862000'),
('Poznań', '3064000'),
('Szczecin', '3262000');