--1
SELECT p.nazwa, r.rok, SUM(r.liczba_osob) AS suma_urodzeń FROM ruch_naturalny as r
JOIN powiaty as p on r.id_powiatu = p.kod_teryt
WHERE r.typ_ruchu LIKE 'Urodzenia%' AND r.rok = 2023
GROUP BY p.nazwa, r.rok
ORDER BY suma_urodzeń DESC
LIMIT 15;

--2 Najbardziej opuszczane powiaty w wybranym roku roku
SELECT p.nazwa, m.rok, SUM(m.liczba_osob) as saldo FROM migracje m
JOIN powiaty p ON m.id_powiatu = p.kod_teryt
WHERE m.typ_migracji = 'saldo migracji' AND m.rok = 2023
GROUP BY p.nazwa, m.rok
HAVING SUM(m.liczba_osob) < 0
ORDER BY saldo ASC
LIMIT 20;


-- 3 Trend salda migracji w latach dla danych powiatów
SELECT p.nazwa, m.rok, SUM(m.liczba_osob) AS saldo_migracji FROM migracje m
JOIN powiaty p ON m.id_powiatu = p.kod_teryt
WHERE m.typ_migracji = 'saldo migracji'
GROUP BY p.nazwa, m.rok
ORDER BY p.nazwa, m.rok;

-- 4 zmiana trendu migracje
SELECT p.nazwa, MAX(CASE WHEN m.rok = (SELECT MAX(rok) FROM migracje) THEN m.liczba_osob END)
  - MAX(CASE WHEN m.rok = (SELECT MIN(rok) FROM migracje) THEN m.liczba_osob END) AS zmiana_trendu
FROM migracje m
JOIN powiaty p ON m.id_powiatu = p.kod_teryt
WHERE m.typ_migracji = 'saldo migracji'
GROUP BY p.nazwa
ORDER BY zmiana_trendu ASC
LIMIT 30;
--5 to u gory na odwrot
SELECT p.nazwa, MAX(CASE WHEN m.rok = (SELECT MAX(rok) FROM migracje) THEN m.liczba_osob END)
  - MAX(CASE WHEN m.rok = (SELECT MIN(rok) FROM migracje) THEN m.liczba_osob END) AS zmiana_trendu FROM migracje m
JOIN powiaty p ON m.id_powiatu = p.kod_teryt
WHERE m.typ_migracji = 'saldo migracji'
GROUP BY p.nazwa
ORDER BY zmiana_trendu DESC
LIMIT 30;

-- 6 migracje na przestrzeni lat miasta wojewojdzkie vs powiatowe
SELECT (CASE WHEN s.id_powiatu IS NOT NULL THEN 'Miasta wojewódzkie' ELSE 'Pozostałe powiaty' END) AS typ, m.rok,(SUM(m.liczba_osob)) AS saldo_migracji FROM migracje m
LEFT JOIN stolice s ON m.id_powiatu = s.id_powiatu
WHERE m.typ_migracji = 'saldo migracji'
GROUP BY typ, m.rok
ORDER BY typ, m.rok;



-- 7 Średnia roczna ile ludzi opuszcza dany powiat
SELECT p.nazwa, round(AVG(roczne_saldo.saldo_roczne),1) AS sredni_bilans_migracji FROM (
    SELECT m.id_powiatu, m.rok, SUM(m.liczba_osob) as saldo_roczne FROM migracje m
    WHERE m.typ_migracji = 'saldo migracji'
    GROUP BY m.id_powiatu, m.rok) AS roczne_saldo
JOIN powiaty p ON roczne_saldo.id_powiatu = p.kod_teryt
GROUP BY p.nazwa
ORDER BY sredni_bilans_migracji ASC
LIMIT 15;

-- 8 Średnia roczna ile ludzi przybywa do powiatu - top 15
SELECT p.nazwa, round(AVG(roczne_saldo.saldo_roczne),1) AS sredni_bilans_migracji FROM (
    SELECT m.id_powiatu, m.rok, SUM(m.liczba_osob) as saldo_roczne FROM migracje m
    WHERE m.typ_migracji = 'saldo migracji'
    GROUP BY m.id_powiatu, m.rok) AS roczne_saldo
