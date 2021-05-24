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
  cf.sex255214 AS percent_women
FROM
  county_facts cf
WHERE
  cf.state_abbreviation ISNULL
ORDER BY
  3 DESC ;

/*liczba stan�w, gdzie kobiety stanowi� wi�cej, mniej lub r�wno 50%*/
WITH cte AS (
  SELECT
    cf.fips ,
    cf.area_name ,
    cf.sex255214 AS percent_women ,
    CASE
      WHEN cf.sex255214 > 50 THEN 'more than 50% women'
      WHEN cf.sex255214 <50 THEN 'less than 50% women'
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

