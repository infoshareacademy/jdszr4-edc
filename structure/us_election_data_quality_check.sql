
----------------------------------------------------------------------------------
--QUALITY CHECK TABLICY COUNTY_FACTS
----------------------------------------------------------------------------------

--sprawdzenie, czy fips zawsze dodatni
 SELECT *
FROM
  county_facts cf
WHERE
  fips < 0
  OR fips isnull ;

--sprawdzenie, czy skr�t sk�ada si� zawsze z dw�ch liter
 SELECT
  count(*) ,
  CASE
    WHEN upper(state_abbreviation) SIMILAR TO '[A-Z]{2}' THEN 'valid state abbr'
    ELSE 'invalid state abbr'
  END state_abbr_check
FROM
  county_facts cf
GROUP BY
  state_abbr_check ;

--^52 invalid state abbreviation --> 51 stan�w + USA
 SELECT
  area_name ,
  state_abbreviation ,
  CASE
    WHEN upper(state_abbreviation) SIMILAR TO '[A-Z]{2}' THEN 'valid state abbr'
    ELSE 'invalid state abbr'
  END state_abbr_check
FROM
  county_facts cf
ORDER BY
  state_abbr_check,
  area_name
LIMIT 52 ;

--sprawdzenie, czy wszystkie hrabstwa maj� wpisany state_abbreviation 
--(oraz czy wszystkie stany maj� null w state_abbreviation) 
 SELECT
  fips ,
  area_name ,
  state_abbreviation
FROM
  county_facts cf
WHERE
  state_abbreviation isnull
ORDER BY
  fips ;

SELECT count(*)
FROM
  county_facts cf
WHERE
  state_abbreviation isnull ;

SELECT
  fips ,
  area_name ,
  state_abbreviation
FROM
  county_facts cf
WHERE
  state_abbreviation IS NOT NULL
  AND state_abbreviation NOT SIMILAR TO '[A-Z]{2}'
ORDER BY
  fips ;
--^USA i Alabama nie maj� przypisanej warto�ci null
--dla ujednolicenia przypisuj� null tym polom
--patrz: us_election_fixes.sql 

--ponowne sprawdzenie warto�ci null
 SELECT
  fips ,
  area_name ,
  state_abbreviation
FROM
  county_facts cf
WHERE
  state_abbreviation isnull
ORDER BY
  fips ;

SELECT count(*)
FROM
  county_facts cf
WHERE
  state_abbreviation isnull ;

----------------------------------------------------------------------------------
--QUALITY CHECK TABLICY PRIMARY_RESULTS
---------------------------------------------------------------------------------- 

--sprawdzenie, czy fips zawsze dodatni
 SELECT *
FROM
  primary_results pr
WHERE
  fips <0
  OR fips isnull ;

--znalezienie potencjalnych warto�ci fips dla wierszy, w kt�rych wyst�puje null
 SELECT
  pr.* ,
  concat(
    pr.county,
    ' County'
  ) AS area_name,
  (
    SELECT
      cf.fips
    FROM
      county_facts cf
    WHERE
      cf.area_name = concat(
        pr.county,
        ' County'
      )
        AND cf.state_abbreviation = pr.state_abbreviation
  ) AS potential_fips
FROM
  primary_results pr
WHERE
  pr.fips <0
  OR pr.fips isnull ;
--update tabeli
--patrz: us_election_fixes.sql

--ponowne sprawdzenie, czy fips zawsze dodatni
 SELECT *
FROM
  primary_results pr
WHERE
  fips <0
  OR fips isnull ;

--sprawdzenie, czy skr�t sk�ada si� zawsze z dw�ch liter
 SELECT
  count(*) ,
  CASE
    WHEN upper(state_abbreviation) SIMILAR TO '[A-Z]{2}' THEN 'valid state abbr'
    ELSE 'invalid state abbr'
  END state_abbr_check
FROM
  primary_results pr
GROUP BY
  state_abbr_check ;

