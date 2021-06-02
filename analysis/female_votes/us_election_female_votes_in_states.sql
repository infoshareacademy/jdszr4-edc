/*- jak wygl�da podzia� ze wzgl�du na p�e� os�b g�osuj�cych w poszczeg�lnych stanach?*/
/*- jak wygl�da rozk�ad g�os�w na poszczeg�lnych kandydat�w z podzia�em na p�e�?*/

/*sprawdzenie, kt�re kolumny dotycz� p�ci*/
SELECT *
FROM
  county_facts_dictionary cfd
WHERE
  lower(cfd.description) LIKE '%fem%'
  OR lower(cfd.description) LIKE '%sex%'
  OR lower(cfd.description) LIKE '%gend%';

/*- jak wygl�da podzia� ze wzgl�du na p�e� os�b g�osuj�cych w poszczeg�lnych stanach?*/
SELECT
  cf.fips ,
  cf.area_name ,
  cf.sex255214 
FROM
  county_facts cf
WHERE
  cf.state_abbreviation ISNULL
ORDER BY
  fips ;

/*posortowane*/
SELECT
  cf.fips ,
  cf.area_name ,
  cf.sex255214 
FROM
  county_facts cf
WHERE
  cf.state_abbreviation ISNULL
ORDER BY
  3 DESC ;

/*wyci�gam warto�ci skrajne*/
WITH cte AS (
  SELECT
    min(cf2.sex255214) AS min_val ,
    max(cf2.sex255214) AS max_val
  FROM
    county_facts cf2
    WHERE cf2.state_abbreviation ISNULL 
)
SELECT
  cf.fips ,
  cf.area_name ,
  cf.sex255214 AS percent_women
FROM
  county_facts cf
JOIN cte ON
  cf.sex255214 = cte.min_val OR cf.sex255214 = cte.max_val
WHERE
  cf.state_abbreviation ISNULL
ORDER BY
  3 DESC ;

/*procent kobiet zawiera si� w przedziale <47.4, 52.6>, dalsze rozwa�ania przeprowadzone z podzia�em na <50%, =50%, >50% */
/*liczba stan�w, gdzie kobiety stanowi� wi�cej, mniej lub r�wno 50%*/
WITH cte AS (
  SELECT
    cf.fips ,
    cf.area_name ,
    cf.sex255214 AS percent_women ,
    CASE
      WHEN cf.sex255214 > 50 THEN 'more than 50% women'
      WHEN cf.sex255214 < 50 THEN 'less than 50% women'
      ELSE '50% women'
    END women_rate
  FROM
    county_facts cf
  WHERE
    cf.state_abbreviation ISNULL
  ORDER BY
    cf.fips
)
SELECT
  women_rate ,
  count(women_rate) AS number_of_states
FROM
  cte
GROUP BY
  women_rate 
ORDER BY women_rate DESC ;

/*ranking kandydat�w w poszczeg�lnych stanach w zestawieniu z procentem kobiet */
SELECT
  cf.sex255214 AS percent_women ,
  cpis.*
FROM
  candidates_percent_in_states cpis
JOIN county_facts cf ON
  cpis.state = cf.area_name ;

/*ile razy poszczeg�lni kandydaci zwyci�yli i jak to si� ma do �redniej kobiet*/
SELECT
  round(avg(cf.sex255214), 2) AS avg_percent_women ,
  (
    SELECT
      cf2.sex255214
    FROM
      county_facts cf2
    WHERE
      cf2.fips = 0
  ) AS avg_in_us ,
  CASE
    WHEN avg(cf.sex255214) > (
      SELECT
        cf2.sex255214
      FROM
        county_facts cf2
      WHERE
        cf2.fips = 0
    ) THEN 'more than avg'
    WHEN avg(cf.sex255214) < (
      SELECT
        cf2.sex255214
      FROM
        county_facts cf2
      WHERE
        cf2.fips = 0
    ) THEN 'less than avg'
    ELSE 'equals avg'
  END AS percent_women_wtr_avg ,
  cpis.party ,
  cpis.candidate ,
  count(cpis.state) AS times_won ,
  round(avg(cpis.percent_votes), 2) AS avg_percent_votes 
FROM
  candidates_percent_in_states cpis
JOIN county_facts cf ON
  cpis.state = cf.area_name
WHERE
  cpis.ranking = 1
GROUP BY
  cpis.party ,
  cpis.candidate
ORDER BY
  party,
  1 DESC ;

