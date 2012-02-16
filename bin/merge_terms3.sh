 	mysql -uchris -pchris tourfilter_$1 -e "insert ignore into terms (text,source) select text,source from tourfilter_shared.shared_terms;"
