#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mpi.h"

#define NEURONSIZE 7
#define INPUTSIZE 100
#define MAX_LINE_LENGTH 100

int main(int argc, char *argv[]) {
    
    
    // Master tasks.
    double timeStart, timeEnd;

    char *weights_path = "weights.txt";//argv[1];
    char *price_path="price.txt";
    char *out_path="NN-mpi-v2-output.txt";
    char buffer[MAX_LINE_LENGTH];
    MPI_Init (&argc, &argv);
    int size,rank,i;
    MPI_Comm_size (MPI_COMM_WORLD, &size); MPI_Comm_rank (MPI_COMM_WORLD, &rank);
    MPI_Status s;
    char curr_val;
    int input_size = 0;    // No. of items on given input.

   

    int row = 0;
    int col;
    char * element;
        
    float x_array[INPUTSIZE];


    if (rank==0){
        printf("You can change NEURONSIZE and INPUTSIZE by modifying assigned macros\n");
        FILE *fp_x = fopen(price_path, "r");
        if (fp_x == NULL) {
            printf("File can\'t be read!\n");
            fclose(fp_x);
            exit(0);
        }
        
        for (input_size = 0; fscanf(fp_x, "%s\n", &curr_val) != EOF; input_size++) 
            x_array[input_size] = strtof(&curr_val, NULL);
            
        for (i = 1; i < size; i++){
            MPI_Send ((void *)x_array, INPUTSIZE, MPI_FLOAT, i, 0xACE5, MPI_COMM_WORLD); 
        }


        
        FILE *fp_w = fopen(weights_path, "r");
        if (fp_w == NULL) {
            printf("File can\'t be read!\n");
            fclose(fp_w);
            exit(0);
        }

        float weight[NEURONSIZE][INPUTSIZE];

        const char delim[2] = ",";
        int flag=1;
        while (fgets(buffer, MAX_LINE_LENGTH, fp_w) != NULL) {
            col = 0;
            element =  strtok(buffer, delim);
            while (element != NULL) {
                if (col>NEURONSIZE){
                    if (flag) {
                        printf("Weight column is bigger than number of workers\n");
                        flag = 0;
                    }
                } else{
                    weight[col][row] = atof(element);
                }
                col++;
                element = strtok(NULL, delim);
            }
            row++;
        }

        int worker_size = size-1;
        int remainder = NEURONSIZE % worker_size;
        int quo = NEURONSIZE / (worker_size-1);

        for (i = 1; i < size; i++){
            int worker_id=i-1;
            int start_index = worker_id >= remainder ? quo*worker_id + remainder : quo*worker_id +worker_id;
            int weight_column_for_workers = worker_id >= remainder ? quo : quo + 1;

        
            MPI_Send ((void *)weight[start_index], weight_column_for_workers*INPUTSIZE, MPI_FLOAT, i, 0xACE5, MPI_COMM_WORLD); 
        }


        float res[NEURONSIZE];
        for (i = 1; i < size; i++){ 
            MPI_Recv ((void *)&res[i-1],1, MPI_FLOAT, i, 0xACE5, MPI_COMM_WORLD, &s);
        }
        
        FILE *fp_out = fopen(out_path, "w+");

        for(col=0;col<NEURONSIZE;col++){
            printf("%f\n",res[col]);
            fprintf(fp_out, "%f",res[col]);
            fprintf(fp_out, "\n");
        }  
        fclose(fp_w);
        fclose(fp_x);
        fclose(fp_out);
        

    } else {

        float weight[INPUTSIZE];

        MPI_Recv ((void *)x_array, INPUTSIZE, MPI_FLOAT, 0, 0xACE5, MPI_COMM_WORLD, &s);
        //for ( i = 0; i < 3; i++) printf("%f\n",x_array[i]);
        int worker_size = size-1;
        int remainder = NEURONSIZE % worker_size;
        int quo = NEURONSIZE / (worker_size-1);

        int worker_id=rank-1;
        int weight_column_for_workers = worker_id >= remainder ? quo : quo + 1;

        MPI_Recv ((void *)weight, weight_column_for_workers*INPUTSIZE, MPI_FLOAT, 0, 0xACE5, MPI_COMM_WORLD, &s);
        
        float sum=0;
        for(col=0;col<INPUTSIZE;col++){
            sum+= weight[col]*x_array[col];
        }
        MPI_Send ((void *)&sum, 1, MPI_FLOAT, 0, 0xACE5, MPI_COMM_WORLD);
    }
    MPI_Finalize();
    return 0;
}