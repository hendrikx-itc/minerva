CREATE AGGREGATE public.first(
    sfunc    = public.fst,
    basetype = anyelement,
    stype    = anyelement
);


CREATE AGGREGATE public.last(
    sfunc    = public.snd,
    basetype = anyelement,
    stype    = anyelement
);
