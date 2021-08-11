#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NEURONSIZE 9
#define INPUTSIZE 100
#define MAX_LINE_LENGTH 100

int main(int argc, char *argv[]) {
    // Master tasks.
    double timeStart, timeEnd;

    char *weights_path = "weights.txt";//argv[1];
    char *price_path="price.txt";
    char *out_path="NN-serial-output.txt";
    char buffer[MAX_LINE_LENGTH];
    
    char curr_val;
    int input_size = 0;    // No. of items on given input.

   

    int row = 0;
    int col;
    char * element;

    float x_array[INPUTSIZE];
    FILE *fp_x = fopen(price_path, "r");
    if (fp_x == NULL) {
        printf("File can\'t be read!\n");
        fclose(fp_x);
        exit(0);
    }

    for (input_size = 0; fscanf(fp_x, "%s\n", &curr_val) != EOF; input_size++) 
        x_array[input_size] = strtof(&curr_val, NULL);
   
  

    FILE *fp_w = fopen(weights_path, "r");
    if (fp_w == NULL) {
        printf("File can\'t be read!\n");
        fclose(fp_w);
        exit(0);
    }

    float weight[INPUTSIZE][NEURONSIZE];

    const char delim[2] = ",";
    while (fgets(buffer, MAX_LINE_LENGTH, fp_w) != NULL) {
        col = 0;
        element =  strtok(buffer, delim);
        while (element != NULL) {
            weight[row][col] = atof(element);
            col++;
            element = strtok(NULL, delim);
        }
        row++;
    }
    FILE *fp_out = fopen(out_path, "w+");
    float res[NEURONSIZE];

    for(col=0;col<NEURONSIZE-2;col++){
        float sum=0;
        for(row=0;row<INPUTSIZE;row++){
            sum+= weight[row][col]*x_array[row];

        }
        res[col]=sum;
        printf("%f\n",sum);
        //fprintf(fp_out, "%f",sum);
        //fprintf(fp_out, "\n");
    }   
    FILE * fp;

    fp = fopen ("file.txt", "w+");
    fprintf(fp, "%s %s %s %d", "We", "are", "in", 2012);
   
    fclose(fp);
    fclose(fp_w);
    fclose(fp_x);
    fclose(fp_out);
   
    return 0;
}