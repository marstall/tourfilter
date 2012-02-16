if [ -z $1 ]
 then
      echo "Usage:"
      echo "new_script.sh script_name [EX: add_metro.sh fix_data will create fix_data.sh based on template.sh and open it in vi]"
      exit
fi
cd ~/tourfilter/bin
cp template.sh $1.sh
chmod a+x $1.sh
vi $1.sh