JOIN powiaty p ON roczne_saldo.id_powiatu = p.kod_teryt
GROUP BY p.nazwa
ORDER BY sredni_bilans_migracji desc
LIMIT 15;


-- 9 Mieszkańcy w wieku produkcyjnym
SELECT p.nazwa, l.rok, SUM(l.liczba_osob) as osoby_produkcyjne FROM ludnosc l
JOIN powiaty p ON l.id_powiatu= p.kod_teryt
WHERE l.grupa_wieku = 'produkcyjny' and l.rok = 2021
GROUP BY p.nazwa, l.rok
ORDER BY osoby_produkcyjne DESC
LIMIT 30;

-- 10 Mieszkańcy w wieku produkcyjnym
SELECT p.nazwa, l.rok, SUM(l.liczba_osob) AS osoby_produkcyjne
FROM ludnosc l
JOIN powiaty p ON l.id_powiatu = p.kod_teryt
WHERE l.grupa_wieku = 'produkcyjny'
GROUP BY p.nazwa, l.rok
ORDER BY p.nazwa, l.rok;


-- 12 Wskaznik obciążenia demograficznego Polski na przestrzeni lat
SELECT l.rok, ROUND(SUM(CASE WHEN l.grupa_wieku IN ('przedprodukcyjny','poprodukcyjny') THEN l.liczba_osob END) * 1.0 /SUM(CASE WHEN l.grupa_wieku = 'produkcyjny' THEN l.liczba_osob END), 2) AS wskaznik_obciazenia FROM ludnosc l
GROUP BY l.rok
ORDER BY l.rok;



-- 13 Średnia liczba urodzeń w pomiacie na przestrzeni lat - top 10
SELECT  p.nazwa, COUNT(DISTINCT r.rok) AS liczba_lat, ROUND(AVG(r.liczba_osob), 0) AS srednia_roczna_liczba_urodzen FROM ruch_naturalny r
JOIN powiaty p ON r.id_powiatu = p.kod_teryt
WHERE r.typ_ruchu LIKE 'Urodzenia żywe'
GROUP BY p.nazwa
HAVING COUNT(DISTINCT r.rok) > 3
ORDER BY srednia_roczna_liczba_urodzen DESC
LIMIT 10;


-- 14 Powiaty rozwijające się
SELECT p.nazwa,
    (SUM(CASE WHEN l.grupa_wieku IN ('przedprodukcyjny', 'produkcyjny') THEN l.liczba_osob ELSE 0 END)) AS sila_i_rezerwa,
    (SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END)) AS seniorzy,

    (SUM(CASE WHEN l.grupa_wieku IN ('przedprodukcyjny', 'produkcyjny') THEN l.liczba_osob ELSE 0 END) -
     SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END)) AS nadwyzka_demograficzna

FROM ludnosc l
JOIN powiaty p ON l.id_powiatu = p.kod_teryt
WHERE l.rok = 2023
GROUP BY p.nazwa
HAVING (SUM(CASE WHEN l.grupa_wieku IN ('przedprodukcyjny', 'produkcyjny') THEN l.liczba_osob ELSE 0 END) -
        SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END)) > 0
ORDER BY nadwyzka_demograficzna DESC;

-- 15 Powiaty rozwijające się (lata)
SELECT p.nazwa, l.rok,
    (SUM(CASE WHEN l.grupa_wieku IN ('przedprodukcyjny', 'produkcyjny') THEN l.liczba_osob ELSE 0 END)) AS sila_i_rezerwa,
    (SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END)) AS seniorzy,

    (SUM(CASE WHEN l.grupa_wieku IN ('przedprodukcyjny', 'produkcyjny') THEN l.liczba_osob ELSE 0 END) -
     SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END)) AS nadwyzka_demograficzna