--|avg_percent_women|avg_in_us|percent_women_wtr_avg|party     |candidate      |times_won|avg_percent_votes|
--|-----------------|---------|---------------------|----------|---------------|---------|-----------------|
--|50.92            |50.8     |more than avg        |Democrat  |Hillary Clinton|25       |62.23            |
--|50.18            |50.8     |less than avg        |Democrat  |Bernie Sanders |16       |60.74            |
--|51.10            |50.8     |more than avg        |Republican|John Kasich    |1        |47.57            |
--|50.77            |50.8     |less than avg        |Republican|Donald Trump   |32       |53.64            |
--|50.18            |50.8     |less than avg        |Republican|Ted Cruz       |6        |45.57            |



/*wyniki dla stan�w, gdzie �rednia populacja kobiet >=50%*/
SELECT
  round(avg(cf.sex255214), 2) AS avg_women_percent ,
  cpis.party ,
  cpis.candidate ,
  count(cpis.state) AS states_won ,
  round(avg(cpis.percent_votes), 2) AS avg_percent_votes
FROM
  candidates_percent_in_states cpis
JOIN county_facts cf ON
  cpis.state = cf.area_name
WHERE
  cf.sex255214 >= 50
  AND cpis.ranking = 1
GROUP BY
  cpis.party ,
  cpis.candidate
ORDER BY
  cpis.party ,
  4 DESC ;

/*wyniki dla stan�w, gdzie �rednia populacja kobiet <50%*/
SELECT
  round(avg(cf.sex255214), 2) AS avg_women_percent ,
  cpis.party ,
  cpis.candidate ,
  count(cpis.state) AS states_won ,
  round(avg(cpis.percent_votes), 2) AS avg_percent_votes
FROM
  candidates_percent_in_states cpis
JOIN county_facts cf ON
  cpis.state = cf.area_name
WHERE
  cf.sex255214 < 50
  AND cpis.ranking = 1
GROUP BY
  cpis.party ,
  cpis.candidate
ORDER BY
  cpis.party ,
  4 DESC ;

--�rednia populacja kobiet >=50%
--|avg_women_percent|party     |candidate      |states_won|avg_percent_votes|
--|-----------------|----------|---------------|----------|-----------------|
--|51.02            |Democrat  |Hillary Clinton|23        |63.13            |
--|50.52            |Democrat  |Bernie Sanders |10        |57.52            |
--|50.93            |Republican|Donald Trump   |28        |52.80            |
--|50.38            |Republican|Ted Cruz       |4         |39.34            |
--|51.10            |Republican|John Kasich    |1         |47.57            |

--�rednia populacja kobiet <50%
--|avg_women_percent|party     |candidate      |states_won|avg_percent_votes|
--|-----------------|----------|---------------|----------|-----------------|
--|49.60            |Democrat  |Bernie Sanders |6         |66.11            |
--|49.70            |Democrat  |Hillary Clinton|2         |51.89            |
--|49.65            |Republican|Donald Trump   |4         |59.52            |
--|49.80            |Republican|Ted Cruz       |2         |58.03            |

/*Wnioski:
 * Istotn� zmian� wida� w partii Demokrat�w - tam gdzie kobiety stanowi� wi�kszo�� 
 * populacji cz�ciej wygrywa Hillary Clinton, natomiast tam, gdzie mniejszo�� - Bernie Sanders.
 * W obydwu przypadkach jednak �redni procent kobiet jest wy�szy w stanach g�osuj�cych na H.Clinton.
 * 
 * W partii Republikan w obu przypadkach wygrywa Donald Trump.*/




/*procent kobiet zawiera si� w przedziale <47.4, 52.6>, dalsze rozwa�ania przeprowadzone z podzia�em na poni�ej/powy�ej �redniej/mediany */
/*liczba stan�w, gdzie kobiety stanowi� wi�cej/mniej ni� �rednio w US */
CREATE TEMP TABLE avg_med
AS 
SELECT
  (SELECT cf2.sex255214 FROM county_facts cf2 WHERE cf2.fips = 0) AS us_avg,
  percentile_disc(0.5) WITHIN GROUP(ORDER BY cf.sex255214) AS us_med 
FROM
  county_facts cf
WHERE cf.state_abbreviation ISNULL ;

SELECT *
FROM
  avg_med ;

