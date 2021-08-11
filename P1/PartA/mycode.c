#include <stdio.h>
#include "mpi.h"
#include <stdlib.h>
#include <string.h>

#define MAX_LINE_LENGTH 60
#define MAX_LINE_COUNT 100000

int main (int argc, char *argv[]) { 
    MPI_Status s;
    int size, rank, i;
    int data[4];
    int line_length = MAX_LINE_LENGTH;
    MPI_Init (&argc, &argv);
    MPI_Comm_size (MPI_COMM_WORLD, &size); MPI_Comm_rank (MPI_COMM_WORLD, &rank);
    char *path;
    //char line[MAX_LINE_LENGTH];
    unsigned int line_count = 0;
    //char character;
    //if (argc < 1)
    //    return EXIT_FAILURE;
    MPI_Status status;
    
    if (rank == 0){ // Master process
       
        path = "Data/PartA/DNA.txt"; //argv[1];
        FILE *file = fopen(path, "r");
        if (!file){
            perror(path);
            return EXIT_FAILURE;
        }
        int nuc_a=0,nuc_t=0, nuc_g=0, nuc_c=0;
        //char *cptr = line;
        char *cptr = (char *)malloc(MAX_LINE_LENGTH * sizeof(char));
        char *ptr_hold = cptr;
        int line_count=0;
        int char_count=0;
        while(1){
            *cptr = fgetc (file); // reading the file
            
            if (*cptr == EOF ){
                //free(cptr);
                break:
            } else if (*cptr=='\n'){
                int dest = line_count % size;

                if (dest != 0){
                     MPI_Send ((void *)ptr_hold, line_length , MPI_CHAR, dest, 0xACE5, MPI_COMM_WORLD); 
                } else {
                    cptr = ptr_hold;
                    int a_temp=0,t_temp=0, g_temp=0, c_temp=0;

                    for(i=0, i<MAX_LINE_LENGTH;i++){
                        if (*cptr=='A'){
                            a_temp++;
                        } else if (*cptr=='T'){
                            t_temp++;
                        } else if (*cptr=='G'){
                            g_temp++;
                        } else if (*cptr=='C'){
                            c_temp++;
                        }  //else printf("exception");
                        cptr++;
                    }
                    if ((a_temp+t_temp+g_temp+c_temp)!=MAX_LINE_LENGTH){
                        printf("Parsing Error")
                        return EXIT_FAILURE
                    }
                    
                    nuc_a += a_temp;
                    nuc_t += t_temp;
                    nuc_g += g_temp;
                    nuc_c += c_temp;
                    cptr = ptr_hold;
                }
                line_count++;

            } else if (*cptr!='\0'){
                printf("0 value")
            } else if (char_count == MAX_LINE_LENGTH){
                char_count=0;

            } else if (*cptr=='A' || *cptr=='T' || *cptr=='G' || *cptr=='C' || ){
                cptr++;
                char_count++;
            } else {
                //cptr++;
                printf("exception");
            }
            
        }

        printf ("Receiving data . . .\n");
        for (i = 1; i < size; i++){ 
            MPI_Recv ((void *)data, 4, MPI_INT, i, 0xACE5, MPI_COMM_WORLD, &s);
            nuc_a += data[0];
            nuc_t += data[1];
            nuc_g += data[2];
            nuc_c += data[3];
            //printf ("[%d] sent %d\n", i, _data); 
        }

       
    } else {
        _data=rank*rank;
        MPI_Send ((void *)&_data, MAX_LINE_LENGTH, MPI_CHAR, 0, 0xACE5, MPI_COMM_WORLD); 
    }
    MPI_Finalize();
    return 0; 
}