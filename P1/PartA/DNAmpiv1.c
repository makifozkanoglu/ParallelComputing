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
    char line_ptr_array[MAX_LINE_COUNT];
    //char line[MAX_LINE_LENGTH];
    unsigned int line_count = 0;
    //char character;
    //if (argc < 1)
    //    return EXIT_FAILURE;
    int lines_to_be_sent = MAX_LINE_COUNT/size;
    if (rank == 0){ // Master process
       
        path = "Data/PartA/DNA.txt"; //argv[1];
        FILE *file = fopen(path, "r");
        if (!file){
            perror(path);
            //return EXIT_FAILURE;
        }
        long int nuc_a=0,nuc_t=0, nuc_g=0, nuc_c=0;
        //char *cptr = line;
        char *cptr = (char *)malloc(MAX_LINE_COUNT*MAX_LINE_LENGTH * sizeof(char));
        char *ptr_hold = cptr;
        int line_count=0;
        int char_count=0;
        while(1){
            //char_count=0;
            
            *cptr = fgetc (file);
            if (*cptr=='A' || *cptr=='T' || *cptr=='G' || *cptr=='C'){
                char_count++;
                cptr++;
            } else if (*cptr==EOF){
                break;
            }
            if (char_count==MAX_LINE_LENGTH){
                char_count=0;
                line_count++;
            }
        }
        printf("%p %p",cptr, ptr_hold);
        printf ("Sending data . . .lines:%d\n",line_count);
        
        
        for (i = 1; i < size; i++){ 
            
            MPI_Send ((void *)(ptr_hold+lines_to_be_sent*(i-1)), MAX_LINE_LENGTH*lines_to_be_sent, MPI_CHAR, i, 0xACE5, MPI_COMM_WORLD); 
            //ptr_hold++;
        }

        
        int a_temp=0, t_temp=0, g_temp=0, c_temp=0;
        printf("\n i:%d ok \n",i);
        ptr_hold=ptr_hold+lines_to_be_sent*(i);
        printf("%p", ptr_hold);
        for(i=0; i<(lines_to_be_sent*MAX_LINE_LENGTH+MAX_LINE_COUNT%size);i++){
            if (*ptr_hold=='A'){
                a_temp++;
            } else if (*ptr_hold=='T'){
                t_temp++;
            } else if (*ptr_hold=='G'){
                g_temp++;
            } else if (*ptr_hold=='C'){
                c_temp++;
            } else printf("exception");
            //free(ptr_hold);
            ptr_hold++;
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

        nuc_a += a_temp;
        nuc_t += t_temp;
        nuc_g += g_temp;
        nuc_c += c_temp;
        printf("%d %d %d %d = %d\n",a_temp,t_temp,g_temp,c_temp, a_temp+t_temp+g_temp+c_temp);
        printf("A:%ld\n",nuc_a);
        printf("T:%ld\n",nuc_t);
        printf("G:%ld\n",nuc_g);
        printf("C:%ld\n",nuc_c);
        printf("total:%ld", nuc_a+nuc_t+nuc_g+nuc_c);
    } else { //if(size<0) {
        char *ptr_hold=(char *)malloc(MAX_LINE_LENGTH*lines_to_be_sent * sizeof(char));;
        int *local_total;//=(int *)malloc(4 * sizeof(int));
        MPI_Recv ((void *)ptr_hold, MAX_LINE_LENGTH*lines_to_be_sent, MPI_CHAR, 0, 0xACE5, MPI_COMM_WORLD, &s);
        int a_temp=0,t_temp=0, g_temp=0, c_temp=0;
        for(i=0; i<(lines_to_be_sent*MAX_LINE_LENGTH);i++){
            if (*ptr_hold=='A'){
                a_temp++;
            } else if (*ptr_hold=='T'){
                t_temp++;
            } else if (*ptr_hold=='G'){
                g_temp++;
            } else if (*ptr_hold=='C'){
                c_temp++;
            }  //else printf("exception");
            //free(ptr_hold);
            ptr_hold++;
        }
        //printf("%d %d %d %d = %d\n",a_temp,t_temp,g_temp,c_temp, a_temp+t_temp+g_temp+c_temp);
        
        data[0] = a_temp;
        data[1] = t_temp;
        data[2] = g_temp;
        data[3] = c_temp;
        MPI_Send ((void *)data, 4,  MPI_INT, 0, 0xACE5, MPI_COMM_WORLD); 
    }
    //printf("%d %d %d %d = %d\n",a_temp,t_temp,g_temp,c_temp, a_temp+t_temp+g_temp+c_temp);
    MPI_Finalize();
    
    return 0; 
}