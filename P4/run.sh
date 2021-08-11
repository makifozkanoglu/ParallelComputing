make 
for VARIABLE in  2
do  
    echo "************************************************"
    echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    echo "************************************************"
    #echo "Parallel version for $((1024*$VARIABLE))"
    #./kmer-parallel data/reference_100000bp.txt data/reads_$((1024*$VARIABLE))_100.txt 3 sad
    echo "Parallel version for $((4096/$VARIABLE)) threads"
    ./kmer-parallel data/reference_100000bp.txt data/reads_4096_100.txt 3 sadsad.txt $((4096/$VARIABLE)) 32
    echo "Serial version for $((1024*$VARIABLE))"
    #./kmer-serial data/reference_100000bp.txt data/reads_$((1024*$VARIABLE))_100.txt 3 sad
    ./kmer-serial data/ref.txt data/reads.txt 3 sad.txt
done