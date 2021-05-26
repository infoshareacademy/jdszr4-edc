/*Wszystkie zapytania na podstawie, kt�rych stworzone zosta�y updaty/delety znajduj� si� w pliku us_election_data_quality_check.sql*/;

/*update tabeli county_facts, aby wszystkie stany mia�y warto�� null w polu state_abbreviation
(z zapyta� w us_election_data_quality_check.sql wiemy, �e nale�y null przypisa� do 'United States' i 'Alabama')*/
UPDATE
  county_facts
SET
  state_abbreviation = NULL
WHERE
  area_name = 'United States'
  OR area_name = 'Alabama' ;

/*uzupe�nienie warto�ci fips w tabeli primary_results na podstawie znalezionych odpowiadaj�cych warto�ci w county_facts */
UPDATE
  primary_results pr
SET
  fips = (
    SELECT
      cf.fips
    FROM
      county_facts cf
    WHERE
      cf.area_name = concat(pr.county, ' County')
        AND cf.state_abbreviation = pr.state_abbreviation
  )
WHERE
  pr.fips ISNULL ;

/*usuni�cie wierszy, dla kt�rych primary_results.fips nie ma odpowiednika county_facts.fips*/
DELETE
FROM
  primary_results
WHERE
  fips IN (
    SELECT
      pr.fips
    FROM
      primary_results pr
    FULL JOIN county_facts cf ON
      pr.fips = cf.fips
    WHERE
      cf.fips ISNULL
  ) ;

/*usuni�cie wierszy, dla kt�rych county_facts.fips nie ma odpowiednika primary_results.fips */
DELETE
FROM
  county_facts
WHERE
  fips IN (
    SELECT
      cf.fips
    FROM
      primary_results pr
    FULL JOIN county_facts cf ON
      pr.fips = cf.fips
    WHERE
      pr.fips ISNULL
      AND cf.state_abbreviation IS NOT NULL
  ) ;

/*usuni�cie wierszy dla hrabstwa, w kt�rym nie oddano g�os�w*/
DELETE
FROM
primary_results
WHERE
fips IN (
  SELECT fips
  FROM
    primary_results pr
  GROUP BY
    fips,
    state,
    county
  HAVING
    sum(votes) = 0
) ;

DELETE
FROM
  county_facts
WHERE
  fips IN (
    SELECT fips
    FROM
      primary_results pr
    GROUP BY
      fips,
      state,
      county
    HAVING
      sum(votes) = 0
  ) ;
