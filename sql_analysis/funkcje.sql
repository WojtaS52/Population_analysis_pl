CREATE OR REPLACE FUNCTION oblicz_wskaznik_obciazenia_rok (rok_analizy INTEGER)
RETURNS NUMERIC
LANGUAGE sql
AS $$
    SELECT
        CASE WHEN SUM ( CASE WHEN l.grupa_wieku = 'produkcyjny' THEN l.liczba_osob ELSE 0 END ) = 0 THEN NULL
            ELSE ROUND ( SUM(CASE WHEN l.grupa_wieku IN ('przedprodukcyjny', 'poprodukcyjny') THEN l.liczba_osob ELSE 0 END)::NUMERIC / SUM(CASE WHEN l.grupa_wieku = 'produkcyjny' THEN l.liczba_osob ELSE 0 END) * 100,2)
        END
        FROM ludnosc l
    WHERE l.rok = rok_analizy;
$$;

CREATE OR REPLACE FUNCTION oblicz_wskaznik_obciazenia_rok_powiat (rok_analizy INTEGER, nazwa_powiat TEXT)
RETURNS NUMERIC
LANGUAGE sql
AS $$
    SELECT
        CASE WHEN SUM ( CASE WHEN l.grupa_wieku = 'produkcyjny' THEN l.liczba_osob ELSE 0 END ) = 0 THEN NULL
            ELSE ROUND ( SUM(CASE WHEN l.grupa_wieku IN ('przedprodukcyjny', 'poprodukcyjny') THEN l.liczba_osob ELSE 0 END)::NUMERIC / SUM(CASE WHEN l.grupa_wieku = 'produkcyjny' THEN l.liczba_osob ELSE 0 END) * 100,2)
        END
        FROM ludnosc l
        JOIN powiaty p ON p.kod_teryt = l.id_powiatu
        WHERE l.rok = rok_analizy AND p.nazwa = nazwa_powiat;
$$;

CREATE OR REPLACE FUNCTION porownanie_populacji_plec (
    rok_analizy INTEGER,
    nazwa_powiatu TEXT
)
RETURNS TEXT
LANGUAGE sql
AS $$
    SELECT
        CASE
    WHEN SUM(CASE WHEN l.plec = 'K' THEN l.liczba_osob ELSE 0 END) > SUM(CASE WHEN l.plec = 'M' THEN l.liczba_osob ELSE 0 END) THEN 'Kobiety'
    WHEN SUM(CASE WHEN l.plec = 'K' THEN l.liczba_osob ELSE 0 END) < SUM(CASE WHEN l.plec = 'M' THEN l.liczba_osob ELSE 0 END) THEN 'Mezczyzni'
    ELSE 'Rowna liczba'
        END AS dominujaca_plec FROM ludnosc l
        JOIN powiaty p ON p.kod_teryt = l.id_powiatu
        WHERE l.rok = rok_analizy AND p.nazwa = nazwa_powiatu;
$$;

--
CREATE OR REPLACE FUNCTION porownaj_dominacje_plci(
    rok_analizy INTEGER,
    nazwa_powiatu TEXT,
    typ_ruchu TEXT
)
RETURNS TEXT
LANGUAGE sql
AS $$
    SELECT
        CASE
            WHEN SUM(CASE WHEN m.plec = 'K' THEN m.liczba_osob ELSE 0 END) >
                 SUM(CASE WHEN m.plec = 'M' THEN m.liczba_osob ELSE 0 END) THEN
                'Kobiety (Wyższy % w danym typie ruchu)'

            WHEN SUM(CASE WHEN m.plec = 'K' THEN m.liczba_osob ELSE 0 END) <
                 SUM(CASE WHEN m.plec = 'M' THEN m.liczba_osob ELSE 0 END) THEN
                'Mężczyźni (Wyższy % w danym typie ruchu)'

            ELSE
                'Równa liczba plci'
        END AS dominujaca_plec FROM migracje m
    JOIN powiaty p ON p.kod_teryt = m.id_powiatu
    WHERE m.rok = rok_analizy AND p.nazwa = nazwa_powiatu AND m.typ_migracji = typ_ruchu;
$$;

