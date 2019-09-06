Aliases
=======

All enities have a name. The name can be found in table entity.<entity_type>. Before data is processed on Minerva ETL, the default naming has to be specified. Later other namings, or aliases, may be useful. For example when a non human understandable, system specific naming is applied (e.g. MAC addresses) it may be useful to create a human understandable alias (e.g. inventory naming). 


Aliases are stored in tables in schema alias, with naming convention: alias.<entity_type>_<aliasname>. An alias table has two columns: entity_id and name. An foreign key on column entity_id refers to column id in the entity.<entity_type> table.