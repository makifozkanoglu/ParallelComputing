#include "stdio.h"
#include "mpi.h"
#include <stdlib.h>


// subject to change 
#define MAX_LINE_LENGTH 60 
#define MAX_LINE_COUNT 100000

int main(int argc, char **argv) {

    MPI_Status status;
    int size, rank;
    int *sptr = ( int *)malloc((MAX_LINE_COUNT*MAX_LINE_LENGTH )* sizeof( int)+1);
    int *ptr_hold = sptr;
    long local_sum[4];
    //memset(local_sum, 0, 4);
    for (int i=0; i<4; ++i)    // Set the first 6 elements in the array
        local_sum[i] = 1;   
    int line_count=0;
    int char_count=0;
    line_count = MAX_LINE_COUNT;
    char_count = MAX_LINE_LENGTH;
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
        
        FILE *file = fopen(path, "r");
        if (!file){
            perror(path);
            //return EXIT_FAILURE;
        }
        else{
            char *cptr=(char *)malloc( sizeof(char));
            while(1){
                //char_count=0;
                *cptr = fgetc (file);
                //printf("%c",*cptr);
                if (*cptr=='A' || *cptr=='T' || *cptr=='G' || *cptr=='C'){
                    _count++;
                    if (*cptr=='A'){
                        *sptr=0;
                    } else if (*cptr=='T'){
                        *sptr=1;
                    } else if (*cptr=='G'){
                        *sptr=2;
                    } else if (*cptr=='C'){
                        *sptr=3;
                    }
                    sptr++;
                } /*else if (char_count==0 && (*cptr=='\n' || *cptr=="\0")) {
                    char_count = _count;
                }*/ 
                else if (*cptr==EOF){
                    sptr++;
                    *cptr='\0';
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
        //printf("%s",cptr);
    }
    MPI_Barrier(MPI_COMM_WORLD);
    MPI_Bcast((void *)ptr_hold, line_count*char_count, MPI_INT, 0, MPI_COMM_WORLD);
    // wait for everyone to receive the array itself
    MPI_Barrier(MPI_COMM_WORLD);


    int quotient = line_count / size;
    
    int remainder = line_count % size;
    int start_index = rank >= remainder ? quotient*rank + remainder : quotient*rank +rank;
    int line_size_for_one_processor = rank >= remainder ? quotient : quotient + 1;



    // edgecase: processor count can be much more than the count of numbers to sum.
    //printf("%d",start_index);
    //printf("%d, %d, %d, %d",start_index,line_count,line_size_for_one_processor,char_count);
    long offset;
    int i;
    int c_idx;
    if(start_index < line_count){
        int *c_;
        for(i = 0; i < line_size_for_one_processor; i++){
            for (c_idx=0;c_idx<char_count;c_idx++){
                offset=((long)char_count)*((long)i+(long)start_index) + (long)c_idx;

                //printf("off %d",offset);
                
                c_ = (ptr_hold + offset );
                //printf("%d \n",*c_);
                
                if (*c_==0){
                     local_sum[0]++;
                } else if (*c_==1){
                     local_sum[1]++;
                } else if (*c_==2){
                    local_sum[2]++;
                } else if (*c_==3){
                     local_sum[3]++;
                } else printf("exception");
                
            }
        }
    }
    //printf("off %ld\n",offset);
    //printf("%d, %d",i,c_idx);
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
    
    MPI_Finalize();

    return 1;
}