-- Funkcja licząca sado naturalne w powiecie urodzenia - zgony
CREATE OR REPLACE FUNCTION oblicz_saldo_naturalne_powiat (
    rok_analizy INTEGER,
    nazwa_powiatu TEXT
)
RETURNS NUMERIC
LANGUAGE sql
AS $$
        SELECT
            SUM(CASE WHEN r.typ_ruchu LIKE 'Urodzenia żywe' THEN r.liczba_osob ELSE 0 END) -
            SUM(CASE WHEN r.typ_ruchu LIKE 'Zgony' THEN r.liczba_osob ELSE 0 END) AS saldo_naturalne
        FROM ruch_naturalny r
        JOIN powiaty p ON p.kod_teryt = r.id_powiatu
        WHERE r.rok = rok_analizy AND p.nazwa = nazwa_powiatu;
$$;

-- Funkcja licząca jakby %
CREATE OR REPLACE FUNCTION oblicz_wskaznik_ruchu_naturalnego(
    rok_analizy INTEGER,
    nazwa_powiatu TEXT,
    typ_zdarzenia TEXT
)
RETURNS NUMERIC
LANGUAGE sql
AS $$
    WITH Populacja AS (
        SELECT SUM(l.liczba_osob) as total
        FROM ludnosc l
        JOIN powiaty p ON l.id_powiatu = p.kod_teryt
        WHERE l.rok = rok_analizy AND p.nazwa = nazwa_powiatu
    ),
    LiczbaZdarzen AS (
        SELECT SUM(r.liczba_osob) as ilosc
        FROM ruch_naturalny r
        JOIN powiaty p ON r.id_powiatu = p.kod_teryt
        WHERE r.rok = rok_analizy AND p.nazwa = nazwa_powiatu AND (
              (typ_zdarzenia = 'urodzenia' AND r.typ_ruchu LIKE 'Urodzenia%') OR
              (typ_zdarzenia = 'zgony' AND r.typ_ruchu LIKE 'Zgony%')
        )
    )
    SELECT ROUND((lz.ilosc::NUMERIC / NULLIF(pop.total, 0)) * 100, 2) FROM Populacja pop, LiczbaZdarzen lz;
$$;

CREATE OR REPLACE FUNCTION oblicz_wskaznik_migracji(
    rok_analizy INTEGER,
    nazwa_powiatu TEXT,
    typ_migracji_param TEXT
)
RETURNS NUMERIC
LANGUAGE sql
AS $$
    WITH Populacja AS (
        SELECT SUM(l.liczba_osob) as total
        FROM ludnosc l
        JOIN powiaty p ON l.id_powiatu = p.kod_teryt
        WHERE l.rok = rok_analizy AND p.nazwa = nazwa_powiatu
    ),
    LiczbaMigracji AS (
        SELECT SUM(m.liczba_osob) as ilosc
        FROM migracje m
        JOIN powiaty p ON m.id_powiatu = p.kod_teryt
        WHERE m.rok = rok_analizy
          AND p.nazwa = nazwa_powiatu
          AND m.typ_migracji = typ_migracji_param
    )
    SELECT
        ROUND((lm.ilosc::NUMERIC / NULLIF(pop.total, 0)) * 1000, 2)
    FROM Populacja pop, LiczbaMigracji lm;
$$;

CREATE OR REPLACE FUNCTION sprawdz_migracje_miasta(
    p_nazwa_miasta VARCHAR,
    p_rok INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(m.liczba_osob), 0)::INT
        FROM stolice s
        JOIN migracje m ON s.id_powiatu = m.id_powiatu
        WHERE
            s.nazwa_miasta = p_nazwa_miasta
            AND m.rok = p_rok
            AND m.typ_migracji ILIKE '%saldo%'
    );
END;
$$;


-- Testy funkcji

-- SELECT * FROM powiaty;
--do testowania: Powiat zgorzelecki Powiat m. Jelenia Góra Powiat radzyński
--testy
SELECT oblicz_wskaznik_obciazenia_rok(2020);
SELECT oblicz_wskaznik_obciazenia_rok_powiat(2020, 'Powiat m. Jelenia Góra');
SELECT porownanie_populacji_plec(2022, 'Powiat zgorzelecki');
-- Powiat bolesławiecki
SELECT porownanie_migracji_plec(2020, 'Powiat bolesławiecki');
SELECT porownaj_dominacje_plci(2020, 'Powiat bolesławiecki', 'zameldowania');
SELECT oblicz_saldo_naturalne_powiat(2023, 'Powiat radzyński');


