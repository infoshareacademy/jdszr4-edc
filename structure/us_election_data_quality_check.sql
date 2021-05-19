----------------------------------------------------------------------------------
--QUALITY CHECK TABLICY COUNTY_FACTS
----------------------------------------------------------------------------------

--sprawdzenie, czy fips zawsze dodatni
select * from county_facts cf 
where fips < 0 
or fips isnull ;

--sprawdzenie, czy skr�t sk�ada si� zawsze z dw�ch liter
select 
	count(*)
,	case	when upper(state_abbreviation) similar to '[A-Z]{2}' then 'valid state abbr'
			else 'invalid state abbr' end state_abbr_check
from county_facts cf 
group by state_abbr_check ;

--^52 invalid state abbreviation --> 51 stan�w + USA
select 
	area_name 
,	state_abbreviation 
,	case	when upper(state_abbreviation) similar to '[A-Z]{2}' then 'valid state abbr'
			else 'invalid state abbr' end state_abbr_check
from county_facts cf 
order by state_abbr_check, area_name 
limit 52 ;

--sprawdzenie, czy wszystkie hrabstwa maj� wpisany state_abbreviation 
--(oraz czy wszystkie stany maj� null w state_abbreviation) 
select 
	fips
,	area_name 
,	state_abbreviation 
from county_facts cf 
where state_abbreviation isnull
order by fips ;

select count(*)
from county_facts cf 
where state_abbreviation isnull ;

select 
	fips
,	area_name 
,	state_abbreviation 
from county_facts cf 
where state_abbreviation is not null 
and state_abbreviation not similar to '[A-Z]{2}'
order by fips ;

--^USA i Alabama nie maj� przypisanej warto�ci null
--dla ujednolicenia przypisuj� null tym polom
--patrz: us_election_fixes.sql 


--ponowne sprawdzenie warto�ci null
select 
	fips
,	area_name 
,	state_abbreviation 
from county_facts cf 
where state_abbreviation isnull
order by fips ;

select count(*)
from county_facts cf 
where state_abbreviation isnull ;


----------------------------------------------------------------------------------
--QUALITY CHECK TABLICY PRIMARY_RESULTS
---------------------------------------------------------------------------------- 

--sprawdzenie, czy fips zawsze dodatni
select *
from primary_results pr 
where fips <0 or fips isnull ;

--znalezienie potencjalnych warto�ci fips dla wierszy, w kt�rych wyst�puje null
select pr.*
,	concat(pr.county, ' County') as area_name,
	(select cf.fips 
		from county_facts cf 
		where cf.area_name = concat(pr.county, ' County') 
		and cf.state_abbreviation = pr.state_abbreviation) as potential_fips 
from primary_results pr 
where pr.fips <0 or pr.fips isnull ;

--update tabeli
--patrz: us_election_fixes.sql

--ponowne sprawdzenie, czy fips zawsze dodatni
select *
from primary_results pr 
where fips <0 or fips isnull ;

--sprawdzenie, czy skr�t sk�ada si� zawsze z dw�ch liter
select 
	count(*)
,	case	when upper(state_abbreviation) similar to '[A-Z]{2}' then 'valid state abbr'
			else 'invalid state abbr' end state_abbr_check
from primary_results pr 
group by state_abbr_check ;

--sprawdzenie, czy liczba stan�w odpowiada liczbie skr�t�w
select 
	count(distinct state)
,	count(distinct state_abbreviation)
from primary_results pr ;

--sprawdzenie, czy skr�t odpowiada nazwie stanu
select 
	state_abbreviation 
,	state 
from primary_results pr
group by state_abbreviation, state
order by state_abbreviation ;

--sprawdzenie, czy stany maj� odpowiedniki w tabeli county_facts 
select 
	pr.state_abbreviation as state_abbr_pr
,	pr.state 
,	cf.state_abbreviation as state_abbr_cf
from primary_results pr
full join county_facts cf on pr.fips = cf.fips 
group by pr.state_abbreviation, pr.state, cf.state_abbreviation 
order by pr.state ;


--sprawdzenie brakuj�cych odpowiednik�w fips w tabelach county_facts i primary_results
select  
	count(distinct pr.fips) as fips_not_in_county_facts
from primary_results pr 
full join county_facts cf on pr.fips = cf.fips 
where cf.fips isnull ;
--z podzia�em na stany
select distinct 
	pr.state_abbreviation 
,	count(pr.fips) as fips_not_in_county_facts
from primary_results pr 
full join county_facts cf on pr.fips = cf.fips 
where cf.fips isnull 
group by pr.state_abbreviation ;

--^istnieje 7032 fips�w, niewyst�puj�cych w county_facts

select 
	count(distinct cf.fips) as fips_not_in_primary_results
from primary_results pr 
full join county_facts cf on pr.fips = cf.fips 
where pr.fips isnull and cf.state_abbreviation is not null ;
--z podzia�em na stany
select distinct
	cf.state_abbreviation 
,	count(cf.fips) as fips_not_in_primary_results
from primary_results pr 
full join county_facts cf on pr.fips = cf.fips 
where pr.fips isnull and cf.state_abbreviation is not null 
group by cf.state_abbreviation ;

--^istnieje 335 fips�w niewyst�puj�cych w primary_results 
--(nieb�d�cych nullami, czyli US lub ca�ymi stanami - te b�d� pozostawione)

--usuni�cie fips�w bez odpowiednik�w
--poni�sze zapytanie powinno zwraca� 7032 i 335:
select  
	count(pr.fips) as fips_not_in_county_facts
,	count(cf.fips) as fips_not_in_primary_results
from primary_results pr 
full join county_facts cf on pr.fips = cf.fips 
where cf.fips isnull or pr.fips isnull and cf.state_abbreviation is not null ;

--zapytania delete patrz: us_election_fixes.sql

--po usuni�ciu poni�sze zapytanie powinno zwraca� zera:
select  
	count(pr.fips) as fips_not_in_county_facts
,	count(cf.fips) as fips_not_in_primary_results
from primary_results pr 
full join county_facts cf on pr.fips = cf.fips 
where cf.fips isnull or pr.fips isnull and cf.state_abbreviation is not null ;



