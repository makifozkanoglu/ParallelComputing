#include "helper.h"
#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <float.h>
#include <math.h>


int main (int argc, char *argv[]){
    
    int size = 24;
    float arr[size];
    for (int i=0;i<size;i++){
        arr[i]=i+1;
    }
    
    MPI_Init(&argc, &argv);
    int rank, comsize;
    MPI_Comm_size(MPI_COMM_WORLD, &comsize);   // size is no. of processes.
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    /*
    if(rank == 0) {
        for (int i=0;i<size;i++){
            printf("%f\n", arr[i]);
        }
        printf("okkkkk");

    }
    */
   
    //////MPI_Map_Func
    /*
    float (*func_square)(float)=&square;
    
    float *res1; //= malloc((size) * sizeof(float));
    //printf("%lu\n",sizeof(res1));
    //printf("%lu\n",sizeof(arr));
    
    res1 = MPI_Map_Func(arr, size, func_square);
    if(rank == 0) {
        for(int i=0; i<size;i++){
            //printf("%f\n", res1[i]);
        }
    }
    */

    //////////MPI_Fold_Func
    /*
    float initial_value = 0;
    float (*func_add)(float, float)=&add;
    float *res2; res2 = MPI_Fold_Func(arr, size, initial_value, func_add);
    if(rank == 0) {
        printf("%f\n", *res2);
    }
    */
    

    boolean_t (*func_pred)(float *)=&even;
    float *res3 = malloc(size*sizeof(float));
    res3 = MPI_Filter_Func(arr, size, func_pred);
     if(rank == 0) {
        for(int i=0; i<size;i++){
            printf("idx:%d,val:%f,%f\n",i, arr[i], *res3);
            res3++;
        }
    }

    MPI_Finalize();


}
