/** Standalone configuration for qonsole on index page */

define( [], function() {
  return {
    prefixes: {
      "rdf":      "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      "rdfs":     "http://www.w3.org/2000/01/rdf-schema#",
      "owl":      "http://www.w3.org/2002/07/owl#",
      "xsd":      "http://www.w3.org/2001/XMLSchema#",
      "sdbm":      "https://sdbm.library.upenn.edu/"
    },
    queries: [
      { "name": "Selection of triples",
        "query": "SELECT ?subject ?predicate ?object\nWHERE {\n" +
                 "  ?subject ?predicate ?object\n}\n" +
                 "LIMIT 25"
      },
      { "name": "Selection of classes",
        "query": "SELECT DISTINCT ?class ?label ?description\nWHERE {\n" +
                 "  ?class a owl:Class.\n" +
                 "  OPTIONAL { ?class rdfs:label ?label}\n" +
                 "  OPTIONAL { ?class rdfs:comment ?description}\n}\n" +
                 "LIMIT 25",
        "prefixes": ["owl", "rdfs"]
      },
      { "name": "France",
        "query": "SELECT ?subject ?predicate ?object WHERE {\n" +
        "  BIND (<https://sdbm.library.upenn.edu/places/13> as ?subject) .\n" +
        "  ?subject ?predicate ?object . \n " +
        "}\n" +
        " LIMIT 25",
        "prefixes": ["xsd", "sdbm"]
      },
      {
        "name": "British 19th Century Collectors",
        "query":
          "SELECT ?entry ?name_text ?provenance_date WHERE {\n" +
          " # ?place is 'Great Britain'\n" +
          " BIND (<https://sdbm.library.upenn.edu/places/2351> as ?place) .\n" +
          " ?name_place sdbm:name_places_place_id ?place .\n" +
          " ?name_place sdbm:name_places_name_id ?name .\n" +
          " # ?provenance is all the provenance uses of names whose associated place or 'nationality' is 'Great Britain'\n" +
          " ?provenance sdbm:provenance_provenance_agent_id ?name .\n" +
          " # ?entry is the entry to which this provenance belongs\n" +
          " ?provenance sdbm:provenance_entry_id ?entry .\n" +
          " # limit results to provenance events which ended between 1800 and 1900\n" +
          " \n" +
          " #change between the following two lines to limit based on provenance dates or the name specific start and end dates\n" +
          " #?name sdbm:names_enddate ?provenance_date .\n" +
          " ?provenance sdbm:provenance_start_date_normalized_start ?provenance_date .\n" +
          " FILTER(xsd:integer(substr(concat(replace(?provenance_date, '-', ''), '0000'), 1, 8)) > 18000000) .\n" +
          " FILTER(xsd:integer(substr(concat(replace(?provenance_date, '-', ''), '0000'), 1, 8)) < 19000000) .\n" +
          " \n" +
          " # the text of the name in question\n" +
          " ?name sdbm:names_name ?name_text\n" +
          "}\n" +
          "LIMIT 1000\n",
        "prefixes": ["xsd", "sdbm"]
      },
      {
        "name": "Potential owners after Phillipps",
        "query":
          "SELECT ?phillipps_entries ?all_related_names_text ?all_related_end_dates ?end\n" +
          "WHERE {\n" +
          " BIND (<https://sdbm.library.upenn.edu/names/7182> as ?name) .\n" +
          " ?name sdbm:names_name ?name_text .\n" +
          " ?name sdbm:names_startdate ?start .\n" +
          " ?name sdbm:names_enddate ?end .\n" +
          " \n" +
          " BIND (xsd:integer(substr(concat(replace(?end, '-', ''), '0000'), 1, 8)) as ?enddate) .\n" +
          " ?phillipps_provenance sdbm:provenance_provenance_agent_id ?name .\n" +
          " ?phillipps_provenance sdbm:provenance_entry_id ?phillipps_entries .\n" +
          " ?all_related_provenance sdbm:provenance_entry_id ?phillipps_entries .\n" +
          " ?all_related_provenance sdbm:provenance_provenance_agent_id ?all_related_names .\n" +
          " \n" +
          " FILTER(?all_related_names != ?name)\n" +
          " ?all_related_names sdbm:names_enddate ?all_related_end_dates .\n" +
          " ?all_related_names sdbm:names_name ?all_related_names_text .\n" +
          " BIND(xsd:integer(substr(concat(replace(?all_related_end_dates, '-', ''), '0000'), 1, 8)) as ?all_related_end_dates_formatted) .\n" +
          " \n" +
          " FILTER(?all_related_end_dates_formatted > ?enddate) .\n" +
          " #?all_related_name_places sdbm:name_places_name_id ?all_related_names .\n" +
          " #?all_related_name_places sdbm:name_places_place_id ?all_related_places .\n" +
          " #?all_related_places sdbm:places_name ?all_related_places_text .\n" +
          " #?all_related_places sdbm:places_latitude ?all_related_places_latitude .\n" +
          " #?all_related_places sdbm:places_longitude ?all_related_places_longitude .\n" +
          " #BIND(concat(concat(xsd:string(?all_related_places_latitude), ','), xsd:string(?all_related_places_longitude)) as ?all_related_places_coordinates) .\n" +
          "}\n" +
          "LIMIT 1000",
        "prefixes": ["xsd", "sdbm"]
      },
      {
        "name": "Associated places of potential owners after Phillipps",
        "query":
          "SELECT ?phillipps_entries ?all_related_names_text ?all_related_end_dates ?all_related_places_text ?all_related_places_coordinates\n" +
          "WHERE {\n" +
          " BIND (<https://sdbm.library.upenn.edu/names/7182> as ?name) .\n" +
          " ?name sdbm:names_name ?name_text .\n" +
          " ?name sdbm:names_startdate ?start .\n" +
          " ?name sdbm:names_enddate ?end .\n" +
          " \n" +
          " BIND (xsd:integer(substr(concat(replace(?end, '-', ''), '0000'), 1, 8)) as ?enddate) .\n" +
          " ?phillipps_provenance sdbm:provenance_provenance_agent_id ?name .\n" +
          " ?phillipps_provenance sdbm:provenance_entry_id ?phillipps_entries .\n" +
          " ?all_related_provenance sdbm:provenance_entry_id ?phillipps_entries .\n" +
          " ?all_related_provenance sdbm:provenance_provenance_agent_id ?all_related_names .\n" +
          " \n" +
          " FILTER(?all_related_names != ?name)\n" +
          " ?all_related_names sdbm:names_enddate ?all_related_end_dates .\n" +
          " ?all_related_names sdbm:names_name ?all_related_names_text .\n" +
          " BIND(xsd:integer(substr(concat(replace(?all_related_end_dates, '-', ''), '0000'), 1, 8)) as ?all_related_end_dates_formatted) .\n" +
          " \n" +
          " FILTER(?all_related_end_dates_formatted > ?enddate) .\n" +
          " \n" +
          " ?all_related_name_places sdbm:name_places_name_id ?all_related_names .\n" +
          " ?all_related_name_places sdbm:name_places_place_id ?all_related_places .\n" +
          " ?all_related_places sdbm:places_name ?all_related_places_text .\n" +
          " ?all_related_places sdbm:places_latitude ?all_related_places_latitude .\n" +
          " ?all_related_places sdbm:places_longitude ?all_related_places_longitude .\n" +
          " BIND(concat(concat(xsd:string(?all_related_places_latitude), ','), xsd:string(?all_related_places_longitude)) as ?all_related_places_coordinates) .\n" +
          "}\n" +
          "LIMIT 1000",
        "prefixes": ["xsd", "sdbm"]
      }
    ]
  };
} );