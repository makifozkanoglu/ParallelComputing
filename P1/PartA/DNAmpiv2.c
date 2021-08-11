#include "stdio.h"
#include "mpi.h"
#include <stdlib.h>


// subject to change 
#define MAX_LINE_LENGTH 60 
#define MAX_LINE_COUNT 80

int main(int argc, char **argv) {

    MPI_Status status;
    int size, rank;
    //char *cptr = (char *)malloc(MAX_LINE_COUNT*MAX_LINE_LENGTH * sizeof(char));
    char carr[MAX_LINE_COUNT*MAX_LINE_LENGTH];
    char *cptr = carr;
    char *ptr_hold = cptr;
    long *local_sum=(long *)malloc(4 * sizeof(long));


    int line_count=0;
    int char_count=0;
    char *path;

    MPI_Init(&argc, &argv);

    double t1, t2;

    t1 = MPI_Wtime();
    long int nuc_a=0,nuc_t=0, nuc_g=0, nuc_c=0;

    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    int _count=0;
    // master process reads the file and sends individual integers to all of the processes.
    if (rank == 0) {
        
        path = "Data/PartA/DNA.txt"; //argv[1];
        printf("%s", path);
        FILE *file = fopen(path, "r");
        if (!file){
            perror(path);
            //return EXIT_FAILURE;
        }
        else{
            while(1){
                //char_count=0;
                *cptr = fgetc (file);
                if (*cptr=='A' || *cptr=='T' || *cptr=='G' || *cptr=='C'){
                    _count++;
                    cptr++;
                } /*else if (char_count==0 && (*cptr=='\n' || *cptr=="\0")) {
                    char_count = _count;
                }*/ else if (*cptr==EOF){
                    break;
                }
                /*
                if (char_count==0 && char_count==char_count){
                    char_count=0;
                    line_count++;
                }
                */
            }
        }
    }
    printf("count:%d", _count);
    // master process broadcasts the array length to the workers
    line_count = MAX_LINE_COUNT;
    char_count = MAX_LINE_LENGTH;
    /*
    MPI_Bcast((void *)&line_count, 1, MPI_INT, 0, MPI_COMM_WORLD);
    printf("1\n");
    // wait for everyone to receive the array length
    MPI_Barrier(MPI_COMM_WORLD);
    MPI_Bcast((void *)&char_count, 1, MPI_INT, 0, MPI_COMM_WORLD);
    // wait for everyone to receive the array length
    printf("2\n");
    MPI_Barrier(MPI_COMM_WORLD);
    */
    /*if(rank != 0){
        // worker processes allocate space for the array to be received.
        arr = malloc(line_count * sizeof(int));
    }*/

    // master process broadcasts the array to the workers
    MPI_Bcast((void *)ptr_hold, line_count*char_count, MPI_CHAR, 0, MPI_COMM_WORLD);
    printf("2\n");
    // wait for everyone to receive the array itself
    MPI_Barrier(MPI_COMM_WORLD);
    printf("2\n");
    // everyone determines their portion of the data to compute.
    int quotient = line_count / size;
    int remainder = line_count % size;
    int start_index = rank >= remainder ? quotient*rank + remainder : quotient*rank +rank;
    int line_size_for_one_processor = rank >= remainder ? quotient : quotient + 1;

    /*
    // edgecase: processor count can be much more than the count of numbers to sum.
    if(start_index < line_count){
        char c_;
        for(int i = 0; i < line_size_for_one_processor; i++){
            for (int c_idx=0;c_idx<char_count;c_idx++){
                c_ = *(ptr_hold + char_count*(i+start_index) + c_idx );
                if (c_=='A'){
                     (*(local_sum))++;
                } else if (c_=='T'){
                     (*(local_sum+1))++;
                } else if (c_=='G'){
                    (*(local_sum+2))++;
                } else if (c_=='C'){
                     (*(local_sum+3))++;
                } else printf("exception");
            }
        }
    }
*/

    /*

    //use all reduce to compute final sum
    long *global_sum = (long *)malloc(4 * sizeof(long));
    MPI_Allreduce(local_sum, global_sum, 4, MPI_LONG, MPI_SUM, MPI_COMM_WORLD);
    MPI_Barrier(MPI_COMM_WORLD);
    // free the allocated heap space for all processors
    free(ptr_hold);

    // Now all processors computed the result but only master processor prints the result
    if(rank == 0) {
        printf("A:%ld\n",*global_sum);
        printf("T:%ld\n",*(global_sum+1));
        printf("G:%ld\n",*(global_sum+2));
        printf("C:%ld\n",*(global_sum+3));
    }

    t2 = MPI_Wtime();
    if(rank == 0){
        printf( "Elapsed time is %f\n", t2 - t1 );
    }
    
    */
    MPI_Finalize();

    return 0;
}