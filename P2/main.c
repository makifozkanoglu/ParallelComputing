#include "helper.h"
#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <float.h>
#include <math.h>
#include <time.h>

float randomfloat(float val){
    float f=(float)arc4random() / UINT32_MAX;
    //printf("%f\n",f);
    return  f * val - val/2;
}
 

float check_rectangle(float *x) {
    int first_condition=((*x)*(*x))<=2;
    x++;
    int second_condition=((*x)*(*x))<=0.25;
    return first_condition && second_condition ? 1.0f : 0.0f;
}

int main(int argc, char *argv[]){

    MPI_Init(&argc, &argv);
    int rank, comsize;
    clock_t t1, t2;
    MPI_Comm_size(MPI_COMM_WORLD, &comsize);   // size is no. of processes.
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    int size;
    if (argc>1){
        size = atoi(argv[1]);
    } else return 0;

    if (rank==0) printf("Size: %d\n",size);
    int i;
    if(size%comsize)
        size += comsize - size%comsize;
    float arr[2*size];
    if(rank == 0){
        for (i=0;i<size;i++){
            arr[2*i]=3;
            arr[2*i+1]=3;
        }
    }
    
    t1 = clock();
    float (*func_rand)(float)=&randomfloat;
    float *res1 = MPI_Map_Func(arr, size*2, func_rand);
    
        
    float (*func_pred)(float *)=&check_rectangle;
    //float *res3 = malloc(size*sizeof(float));
    float *res2 = MPI_Filter_Func(res1, size, func_pred);
    /*if (rank==0){
        for (i=0;i<size;i++){
            printf("arrayid,%d:%f\n",i,*(res2+i));
        }
    }*/
    float initial_value = 0;
    float (*func_add)(float, float)=&add;
    float *res3 = MPI_Fold_Func(res2, size, initial_value, func_add);
    *res3 = (*res3)/size*4.5;
    t2=clock();
    if(rank == 0){
        printf("Elapsed time is %lu\n", t2 - t1 );
        printf("Result:%f\n",*res3);
    }
    
    MPI_Finalize();
}