/*tabela z por�wnaniem populacji kobiet do warto�ci �redniej dla US oraz mediany*/
CREATE OR REPLACE
VIEW avg_med_comparison AS
SELECT
  cf.fips ,
  cf.area_name ,
  cf.sex255214 AS percent_women ,
  (SELECT am.us_avg FROM avg_med am) ,
  CASE
    WHEN cf.sex255214 > am.us_avg THEN 'more than average'
    WHEN cf.sex255214 < am.us_avg THEN 'less than average'
    ELSE 'equals average'
  END AS avg_check ,
  (SELECT am.us_med FROM avg_med am) ,
  CASE
    WHEN cf.sex255214 > am.us_med THEN 'more than median'
    WHEN cf.sex255214 < am.us_med THEN 'less than median'
    ELSE 'equals median'
  END AS med_check
FROM
  county_facts cf ,
  avg_med am
WHERE
  cf.state_abbreviation ISNULL
  AND cf.fips != 0
ORDER BY
  cf.fips ;

SELECT * FROM avg_med_comparison ;

/*ile stan�w w poszczeg�lnych przedzia�ach*/
SELECT
  med_check ,
  count(*) AS states
FROM
  avg_med_comparison amc
GROUP BY
  med_check 
ORDER BY 2 DESC ;

--|med_check       |states|
--|----------------|------|
--|more than median|25    |
--|less than median|24    |
--|equals median   |2     |


SELECT
  avg_check ,
  count(*) AS states
FROM
  avg_med_comparison amc
GROUP BY
  avg_check 
ORDER BY 2 DESC ;

--|avg_check        |states|
--|-----------------|------|
--|less than average|26    |
--|more than average|23    |
--|equals average   |2     |


/*zestawienie rankingu kandydat�w z populacj� kobiet*/
SELECT
  cpis.* ,
  amc.percent_women ,
  amc.us_avg ,
  amc.avg_check ,
  amc.us_med ,
  amc.med_check
FROM
  candidates_percent_in_states cpis
JOIN avg_med_comparison amc ON
  cpis.state = amc.area_name
ORDER BY
  amc.fips ,
  cpis.party ,
  cpis.ranking ;

/*ile razy poszczeg�lni kandydaci zwyci�yli*/

/*przedzia� < us_avg*/
SELECT
  round(avg(amc.percent_women),2) AS avg_percent_women ,
  cpis.party ,
  cpis.candidate ,
  count(cpis.state) AS states_won ,
  round(avg(cpis.percent_votes),2) AS avg_votes_percent
FROM
  candidates_percent_in_states cpis
JOIN avg_med_comparison amc ON
  cpis.state = amc.area_name
WHERE
  cpis.ranking = 1
  AND amc.avg_check LIKE 'less%'
GROUP BY
  cpis.party ,
  cpis.candidate
ORDER BY
  cpis.party ,
  4 DESC ;

/*przedzia� >= us_avg*/
SELECT
  round(avg(amc.percent_women),2) AS avg_percent_women ,
  cpis.party ,
  cpis.candidate ,
  count(cpis.state) AS states_won ,
  round(avg(cpis.percent_votes),2) AS avg_votes_percent
FROM
  candidates_percent_in_states cpis
JOIN avg_med_comparison amc ON
  cpis.state = amc.area_name
WHERE
  cpis.ranking = 1
  AND (amc.avg_check LIKE 'more%' OR amc.avg_check LIKE 'equals%')
GROUP BY
  cpis.party ,
  cpis.candidate
ORDER BY
  cpis.party ,
  4 DESC ;


/*przedzia� < us_med*/
SELECT
  round(avg(amc.percent_women),2) AS avg_percent_women ,
  cpis.party ,
  cpis.candidate ,
  count(cpis.state) AS states_won ,
  round(avg(cpis.percent_votes),2) AS avg_votes_percent
FROM
  candidates_percent_in_states cpis
JOIN avg_med_comparison amc ON
  cpis.state = amc.area_name
WHERE
  cpis.ranking = 1
  AND amc.med_check LIKE 'less%'
GROUP BY
  cpis.party ,
  cpis.candidate
ORDER BY
  cpis.party ,
  4 DESC ;

/*przedzia� >= us_med*/
SELECT
  round(avg(amc.percent_women),2) AS avg_percent_women ,
  cpis.party ,
  cpis.candidate ,
  count(cpis.state) AS states_won ,
  round(avg(cpis.percent_votes),2) AS avg_votes_percent
FROM
  candidates_percent_in_states cpis
JOIN avg_med_comparison amc ON
  cpis.state = amc.area_name
