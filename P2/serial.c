#include <stdio.h>
#include <stdlib.h>
#include <float.h>
#include <math.h>
#include <time.h>

float randomfloat(float val){
    float f=(float)arc4random() / UINT32_MAX;
    //printf("%f\n",f);
    return  f * val - val/2;
}


float check_rectangle(float x, float y) {
    int first_condition=(x*x)<=2;
    int second_condition=(y*y)<=0.25;
    return first_condition && second_condition ? 1.0f : 0.0f;
}


void add(float x, float *y){
    *y =  x + *y;
}

int main(int argc, char *argv[]){
    clock_t t1, t2;
    t1 = clock();
    int size = 100000,i;
    float arr_x[size+1],arr_y[size+1];
    
    if (argc>1){
        size = atoi(argv[1]);
    } else return 0;
    
    for (i=0;i<size;i++){
        arr_x[i]=randomfloat(3);
        arr_y[i]=randomfloat(3);
    }

    float filtered[size+1];
    for (i=0;i<size;i++){
        filtered[i] =check_rectangle(arr_x[i], arr_y[i]);
    }
    
    float sum=0;
    for (i=0;i<size;i++){
        add(filtered[i], &sum);
    }
    sum = sum/size*4.5;
    t2 = clock();
    printf("Elapsed time is %lu\n", t2 - t1);
    printf("Result:%f\n",sum);
    
    //return 0;
}