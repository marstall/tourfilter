for name in $(m shared  "select code from metros where status='active'")
do
 if [ $name != "code" ]; then 
        echo $name :
        m $name  "insert ignore into tourfilter_shared.shared_terms (text,url,source) select text,url,source from terms group by terms.text"
 fi
done

