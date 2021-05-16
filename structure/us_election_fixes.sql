/*Wszystkie zapytania na podstawie, kt�rych stworzone zosta�y updaty/delety znajduj� si� w pliku us_election_data_quality_check.sql*/

/*update tabeli county_facts, aby wszystkie stany mia�y warto�� null w polu state_abbreviation
(z zapyta� w us_election_data_quality_check.sql wiemy, �e nale�y null przypisa� do 'United States' i 'Alabama')*/
update county_facts set state_abbreviation = null 
where area_name = 'United States' or area_name = 'Alabama' ;

/*uzupe�nienie warto�ci fips w tabeli primary_results na podstawie znalezionych odpowiadaj�cych warto�ci w county_facts */
update primary_results pr
set fips = (
	select cf.fips 
	from county_facts cf 
	where cf.area_name = concat(pr.county, ' County') 
	and cf.state_abbreviation = pr.state_abbreviation)
where pr.fips isnull ;

/*usuni�cie wierszy, dla kt�rych primary_results.fips nie ma odpowiednika county_facts.fips*/
delete from primary_results 
where fips in (
select  
	pr.fips 
from primary_results pr 
full join county_facts cf on pr.fips = cf.fips 
where cf.fips isnull
) ;

/*usuni�cie wierszy, dla kt�rych county_facts.fips nie ma odpowiednika primary_results.fips */
delete from county_facts 
where fips in (
select  
	cf.fips 
from primary_results pr 
full join county_facts cf on pr.fips = cf.fips 
where pr.fips isnull and cf.state_abbreviation is not null
) ;