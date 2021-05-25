/*- jak wygl�da podzia� ze wzgl�du na p�e� os�b g�osuj�cych w poszczeg�lnych hrabstwach?*/
/*- jak wygl�da rozk�ad g�os�w na poszczeg�lnych kandydat�w z podzia�em na p�e�?*/

/*- jak wygl�da podzia� ze wzgl�du na p�e� os�b g�osuj�cych w poszczeg�lnych hrabstwach?*/
SELECT
  cf.fips ,
  cf.area_name ,
  cf.sex255214 AS percent_women
FROM
  county_facts cf
WHERE
  cf.state_abbreviation IS NOT NULL
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
  cf.state_abbreviation IS NOT NULL
ORDER BY
  3 DESC ;

/*wyci�gam tylko warto�ci skrajne*/
WITH cte AS (
  SELECT
    min(cf2.sex255214) AS min_val ,
    max(cf2.sex255214) AS max_val
  FROM
    county_facts cf2
    WHERE cf2.state_abbreviation IS NOT NULL 
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
  cf.state_abbreviation IS NOT NULL
ORDER BY
  3 DESC ;

/*wida�, �e w przypadku hrabstw warto�ci znacznie bardziej zr�nicowane (mi�dzy 30.1% a 56.8%) ni� w stanach (mi�dzy 47.4% a 52.6%)*/

/*tworz� widok z rankingiem kandydat�w ka�dej z partii w poszczeg�lnych hrabstwach*/
CREATE OR REPLACE VIEW county_ranking AS
SELECT
  cf.fips ,
  pr.state_abbreviation ,
  pr.state ,
  cf.area_name ,
  cf.sex255214 AS percent_women ,
  pr.party ,
  pr.candidate ,
  pr.votes ,
  pr.fraction_votes ,
  RANK() OVER (
    PARTITION BY pr.fips ,
    pr.party
  ORDER BY
    pr.votes DESC
  ) AS ranking
FROM
  county_facts cf
JOIN primary_results pr ON
  cf.fips = pr.fips
WHERE
  cf.state_abbreviation IS NOT NULL
ORDER BY
  cf.fips ,
  pr.party ,
  pr.votes DESC ;

/*utworzony widok:*/
SELECT *
FROM
  county_ranking ;

/*wyniki poszczeg�lnych kandydat�w, tzn. w ilu hrabstwach wygrali*/
SELECT
  round(avg(cr.percent_women),2) AS avg_women_percent ,
  (SELECT cf.sex255214 FROM county_facts cf WHERE cf.fips = 0) AS us_avg ,
  cr.party ,
  cr.candidate ,
  count(DISTINCT cr.fips) AS counties_won ,
  round(100*avg(cr.fraction_votes),2) avg_fraction_votes
FROM
  county_ranking cr 
  WHERE cr.ranking = 1 AND votes != 0
GROUP BY cr.party ,
  cr.candidate 
ORDER BY cr.party, 5 DESC ;

--|avg_women_percent|us_avg|party     |candidate      |counties_won|avg_fraction_votes|
--|-----------------|------|----------|---------------|------------|------------------|
--|50.15            |50.8  |Democrat  |Hillary Clinton|1663        |63.47             |
--|49.70            |50.8  |Democrat  |Bernie Sanders |1162        |57.05             |
--|50.06            |50.8  |Republican|Donald Trump   |2006        |53.00             |
--|49.78            |50.8  |Republican|Ted Cruz       |619         |44.38             |
--|50.52            |50.8  |Republican|John Kasich    |58          |45.16             |
--|51.29            |50.8  |Republican|Marco Rubio    |39          |36.94             |

/*Tutaj jakie� wnioski*/

/*podzia� hrabstw ze wzgl�du na populacj� kobiet: */
CREATE TEMP TABLE IF NOT EXISTS quartiles AS 
SELECT
  percentile_disc(0.25) WITHIN GROUP (ORDER BY cf.sex255214) AS q_25 ,
  percentile_disc(0.5) WITHIN GROUP (ORDER BY cf.sex255214) AS q_50 ,
  percentile_disc(0.75) WITHIN GROUP (ORDER BY cf.sex255214) AS q_75 ,
  percentile_disc(1) WITHIN GROUP (ORDER BY cf.sex255214) AS q_100 ,
  round(avg(cf.sex255214),2) AS average ,
  (SELECT cf.sex255214 FROM county_facts cf WHERE cf.fips = 0) AS avg_in_us
FROM
  county_facts cf
WHERE
  cf.state_abbreviation IS NOT NULL ;

/*wyniki kandydat�w w hrabstwach, gdzie populacja kobiet mie�ci si� w pierwszym kwartylu*/
SELECT
  round(avg(cr.percent_women), 2) AS avg_women_percent ,
  cr.party ,
  cr.candidate ,
  count(DISTINCT cr.fips) counties_won ,
  round(100 * avg(cr.fraction_votes), 2) AS avg_fraction_votes
FROM
  county_ranking cr ,
  quartiles
WHERE
  cr.percent_women <= q_25
  AND cr. ranking = 1
  AND cr.fraction_votes != 0
GROUP BY
  cr.party ,
  cr.candidate
ORDER BY
  cr.party ,
  4 DESC ;

/*wyniki kandydat�w w hrabstwach, gdzie populacja kobiet mie�ci si� w drugim kwartylu*/
SELECT
  round(avg(cr.percent_women), 2) AS avg_women_percent ,
  cr.party ,
  cr.candidate ,
  count(DISTINCT cr.fips) counties_won ,
  round(100 * avg(cr.fraction_votes), 2) AS avg_fraction_votes
FROM
  county_ranking cr ,
  quartiles
WHERE
  cr.percent_women <= q_50
  AND cr.percent_women > q_25
  AND cr. ranking = 1
  AND cr.fraction_votes != 0
GROUP BY
  cr.party ,
  cr.candidate
ORDER BY
  cr.party ,
  4 DESC ;

/*wyniki kandydat�w w hrabstwach, gdzie populacja kobiet mie�ci si� w trzecim kwartylu*/
SELECT
  round(avg(cr.percent_women), 2) AS avg_women_percent ,
  cr.party ,
  cr.candidate ,
  count(DISTINCT cr.fips) counties_won ,
  round(100 * avg(cr.fraction_votes), 2) AS avg_fraction_votes
FROM
  county_ranking cr ,
  quartiles
WHERE
  cr.percent_women <= q_75
  AND cr.percent_women > q_50
  AND cr. ranking = 1
  AND cr.fraction_votes != 0
GROUP BY
  cr.party ,
  cr.candidate
ORDER BY
  cr.party ,
  4 DESC ;

/*wyniki kandydat�w w hrabstwach, gdzie populacja kobiet mie�ci si� w czwartym kwartylu*/
SELECT
  round(avg(cr.percent_women), 2) AS avg_women_percent ,
  cr.party ,
  cr.candidate ,
  count(DISTINCT cr.fips) counties_won ,
  round(100 * avg(cr.fraction_votes), 2) AS avg_fraction_votes
FROM
  county_ranking cr ,
  quartiles
WHERE
  cr.percent_women > q_75
  AND cr. ranking = 1
  AND cr.fraction_votes != 0
GROUP BY
  cr.party ,
  cr.candidate
ORDER BY
  cr.party ,
  4 DESC ;

--pierwszy kwartyl 
--|avg_women_percent|party     |candidate      |counties_won|avg_fraction_votes|
--|-----------------|----------|---------------|------------|------------------|
--|47.89            |Democrat  |Bernie Sanders |388         |58.68             |
--|47.04            |Democrat  |Hillary Clinton|386         |62.84             |
--|47.50            |Republican|Donald Trump   |521         |56.38             |
--|47.40            |Republican|Ted Cruz       |177         |47.15             |
--|47.65            |Republican|John Kasich    |6           |42.57             |
--|47.13            |Republican|Marco Rubio    |3           |35.80             |

--drugi kwartyl
--|avg_women_percent|party     |candidate      |counties_won|avg_fraction_votes|
--|-----------------|----------|---------------|------------|------------------|
--|50.09            |Democrat  |Bernie Sanders |351         |57.87             |
--|50.08            |Democrat  |Hillary Clinton|308         |58.93             |
--|50.09            |Republican|Donald Trump   |448         |55.40             |
--|50.08            |Republican|Ted Cruz       |165         |44.66             |
--|50.05            |Republican|John Kasich    |13          |44.98             |
--|50.18            |Republican|Marco Rubio    |4           |38.53             |

--trzeci kwartyl
--|avg_women_percent|party     |candidate      |counties_won|avg_fraction_votes|
--|-----------------|----------|---------------|------------|------------------|
--|50.79            |Democrat  |Hillary Clinton|434         |60.81             |
--|50.74            |Democrat  |Bernie Sanders |300         |55.10             |
--|50.77            |Republican|Donald Trump   |523         |51.16             |
--|50.76            |Republican|Ted Cruz       |172         |42.48             |
--|50.75            |Republican|John Kasich    |24          |44.57             |
--|50.79            |Republican|Marco Rubio    |10          |34.26             |

--czwarty kwartyl
--|avg_women_percent|party     |candidate      |counties_won|avg_fraction_votes|
--|-----------------|----------|---------------|------------|------------------|
--|51.91            |Democrat  |Hillary Clinton|535         |68.69             |
--|51.73            |Democrat  |Bernie Sanders |123         |54.29             |
--|51.90            |Republican|Donald Trump   |514         |49.35             |
--|51.70            |Republican|Ted Cruz       |105         |42.41             |
--|52.29            |Republican|Marco Rubio    |22          |38.02             |
--|51.69            |Republican|John Kasich    |15          |47.31             |

/*Wnioski: 
 * Wraz ze wzrostem populacji kobiet w partii Demokrat�w ro�nie poparcie Hillary Clinton, 
 * pod wzgl�dem zar�wno wygranych hrabstw, jak i przewagi procentowej.
 * 
 * W partii Republikan niezmiennie wygrywa Donald Trump, cho� w drugim kwartylu liczba zdobytych przez niego hrabstw stosunkowo spad�a.
 * Je�li chodzi o pozosta�ych kandydat�w w pierwszych trzech kwartylach stopniowo ro�nie poparcie Johna Kasich oraz Marco Rubio
 * (pod wzgl�dem wygranych hrabstw), w czwartym natomiast gwa�townie spada liczba hrabstw sprzyjaj�cych Tedowi Cruz,
 * (kt�ra utrzymywa�a si� do�� stabilnie) a Marco Rubio wyprzedza Johna Kasich.
 * 
 * W partii Demokrat�w dla ka�dego przedzia�u Hillary Clinton zdobywa hrabstwa o �rednio wi�kszej populacji kobiet.
 * W partii Republikan hrabstwa o najwy�szej �redniej populacji kobiet zdobywa Marco Rubio w drugim do czwartego kwartyla.
 * Jedynie w pierwszym zdobywa je John Kasich. */

/*UWAGI:
 * W drugim oraz trzecim kwartylu jedynie nieznaczne r�nice w populacji kobiet dla poszczeg�lnych kandydat�w. */

