#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <float.h>
#include <math.h>
#include <string.h> 

 typedef enum {
        FALSE=0,
        TRUE=1,
    } boolean_t; 

float square(float x){
    return x * x; 
}

float add(float x, float y){
    return x + y;
}

boolean_t even(float *x) {
    return ((int)*x) % 2 == 0 ? TRUE : FALSE;
}


float* MPI_Filter_Func(float* arr, int size, float (*pred)(float *)){
    int rank, comsize,i=0;
    float *result = malloc(size * sizeof(float));

    MPI_Comm_size(MPI_COMM_WORLD, &comsize);   // size is no. of processes.
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    int count = (size%comsize)?size/comsize+1:size/comsize;
    float *buff = malloc(2*count * sizeof(float));

    MPI_Scatter(arr, count*2, MPI_FLOAT, buff,
                count*2, MPI_FLOAT, 0, MPI_COMM_WORLD);
    float *local = malloc(count * sizeof(float));
    while(i<count){
        //printf("id:%d, %f:",rank, *buff);
        *local = pred(buff);
        //printf("%c\n",*local);
        buff++;
        local++;
        i++;
    }

    float *locals = malloc(count * comsize * sizeof(float));;
    
    MPI_Allgather(local-i, count, MPI_FLOAT, locals, count, MPI_FLOAT, MPI_COMM_WORLD); 
    //printf("%p\n",locals);
    return locals;
}


float* MPI_Fold_Func(float* arr, int size, float initial_value, float (*func)(float, float)){
    int rank, comsize, i=0;

    MPI_Comm_size(MPI_COMM_WORLD, &comsize);   // size is no. of processes.
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    int count = (size%comsize)?size/comsize+1:size/comsize;
    float *buff = malloc(count * sizeof(float));
    //memset(buff, initial_value, count * sizeof(float));
    
    MPI_Scatter(arr, count, MPI_FLOAT, buff,
                count, MPI_FLOAT, 0, MPI_COMM_WORLD);
    
    
    float local=initial_value;
    while(i<count){
        local = func(*buff, local);
        /*if (rank==7){
        //if (*buff<0.01 || *buff>60){
            printf("id %d,  i : %d, buff: %f \n",rank, i, *buff);
            printf("%s \n", buff==NULL?"true":"false");
        }*/
        buff++;
        i++;
    }
    //if (rank==7) printf("id %d, first i : %d, local: %f \n",rank, i,local);
    
    buff -= i;
    free(buff); //buff = malloc(comsize * sizeof(float));
    float *globals = NULL; 
    //if (rank==0)
    globals = malloc(comsize*sizeof(float));
    
    //MPI_Allgather(buff, 1, MPI_FLOAT, global, 1, MPI_FLOAT, MPI_COMM_WORLD);
    MPI_Allgather(&local, 1, MPI_FLOAT, globals, 1, MPI_FLOAT, MPI_COMM_WORLD);
    float *result=malloc(sizeof(float)); *result=initial_value; i=0;

    while(i<comsize){
        *result = func(*globals, *result);
        globals++;
        i++;
    }//printf("second i : %d\n",i);
    return result;
}

float *MPI_Map_Func(float *arr, int size, float (*func)(float)){
    int rank, comsize, i;

    MPI_Comm_size(MPI_COMM_WORLD, &comsize);   // size is no. of processes.
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    int count = (size%comsize)?size/comsize+1:size/comsize;
    float *buff = malloc(count * sizeof(float));
    MPI_Scatter(arr, 
                count, 
                MPI_FLOAT, 
                buff,
                count, 
                MPI_FLOAT, 
                0, MPI_COMM_WORLD);


    for(i = 0; i < count; i++){
        //printf("id:%d, %f:",rank, *buff);
        *buff = func(*buff);
        //printf("%f\n",*buff);
        buff++;
    }
    float *locals = NULL;
    if (rank==0)
        locals = malloc((size) * sizeof(float));
    //MPI_Allgather(buff, count, MPI_FLOAT, locals, count, MPI_FLOAT, MPI_COMM_WORLD);
    MPI_Gather(buff-i, count, 
               MPI_FLOAT, locals, count,
               MPI_FLOAT,0, 
               MPI_COMM_WORLD);
    return locals;
}