--sprawdzenie, czy liczba stan�w odpowiada liczbie skr�t�w
 SELECT
  count(DISTINCT state) ,
  count(DISTINCT state_abbreviation)
FROM
  primary_results pr ;

--sprawdzenie, czy skr�t odpowiada nazwie stanu
 SELECT
  state_abbreviation ,
  state
FROM
  primary_results pr
GROUP BY
  state_abbreviation,
  state
ORDER BY
  state_abbreviation ;

--sprawdzenie, czy stany maj� odpowiedniki w tabeli county_facts 
 SELECT
  pr.state_abbreviation AS state_abbr_pr ,
  pr.state ,
  cf.state_abbreviation AS state_abbr_cf
FROM
  primary_results pr
FULL JOIN county_facts cf ON
  pr.fips = cf.fips
GROUP BY
  pr.state_abbreviation,
  pr.state,
  cf.state_abbreviation
ORDER BY
  pr.state ;

--sprawdzenie brakuj�cych odpowiednik�w fips w tabelach county_facts i primary_results
 SELECT count(DISTINCT pr.fips) AS fips_not_in_county_facts
FROM
  primary_results pr
FULL JOIN county_facts cf ON
  pr.fips = cf.fips
WHERE
  cf.fips isnull ;

--z podzia�em na stany
 SELECT
  DISTINCT pr.state_abbreviation ,
  count(pr.fips) AS fips_not_in_county_facts
FROM
  primary_results pr
FULL JOIN county_facts cf ON
  pr.fips = cf.fips
WHERE
  cf.fips isnull
GROUP BY
  pr.state_abbreviation ;

--^istnieje 7032 fips�w, niewyst�puj�cych w county_facts
 SELECT
  count(DISTINCT cf.fips) AS fips_not_in_primary_results
FROM
  primary_results pr
FULL JOIN county_facts cf ON
  pr.fips = cf.fips
WHERE
  pr.fips isnull
  AND cf.state_abbreviation IS NOT NULL ;

--z podzia�em na stany
 SELECT
  DISTINCT cf.state_abbreviation ,
  count(cf.fips) AS fips_not_in_primary_results
FROM
  primary_results pr
FULL JOIN county_facts cf ON
  pr.fips = cf.fips
WHERE
  pr.fips isnull
  AND cf.state_abbreviation IS NOT NULL
GROUP BY
  cf.state_abbreviation ;
--^istnieje 335 fips�w niewyst�puj�cych w primary_results 
--(nieb�d�cych nullami, czyli US lub ca�ymi stanami - te b�d� pozostawione)
--usuni�cie fips�w bez odpowiednik�w

--poni�sze zapytanie powinno zwraca� 7032 i 335:
 SELECT
  count(pr.fips) AS fips_not_in_county_facts ,
  count(cf.fips) AS fips_not_in_primary_results
FROM
  primary_results pr
FULL JOIN county_facts cf ON
  pr.fips = cf.fips
WHERE
  cf.fips isnull
  OR pr.fips isnull
  AND cf.state_abbreviation IS NOT NULL ;
--zapytania delete patrz: us_election_fixes.sql

--po usuni�ciu poni�sze zapytanie powinno zwraca� zera:
 SELECT
  count(pr.fips) AS fips_not_in_county_facts ,
  count(cf.fips) AS fips_not_in_primary_results
FROM
  primary_results pr
FULL JOIN county_facts cf ON
  pr.fips = cf.fips
WHERE
  cf.fips isnull
  OR pr.fips isnull
  AND cf.state_abbreviation IS NOT NULL ;

--sprawdzenie, czy istniej� hrabstwa, w kt�rych nie oddano g�os�w
 SELECT
  fips ,
  state,
  county ,
  sum(votes) OVER (
    PARTITION BY fips
  )
FROM
  primary_results pr
ORDER BY
  4 ;

--^w hrabstwie Carroll w Arkansas nie oddano g�os�w --> usuwam te rekordy z tabel
--zapytania delete patrz: us_election_fixes.sql