WHERE
  cpis.ranking = 1
  AND (amc.med_check LIKE 'more%' OR amc.med_check LIKE 'equals%')
GROUP BY
  cpis.party ,
  cpis.candidate
ORDER BY
  cpis.party ,
  4 DESC ;

--przedzia� < us_avg
--|avg_percent_women|party     |candidate      |states_won|avg_votes_percent|
--|-----------------|----------|---------------|----------|-----------------|
--|50.07            |Democrat  |Bernie Sanders |14        |61.98            |
--|50.17            |Democrat  |Hillary Clinton|7         |55.26            |
--|50.18            |Republican|Donald Trump   |13        |64.44            |
--|50.18            |Republican|Ted Cruz       |6         |45.57            |

--przedzia� >= us_avg
--|avg_percent_women|party     |candidate      |states_won|avg_votes_percent|
--|-----------------|----------|---------------|----------|-----------------|
--|51.21            |Democrat  |Hillary Clinton|18        |64.94            |
--|50.90            |Democrat  |Bernie Sanders |2         |52.04            |
--|51.18            |Republican|Donald Trump   |19        |46.26            |
--|51.10            |Republican|John Kasich    |1         |47.57            |

--przedzia� < us_med
--|avg_percent_women|party     |candidate      |states_won|avg_votes_percent|
--|-----------------|----------|---------------|----------|-----------------|
--|50.02            |Democrat  |Bernie Sanders |13        |62.71            |
--|50.17            |Democrat  |Hillary Clinton|7         |55.26            |
--|50.13            |Republican|Donald Trump   |12        |65.26            |
--|50.18            |Republican|Ted Cruz       |6         |45.57            |

--przedzia� >= us_med
--|avg_percent_women|party     |candidate      |states_won|avg_votes_percent|
--|-----------------|----------|---------------|----------|-----------------|
--|51.21            |Democrat  |Hillary Clinton|18        |64.94            |
--|50.83            |Democrat  |Bernie Sanders |3         |52.19            |
--|51.16            |Republican|Donald Trump   |20        |46.68            |
--|51.10            |Republican|John Kasich    |1         |47.57            |

/*Sprawdzenie korelacji dla poszczeg�lnych kandydat�w*/

/*Ile razy kandydat znalaz� si� na li�cie wynik�w*/
SELECT
  DISTINCT candidate ,
  count(*)
FROM
  candidates_percent_in_states cpis
JOIN county_facts cf ON
  cpis.state = cf.area_name
GROUP BY
  candidate
ORDER BY
  2 DESC ;

/*Zale�no�� wygranej kandydata od populacji kobiet badam dla kandydat�w,
 * kt�rzy co najmniej 10 razy pojawiaj� si� w wynikach dla stan�w*/

CREATE OR REPLACE
VIEW candidates_in_states_vs_female AS
SELECT
  cpis.* ,
  cf.sex255214 AS percent_women ,
  CASE
    WHEN cpis.candidate = 'Bernie Sanders' THEN 1
    WHEN cpis.candidate = 'Hillary Clinton' THEN 2
    WHEN cpis.candidate = 'Donald Trump' THEN 3
    WHEN cpis.candidate = 'John Kasich' THEN 4
    WHEN cpis.candidate = 'Ted Cruz' THEN 5
    WHEN cpis.candidate = 'Marco Rubio' THEN 6
    WHEN cpis.candidate = 'Ben Carson' THEN 7
    ELSE NULL
  END AS candidate_number
FROM
  candidates_percent_in_states cpis
JOIN county_facts cf ON
  cpis.state = cf.area_name ;

SELECT * FROM candidates_in_states_vs_female cisvf ;

/*Wyniki*/
SELECT
  count(*) ,
  candidate ,
  corr(percent_votes, percent_women) ,
  @corr(percent_votes, percent_women) AS corr_abs
FROM
  candidates_in_states_vs_female cisvf
  WHERE candidate_number IS NOT NULL 
GROUP BY candidate 
ORDER BY 4 DESC ;

/*Wniosek:
 * - najwi�ksz� zale�no�� wida� w partii Demokrat�w. (0.71)
 * - w partii Republikan dla wi�kszo�ci kandydat�w istnieje s�aba korelacja,
 *   b�d� praktycznie zupe�ny brak zwi�zku mi�dzy oddanymi na nich g�osami 
 *   z populacj� kobiet w danym stanie, w przypadku Johna Kasich mo�na stwierdzi�
 *   nisk� korelacj�, w przypadku Bena Carsona - umiarkowan�.*/




