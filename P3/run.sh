make 
for VARIABLE in 100 1000 10000 20000 40000 80000 100000  1000000
do  
    echo "************************************************"
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    echo "************************************************"
    echo "Parallel version for $VARIABLE"
    ./main-parallel $VARIABLE
    echo "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww"
    echo "Serial version  for $VARIABLE"
    ./main-serial $VARIABLE
done