m shared "update artist_terms set status='valid' where status='new' and match_probability='likely'"
m shared "update artist_terms set status='invalid' where status='new' and match_probability='unlikely'"
