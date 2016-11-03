SELECT trigger.set_condition(
    'high_traffic',
    $predicate$
    traffic > max_traffic
    $predicate$
);
