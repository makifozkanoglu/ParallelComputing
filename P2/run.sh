ARG1=${1:-8}
make
for VARIABLE in 1000 10000 100000 1000000
do  
    echo "************************************************"
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    echo "************************************************"
    echo "Parallel version w np $ARG1 for $VARIABLE"
    mpirun -np $ARG1 main-parallel $VARIABLE
    echo "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww"
    echo "Serial version  for $VARIABLE"
    ./main-serial $VARIABLE
done