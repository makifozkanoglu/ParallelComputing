// OpenMP program to print Hello World
// using C language

// OpenMP header
#include <omp.h>

#include <stdio.h>
#include <stdlib.h>
int a = 10;
int finished = 0;
/*
#pragma omp parallel num_threads(3) shared(a, finished)
{
    while(!finished) {

        #pragma omp single nowait
        {
            printf("[%d] a is: %d\n", omp_get_thread_num(), a);
            a--;
            finished = 1;
        }

    }
}*/
int i,j,k;
#pragma omp parallel for collapse(3) 
for (i = 0; i < 4; i++){
    for (j = 0; j < i; j++){
        for (k = 0; k < 4; k++){
            printf("%d %d %d %d\n", i, j, k, omp_get_thread_num());
        }
            
    }
        
}
    