FROM ludnosc l
JOIN powiaty p ON l.id_powiatu = p.kod_teryt
GROUP BY p.nazwa, l.rok
HAVING (SUM(CASE WHEN l.grupa_wieku IN ('przedprodukcyjny', 'produkcyjny') THEN l.liczba_osob ELSE 0 END) -
        SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END)) > 0
ORDER BY nadwyzka_demograficzna DESC;


-- 16 Lista powiatów, gdzie liczba seniorów jest większa niż przedprodukcyjni
SELECT p.nazwa,
    SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END) AS populacja_seniorzy,
    SUM(CASE WHEN l.grupa_wieku = 'przedprodukcyjny' THEN l.liczba_osob ELSE 0 END) AS populacja_mlodziez,
    (SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END) -
     SUM(CASE WHEN l.grupa_wieku = 'przedprodukcyjny' THEN l.liczba_osob ELSE 0 END)) AS nadwyzka_seniorow
FROM ludnosc l
JOIN powiaty p ON l.id_powiatu = p.kod_teryt
WHERE l.rok = 2023
GROUP BY p.nazwa
HAVING (SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END) -
        SUM(CASE WHEN l.grupa_wieku = 'przedprodukcyjny' THEN l.liczba_osob ELSE 0 END)) > 0
ORDER BY nadwyzka_seniorow DESC
LIMIT 20;

-- 17 Lista powiatów, gdzie liczba seniorów jest większa niż przedprodukcyjni
SELECT p.nazwa, l.rok,
    SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END) AS populacja_seniorzy,
    SUM(CASE WHEN l.grupa_wieku = 'przedprodukcyjny' THEN l.liczba_osob ELSE 0 END) AS populacja_mlodziez,
    (SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END) -
     SUM(CASE WHEN l.grupa_wieku = 'przedprodukcyjny' THEN l.liczba_osob ELSE 0 END)) AS nadwyzka_seniorow
FROM ludnosc l
JOIN powiaty p ON l.id_powiatu = p.kod_teryt
GROUP BY p.nazwa, l.rok
HAVING (SUM(CASE WHEN l.grupa_wieku = 'poprodukcyjny' THEN l.liczba_osob ELSE 0 END) -
        SUM(CASE WHEN l.grupa_wieku = 'przedprodukcyjny' THEN l.liczba_osob ELSE 0 END)) > 0
ORDER BY nadwyzka_seniorow DESC
LIMIT 20;





-- 18 Najbardziej znikające powiaty w 2023 roku uwzględniając przyrost naturalny i saldo migracji
SELECT p.nazwa, oblicz_saldo_naturalne_powiat(2023, p.nazwa) AS przyrost_naturalny,
    MAX(m.liczba_osob) AS migracja, (oblicz_saldo_naturalne_powiat(2023, p.nazwa) + MAX(m.liczba_osob)) AS przyrost_rzeczywisty
FROM powiaty p
JOIN migracje m ON p.kod_teryt = m.id_powiatu
WHERE m.typ_migracji = 'saldo migracji' AND m.rok = 2023
GROUP BY p.nazwa
ORDER BY przyrost_rzeczywisty ASC
LIMIT 10;

-- 19 Najbardziej znikające powiaty uwzględniając przyrost naturalny i saldo migracji
SELECT p.nazwa, m.rok, oblicz_saldo_naturalne_powiat(2023, p.nazwa) AS przyrost_naturalny,
    MAX(m.liczba_osob) AS migracja, (oblicz_saldo_naturalne_powiat(2023, p.nazwa) + MAX(m.liczba_osob)) AS przyrost_rzeczywisty
FROM powiaty p
JOIN migracje m ON p.kod_teryt = m.id_powiatu
WHERE m.typ_migracji = 'saldo migracji'
GROUP BY p.nazwa, m.rok
ORDER BY przyrost_rzeczywisty ASC
LIMIT 60;

-- 20 Najbardziej przybywające powiaty uwzględniając przyrost naturalny i saldo migracji
SELECT p.nazwa, m.rok, oblicz_saldo_naturalne_powiat(2023, p.nazwa) AS przyrost_naturalny,
    MAX(m.liczba_osob) AS migracja, (oblicz_saldo_naturalne_powiat(2023, p.nazwa) + MAX(m.liczba_osob)) AS przyrost_rzeczywisty
FROM powiaty p
JOIN migracje m ON p.kod_teryt = m.id_powiatu
WHERE m.typ_migracji = 'saldo migracji'
GROUP BY p.nazwa, m.rok
ORDER BY przyrost_rzeczywisty DESC
LIMIT 60;


-- 21 Porównanie populacji - w ilu powiatach żyje więcej kobiet bądź mężczyzn - trend 2018 >2023
(SELECT porownanie_populacji_plec(2023, p.nazwa) AS kategoria_plec, COUNT(*) AS liczba_powiatow FROM powiaty p
GROUP BY kategoria_plec
ORDER BY liczba_powiatow DESC)
UNION ALL
(SELECT porownanie_populacji_plec(2018, p.nazwa) AS kategoria_plec, COUNT(*) AS liczba_powiatow FROM powiaty p
GROUP BY kategoria_plec
ORDER BY liczba_powiatow DESC);




-- 22 Wyświetlenie powiatów, gdzie dominują mężczyźni
SELECT p.nazwa, porownanie_populacji_plec(2023, p.nazwa) AS status_plec FROM powiaty p
WHERE porownanie_populacji_plec(2023, p.nazwa) = 'Mezczyzni'
ORDER BY p.nazwa ASC;

SELECT p.nazwa, porownanie_populacji_plec(2018, p.nazwa) AS status_plec FROM powiaty p
WHERE porownanie_populacji_plec(2018, p.nazwa) = 'Mezczyzni'
ORDER BY p.nazwa ASC;

-- 23 Wskaźnik obciążenia demograficznego Polski w latach 2018 i 2023
SELECT 2018 AS rok, oblicz_wskaznik_obciazenia_rok(2018) AS wskaznik_obciazenia_PL
UNION ALL
SELECT 2023 AS rok, oblicz_wskaznik_obciazenia_rok(2023) AS wskaznik_obciazenia_PL;

--24 10 powiatów o najwyższym wskaźniku urodzeń w 2023 roku w %
SELECT p.nazwa, oblicz_wskaznik_ruchu_naturalnego(2023, p.nazwa, 'urodzenia') AS wskaznik_urodzen FROM powiaty p
ORDER BY wskaznik_urodzen DESC
LIMIT 10;

-- 25
SELECT p.nazwa, oblicz_wskaznik_migracji(2023, p.nazwa, 'saldo migracji') AS wskaznik_migracji FROM powiaty p
WHERE oblicz_wskaznik_migracji(2023, p.nazwa, 'saldo migracji') IS NOT NULL
ORDER BY wskaznik_migracji DESC
LIMIT 10;

--26 Silnie sfemilizowane powiaty
SELECT p.nazwa, l.rok, SUM(l.liczba_osob) as populacja_razem FROM ludnosc l
JOIN powiaty p ON l.id_powiatu = p.kod_teryt
GROUP BY p.nazwa, l.rok
HAVING SUM(CASE WHEN l.plec = 'K' THEN l.liczba_osob ELSE 0 END) >
    1.16 * SUM(CASE WHEN l.plec = 'M' THEN l.liczba_osob ELSE 0 END);

SELECT DISTINCT typ_migracji FROM migracje;

SELECT sprawdz_migracje_miasta('Wrocław', 2022);

--27
(
    SELECT * FROM (
        SELECT
            'TOP 3 najlepsze' AS kategoria,
            s.nazwa_miasta,
            sprawdz_migracje_miasta(s.nazwa_miasta, 2022) AS saldo_migracji
        FROM stolice s
    ) t
    ORDER BY saldo_migracji DESC
    LIMIT 3
)
UNION ALL
(
    SELECT * FROM (
        SELECT 'TOP 3 najgorsze' AS kategoria, s.nazwa_miasta, sprawdz_migracje_miasta(s.nazwa_miasta, 2022) AS saldo_migracji
        FROM stolice s
    ) t
    ORDER BY saldo_migracji ASC
    LIMIT 3
);

